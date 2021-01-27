#!/bin/bash
#Author: chenglin.wu
#Version: 2021/01/06

X=$(stty size|awk '{print$1}')
Y=$(stty size|awk '{print$2}')
LINES=${X:-30}
COLUMNS=${Y:-130}
HEIGHT=$(expr $LINES - 10 )
WIDTH=$(expr $COLUMNS - 10 )
if [[ $HEIGHT -le 10 ]];then
    HEIGHT=$LINES
fi
if [[ $WIDTH -le 10 ]];then
    WIDTH=$COLUMNS
fi

if [[ -z $(systemctl is-active NetworkManager|grep -w active) ]];then
	systemctl start NetworkManager
fi

network_test(){
    HOST_1='114.114.114.114'
    HOST_2='119.29.29.29'
    HOST_3='223.5.5.5'
    HOST_4='180.76.76.76'
    HOST_5='1.2.4.8'
    HOST_6='8.8.8.8'
    HOST_7='199.85.126.10'
    ping_cmd(){
        ping -q -c10 -i0.1 -w2 $1 |egrep -o '[0-9]{0,3}%'|egrep -o -w '[0-9]{0,3}'
    }
    RESULT=$(ping_cmd $HOST_1)
    i=1
    until [[ $RESULT -le 30 ]];do
        ((i += i))
        eval host=$(echo '$HOST_'"$i")
        RESULT=$(ping_cmd ${host})
    done
    if [[ -z $RESULT ]];then
        RESULT=100
    else
        RESULT=$RESULT
    fi
}

delete_connect(){
    for uuid in $(nmcli -t con|awk -F: '{print$2}');do
        nmcli con del $uuid
    done
}

auto_get_interface_config(){
    interface_speed(){
        INTERFACE_DEV=$(ls /sys/class/net/| egrep -v "^(bond|`ls /sys/devices/virtual/net/ |sed ":a;N;s/\n/|/g;ta"`)")
        for i in $INTERFACE_DEV;do
            if [[ $(ethtool $i|grep 'Link detected') =~ "yes" ]];then
                echo -e "$i $(cat /sys/class/net/$i/speed)"
            fi
        done
    }
    INTERFACE_SPEED=$(interface_speed|awk '{if(hash[$2]){hash[$2] = hash[$2]","$1}else{hash[$2] = $1}}END{for(i in hash) print i,hash[i]}'|sort |awk 'NR==1{print$2}')
    INTERFACE_NUM=$(echo $INTERFACE_SPEED|awk -F, '{print NF}')
    INTERFACE_LIST=$(echo $INTERFACE_SPEED|sed 's/,/\n/g')
}

nmcli_common_connect(){
    if [[ $INTERFACE_NUM -eq 0 ]];then
        whiptail --title "Information" --msgbox "Auto is not supported, please select the option under 'auto'" $HEIGHT $WIDTH
        choose_interface
    elif [[ $INTERFACE_NUM -eq 1 ]];then
        nmcli con add con-name $INTERFACE_LIST type ethernet ifname $INTERFACE_LIST
        CON_NAME=$INTERFACE_LIST
    elif [[ $INTERFACE_NUM -gt 1 ]];then
        modprobe bonding
        nmcli con add con-name bond0 type bond ifname bond0 +bond.options mode=balance-xor +bond.options xmit_hash_policy=layer3+4 +bond.options miimon=100 +bond.options downdelay=200 +bond.options updelay=200
        for i in $INTERFACE_LIST;do
            nmcli con add type bond-slave ifname $i master bond0
        done
        CON_NAME='bond0'
    fi
}

nmcli_single_connect(){
    nmcli con mod $CON_NAME ipv4.addr "$IP/$PREFIX" ipv4.gate "$GATEWAY" ipv4.method manual ipv4.dns "$DNS"
    nmcli con up $CON_NAME
}

input_network_info(){
    check_inputbox(){
        KEY=$1
        VALUE=$2
        VALID_CHECK=$(echo $VALUE |awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
        if [[ -z $(echo $VALUE |grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$") || "$VALID_CHECK" != "yes" ]]; then
			whiptail --title "$KEY check error" --msgbox "The VALUE=$VALUE may be wrong, please check it and enter it again." $HEIGHT $WIDTH
			input_network_info
        fi
    }
    IP=$(whiptail --title "IP Configure - IP" --inputbox "Please input IP address" $HEIGHT $WIDTH $IP 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]];then choose_interface ;fi
    GATEWAY=$(whiptail --title "IP Configure - GATEWAY" --inputbox "Please input GATEWAY" $HEIGHT $WIDTH $GATEWAY 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]];then choose_interface ;fi
    NETMASK=$(whiptail --title "IP Configure - NETMASK" --inputbox "Please input NETMASK" $HEIGHT $WIDTH $NETMASK 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]];then choose_interface ;fi
    DNS=$(whiptail --title "IP Configure - DNS" --inputbox "Please input DNS" $HEIGHT $WIDTH $DNS 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]];then choose_interface ;fi
    for i in $(echo -e "IP\nGATEWAY\nNETMASK\nDNS");do
        eval input=$(echo '$'"$i")
        check_inputbox $i ${input}
    done
    PREFIX=$(ipcalc --prefix $IP $NETMASK|awk -F= '{print$2}')
}

choose_interface(){
    INTERFACE_DEV=$(ls /sys/class/net/| egrep -v "^(bond|`ls /sys/devices/virtual/net/ |sed ":a;N;s/\n/|/g;ta"`)")
    for i in $INTERFACE_DEV;do
        printf "%s|%s|%s\n" $i "$(ethtool $i|grep 'Link detected'|sed 's/^[ \t]*//g')" "$(ethtool $i|grep 'Speed'|sed 's/^[ \t]*//g'|sed 's/\!//g')"
    done |sed 's/ /_/g' > /tmp/interface.txt
    sed -i 's/$/& OFF/g' /tmp/interface.txt
    sed -i '1i auto|Auto_Create_Bond_or_Choose_interface ON' /tmp/interface.txt
    INTERFACE_NUM=$(cat /tmp/interface.txt|wc -l)
    OPTION=$(whiptail --title "Interface List" --checklist "Choose a interface for configuration.Multiple choices include AUTO, only AUTO will take effect. Select two interfaces and they will be made into bonds by default." $HEIGHT $WIDTH $INTERFACE_NUM $(for i in `seq 1 $INTERFACE_NUM`;do printf "%s %s " $i $(cat /tmp/interface.txt|awk 'NR==i{print}' i="$i");done ) 3>&1 1>&2 2>&3)

    if [[ $? == 0 ]];then
        INTERFACE_LIST=$(for i in $(echo $OPTION|sed 's/"//g');do
            echo -e "$(cat /tmp/interface.txt |awk 'NR==i{print}' i="$i" |awk -F\| '{print$1}')"
        done)
        INTERFACE_NUM=$(echo $INTERFACE_LIST|wc -w)
        input_network_info
    else
        whiptail_netBreak
    fi
}

exec_conf_network(){
    whiptail --title "Confirm" --yesno "[Warring] The network will be configured and delete all connection. Choose Yes to continue." $HEIGHT $WIDTH
    if [[ $? == 0 ]];then
        delete_connect
        choose_interface
        if [[ $INTERFACE_LIST =~ "auto" ]];then
            auto_get_interface_config
        fi
        nmcli_common_connect
        nmcli_single_connect
        echo -e 'Configuration complete\n' > /tmp/netpass.txt
        get_ip_info
        command_list
    else
        whiptail_netBreak
    fi
}

command_list(){
    OPTION=$(whiptail --title "Test Network" --menu "Select the command to be executed." $HEIGHT $WIDTH 3 \
    "1" "ping" \
    "2" "mtr" \
    "3" "traceroute" 3>&1 1>&2 2>&3)
    
    if [ $? = 0 ]; then
        HOST=$(whiptail --title "ICMP test - HOST" --inputbox "Please input HOST" $HEIGHT $WIDTH 114.114.114.114 3>&1 1>&2 2>&3)
        if [[ $OPTION == "1" ]];then
            ping -c 4 -i 0.1 -n $HOST > /tmp/ping.txt 2>&1
            whiptail --title "PING test result" --scrolltext --textbox /tmp/ping.txt $HEIGHT $WIDTH
        elif [[ $OPTION == "2" ]];then
            mtr -c 10 -ni 0.05 -r $HOST > /tmp/mtr.txt 2>&1
            whiptail --title "MTR test result" --scrolltext --textbox /tmp/mtr.txt $HEIGHT $WIDTH
        elif [[ $OPTION == "3" ]];then
            traceroute -w 1 -n $HOST > /tmp/traceroute.txt 2>&1
            whiptail --title "TRACEROUTE test result" --scrolltext --textbox /tmp/traceroute.txt $HEIGHT $WIDTH
        fi
        command_list
    else
        whiptail_netBreak
    fi
}

get_ip_info(){
    printf '%s\t%s\n' "Serial Number: " "$(cat /sys/class/dmi/id/product_serial|sed 's/ //g')" >> /tmp/netpass.txt
    CON_NAME=$(ip route |grep default|awk '{print$5}')
    nmcli connection show $CON_NAME |egrep 'connection.id|ipv4.addresses|ipv4.gateway' >> /tmp/netpass.txt
    echo ''
    sed -i 's/[ ][ ]*/ /g' /tmp/netpass.txt
    echo '' >> /tmp/netpass.txt
    whiptail --title "Network Status" --scrolltext --textbox /tmp/netpass.txt $HEIGHT $WIDTH
}

show_ip_info(){
    echo -e "IP Information\n" > /tmp/netpass.txt
    get_ip_info
}

advance_features(){
    MENU=$(whiptail --title "Baishan network configure" --menu \
    "Use Enter to select a function." $HEIGHT $WIDTH 1 \
    "1" "Edit Connection" 3>&1 1>&2 2>&3)
    if [ $? = 0 ]; then
        if [[ $MENU == "1" ]];then
            nmtui-edit
        fi
    fi
}

show_help(){
    whiptail --title "help information " --msgbox "NO HELP!" $HEIGHT $WIDTH
}

whiptail_netPass(){
    echo -e "The network connection is successful. No need to configure\n" > /tmp/netpass.txt
    get_ip_info
}

whiptail_netBreak(){
    MENU=$(whiptail --title "Baishan network configure" --cancel-button "LOGIN OUT" --backtitle "chenglin.wu@baishan.com" --menu \
    "Use Enter to select a function." $HEIGHT $WIDTH 5 \
    "1" "IP Configure" \
    "2" "Test Network (ping/mtr/traceroute)" \
    "3" "Show IP Information" \
    "4" "Advance Features..." \
    "5" "Show Help" 3>&1 1>&2 2>&3)

    if [ $? = 0 ]; then
        if [[ $MENU == "1" ]];then
            exec_conf_network
        elif [[ $MENU == "2" ]];then
            command_list
        elif [[ $MENU == "3" ]];then
            show_ip_info
        elif [[ $MENU == "4" ]];then
            advance_features
        elif [[ $MENU == "5" ]];then
            show_help
        fi
        if [ $? = 0 ]; then
            whiptail_netBreak
        fi
    else
        echo "You chose LOGIN OUT."
        exit 0
    fi
}

main(){
    trap '' INT
    network_test
    if [[ $RESULT -le 30 ]];then
        whiptail_netPass
    else
        whiptail_netBreak
    fi
}
main "$@"
