---
title: "Board Environment Setup"
author: [Yongxi Yang]
date: "2024-03-22"
subject: "Markdown"
keywords: [Markdown, Tutorial, Board]
listings-disable-line-numbers: true
fontfamily: xeCJK
...

# 板子烧录教程

## 准备工作

### 机器准备

- linux PC
- window PC
- v4h2 board

### 软件准备

- Jfrog
  - 下载 rcar-xos_tool_yocto_linux_v3.21.0_release.tar.gz
    - https://rcar-env.dgn.renesas.com/artifactory/rcar-release/release/xos3/adas/v3.21.0/rcar-tools/rcar-xos_tool_yocto_linux_v3.21.0_release.tar.gz
    - 解压之后 文件在 os/yocto_linux/
      - image 放到 tftp
      - r8a779g0-whitehawk.dtb 放到 tftp
      - rcar-image-adas-v4h.tar.gz 这个是 系统 解压后 放到 nfs 上的
  - 下载 rcar-xos_developer-adas-bootloader_v3.21.0_release.tar.gz
    - https://rcar-env.dgn.renesas.com/artifactory/rcar-release/release/xos3/adas/v3.21.0/rcar-xos_developer-adas-bootloader_v3.21.0_release/rcar-xos_developer-adas-bootloader_v3.21.0_release.tar.gz
    - 解压后 在 rcar-xos/v3.21.0/os/bootloader/v4h2
- window PC
  - teraterm 板子串口通讯需要
  - UART 串口驱动 （CP210xVCPInstaller.exe）
  - v4h_bootloader.7z

- linux PC
  - 安装 nfs server

    ```bash
    sudo apt install nfs-kernel-server
    sudo apt install rpcbind
    ```

  - export path `/etc/exports`

    ```
    #/srv/nfs 192.168.0.0/24(rw,no_root_squash,no_subtree_check)
    /srv/nfs/1031_rcar_3180 *(rw,no_root_squash,no_subtree_check)
    /srv/nfs/1020_rcar_3180 *(rw,no_root_squash,no_subtree_check)
    /srv/nfs/1031_rcar_3210 *(rw,no_root_squash,no_subtree_check)
    /srv/nfs/1020_rcar_3210 *(rw,no_root_squash,no_subtree_check)
    #/srv/tftp *(rw,no_root_squash,no_subtree_check)
    #/srv/tftp 192.168.0.0/16(rw,no_root_squash,no_subtree_check)
    #/srv/tftp 10.166.16.0/24(rw,no_root_squash,no_subtree_check)
    #/srv/tftp 192.168.0.0/16(rw,no_root_squash,no_subtree_check)
    #/srv/tftp 10.166.16.0/24(rw,no_root_squash,no_subtree_check)
    ```

  - 关闭防火墙

    ```bash
    sudo ufw disable
    #sudo reboot
    ```

  - 打开配置文件并添加以下内容

    ```bash
    sudo vi /etc/default/nfs-kernel-server
    ```

    ```config
    RPCNFSDOPTS="--nfs-version 2,3,4"
    ```

  - 重启 nfs 服务

    ```bash
    sudo service nfs-kernel-server restart
    ```

  - 安装 tftp server

    ```sh
    sudo apt install tftp   //客户端也装上了
    sudo apt install tftpd-hpa
    sudo apt install xinetd
    sudo mkdir /srv/tftp
    sudo chown -R tftp:tftp /srv/tftp
    ```

    - cat this "/etc/default/tftpd-hpa"

      ```conf
      # /etc/default/tftpd-hpa

      TFTP_USERNAME="tftp"
      TFTP_DIRECTORY="/srv/tftp"
      TFTP_ADDRESS=":69"
      TFTP_OPTIONS="-l -c -s"
      ```

    - cat /etc/xinetd.d/tftp

      ```conf
      service tftp
      {
          disable = no
          socket_type = dgram
          protocol = udp
          wait = yes
          user = tftp
          server = /usr/sbin/in.tftpd
          server_args = -s /srv/tftp -c
          per_source = 11
          cps = 100 2
          flags =IPv4
      }
      ```

    - 重启tftp 服务,重新加载xinetd, 重启xinetd

      ```sh
      sudo service tftpd-hpa restart
      sudo /etc/init.d/xinetd reload
      sudo /etc/init.d/xinetd restart
      ```

    - 测试：

      ```bash
      netstat -a | grep tftp
      tftp 172.28.28.81
      tftp> get /1031_rcar_3180/Image_v3180
      ```

    - 将两项服务加入自启动中

      ```bash
      sudo systemctl enable nfs-kernel-server
      sudo systemctl enable tftpd-hpa
      sudo systemctl enable xinetd
      ```

  - 将 rcar-image-adas-v4h.tar.bz2 复制到 nfs 配置的文件夹并解压
  - 请将版本信息 echo "rcar-xos: x.x.x" > RCAR_VERSION 写到 nfs 的文件夹中方便识别版本 **在 yocoto linux 系统的根目录下做这个事情**
  - 将  image_v3180 和 r8a779g0-whitehawk_v3180.dtb 拷贝到 tftp 的文件夹

### 连线准备

- 确保 linux PC 可以上网 （在北京办公室需要插网线）
- 确保 window PC （在北京办公室需要链接 wifi ）
- v4h 板子需要连接电源
- v4h 板子需要连接网线至网口
- micro B 的 USB 串口
  - 连接上之后请到 设备管理器 产看端口 这一选项 有 CP210x USB

NB：电脑如果没有反应 请检查连线是否虚连 或者 数据线是否正常

## 连接准备

- window
  1. 打开 Tera Term
     1. File -> new connection -> serial
     2. 重新启动板卡 在 tera term 中显示乱码 则 连接成功
     3. 调整波特率 setup -> serial port -> baud rate 调整至 921600 -> OK
     4. 重新启动板卡 在 tera term 中显示字符 则 波特率调整成功

## 开始烧录

- 板卡端
  1. 启动烧录模式
     1. 关闭板卡电源
     2. 把板子设置SCIF 启动方式 SW1 小红板上 靠近数据线和风扇的那个开关

      | SW1                | PIN5 | PIN6 | PIN7 | PIN8 |
      | ------------------ | ---- | ---- | ---- | ---- |
      | 正常启动模式       | ON   | OFF  | ON   | ON   |
      | SCIF Download 模式 | OFF  | OFF  | OFF  | OFF  |
      
      打开板卡电源，在 teraterm 中显示 `please send!` 则进入烧录模式成功

     3. 然后把 WhiteHawk_CX_QSPI_eMMC_BL31.ttl 文件发送到板子
        1. control -> Macro -> 找到 v4h_bootloader.7z 解压后的 v4h 文件夹 中的 WhiteHawk_CX_QSPI_eMMC_BL31.ttl -> 打开
        [**NB: 路径必须是英文路径**]
     4. 烧录完之后，关闭电源改成正常启动模式再重启。
     5. 然后配置板子的启动参数。


      ```txt
      setenv ipaddr '<board_ip_addr>'  # IP address

      setenv ethaddr '2e:09:0a:0a:35:88'

      setenv serverip '<linux_host_server_ip>'

      setenv bootcmd 'tftp 0x48080000 <image_file_path_without_tftp_prefix> ; tftp 0x48000000 <dtb_file_path_without_tftp_prefix>; booti 0x48080000 - 0x48000000'

      setenv bootargs 'root=/dev/nfs rw nfsroot=<linux_host_server_ip>:<nfs_full_path_for_linux_file_system>,v3 ip=<board_ip_addr>::<gateway>:<subnet_mask>::eth0:off consoleblank=0 cma=760M@0x80000000 video=DP-1:1920x1080@60 clk_ignore_unused'

      saveenv
      ```

      样例：

      ```txt
      setenv ipaddr '172.28.28.112'  # IP address
      
      setenv ethaddr '2e:09:0a:0a:3b:02'
      
      setenv serverip '172.28.15.64'
      
      setenv bootcmd 'tftp 0x48080000 /rcar_3240rc/v4h/Image ; tftp 0x48000000 /rcar_3240rc/v4h/r8a779g0-whitehawk.dtb; booti 0x48080000 - 0x48000000'
      
      setenv bootargs 'root=/dev/nfs rw nfsroot=172.28.15.64:/srv/nfs/0241_rcar_3240rc,v3 ip=172.28.28.112::172.28.28.1:255.255.255.128::eth0:off consoleblank=0 cma=760M@0x80000000 video=DP-1:1920x1080@60 clk_ignore_unused'
      
      saveenv
      ```

     6. 重启板卡，看到 linux 启动成功，即可进入下一步。
     7. login, user: root  pwd: 

## 配置板卡网络设置

- 配置 静态 IP
  1. vim /etc/network/interfaces
  2. 配置eth0相关参数

  ```bash
  iface eth0 inet static
    netmask 255.255.255.128
    gateway 172.28.28.1
    dns-nameservers 172.28.15.82
  /etc/init.d/networking restart
  ```

- proxy方法
  - 在 linux host：

    ```bash
    sudo apt install squid
    sudo systemctl restart squid
    ```

  - 在板子：

    ```bash
    export http_proxy=172.28.28.23:3128
    export https_proxy=172.28.28.23:3128
    ```

Issue
------

tftp Address already in use

```bash
sudo netstat -lnp G 69
```

```bash
sudo /etc/init.d/xinetd stop
sudo service tftpd-hpa restart
sudo /etc/init.d/xinetd restart
```
