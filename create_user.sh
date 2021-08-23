#!/bin/bash

#定义变量
USER_NAME='network'

#删除并创建
userdel -r -f $USER_NAME
useradd -m $USER_NAME -s '/usr/bin/sudo /usr/local/bin/User_network'

#配置密码
echo 'network123' | passwd --stdin $USER_NAME

#禁止ssh
sed -i '/.*DenyUsers.*/d' /etc/ssh/sshd_config
echo "DenyUsers $USER_NAME" >>/etc/ssh/sshd_config
service sshd reload

#sudo免密码
echo "$USER_NAME ALL=(root)NOPASSWD: /usr/local/bin/User_network" >/etc/sudoers.d/user-$USER_NAME
chmod 400 /etc/sudoers.d/user-$USER_NAME

curl -ks https://raw.githubusercontent.com/SkyOfWood/whiptail_Network/master/User_network.sh -o /usr/local/bin/User_network
chmod 755 /usr/local/bin/User_network
