# whiptail_User
### CentOS7下的GUI用户网络配置 - 无shell环境
> Redhat系运行无异常，Debian系需要NetworkManager服务

```bash
#执行下面命令在操作系统上快速体验
curl -ks https://raw.githubusercontent.com/SkyOfWood/whiptail_Network/master/create_user.sh|bash

#登入用户network
#登入密码network123
```

- **网络正常**后登入的显示，无法做其它操作  
[![sxzqyV.md.png](https://s3.ax1x.com/2021/01/27/sxzqyV.md.png)](https://imgchr.com/i/sxzqyV)

- **网络不通**登入后菜单列表

  [![sxz7zq.png](https://z3.ax1x.com/2021/01/27/sxz7zq.png)](https://imgtu.com/i/sxz7zq)

#### 功能说明

1. IP Configure

   A.确认是否继续，该步骤会删除当前网络配置

   [![sxzoJs.md.png](https://s3.ax1x.com/2021/01/27/sxzoJs.md.png)](https://imgchr.com/i/sxzoJs)

   B.选择网卡，默认单选第一个auto。

   ---选择auto或者选择中包含auto都会自动配置bond，如果bond条件不满足则自动选择网卡

   ---除auto选项外，单选只会配置到一个网卡上面，多选会自动将选择的网卡合并成bond

   [![sxzbQ0.md.png](https://s3.ax1x.com/2021/01/27/sxzbQ0.md.png)](https://imgchr.com/i/sxzbQ0)

   C.接下来会进行IP、网关、掩码、DNS的配置

   [![sxzIij.md.png](https://s3.ax1x.com/2021/01/27/sxzIij.md.png)](https://imgchr.com/i/sxzIij)

   D.配置完成后会显示配置信息

   [![sxzLLT.md.png](https://s3.ax1x.com/2021/01/27/sxzLLT.md.png)](https://imgchr.com/i/sxzLLT)

   E.这一步会进行一些基本网络测试 ping、mtr、traceroute。然后输入需要测试的主机地址，默认是114.114.114.114

   [![sxzXeU.md.png](https://s3.ax1x.com/2021/01/27/sxzXeU.md.png)](https://imgchr.com/i/sxzXeU)

   [![sxzjwF.md.png](https://s3.ax1x.com/2021/01/27/sxzjwF.md.png)](https://imgchr.com/i/sxzjwF)

   F.选择命令后会输出结果

   [![sxzvo4.md.png](https://s3.ax1x.com/2021/01/27/sxzvo4.md.png)](https://imgchr.com/i/sxzvo4)

   G.打完收工

2. Test Network (ping/mtr/traceroute)

   参考'1 IP Configure'中的 E、F步骤

3. Show IP Information

   参考'1 IP Configure'中的 D步骤

4. Advance Features...

   [![sxzTWn.md.png](https://s3.ax1x.com/2021/01/27/sxzTWn.md.png)](https://imgchr.com/i/sxzTWn)

5. Show Help

