# Chapter 3
```
# As a `root` user
sudo su
bash 31_intro.sh
```

# Chapter 4
```
# As a `root` user
sudo su
bash 42_creating_a_limited_directory_layout.sh
bash 43_adding_the_lfs_user.sh

# As a `lfs` user
su - lfs
bash 44_setting_up_the_environment.sh
exit
```
# Chapter 5
```
# As a `root` user
sudo mkdir -pv $LFS/log

# As a `lfs` user
su - lfs
bash version-check.sh 
bash 5_compiling_a_cross_toolchain.sh
```

# Chapter 6
```
# As a `lfs` user
su - lfs
bash 6_cross_compiling_temporary_tools.sh
```

# Chapter 7
```
# As a `root` user
sudo su
# 7.2. Changing Ownership
# 7.3. Preparing Virtual Kernel File Systems
bash 72_73_preparing_chroot.sh

# 7.4. Entering the Chroot Environment
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

# 7.5. Creating Directories
# 7.6. Creating Essential Files and Symlinks
bash 75_76_creating_dirs_files_symlinks.sh

# 7.7. Gettext-0.22.4
# 7.8. Bison-3.8.2
# 7.9. Perl-5.38.2
# 7.10. Python-3.12.2
# 7.11. Texinfo-7.1
# 7.12. Util-linux-2.39.3
bash 77_712_building_additional_tools.sh

# 7.13. Cleaning up and Saving the Temporary System
# 7.13.1. Cleaning
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

# 7.13.2. Backup
# leave the chroot environment
exit

# As a `root` user
sudo su
bash 713_backup.sh

# prepare the chroot environment again
bash 72_73_preparing_chroot.sh

# chroot again
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

# Chapter 8
This must be done in chroot environment.
```
# 8.1 to 8.27
bash 81_827_installing_basic_system_software.sh

# 8.27.3. Setting the Root Password
passwd root

# 8.28 to 
bash 828_installing_basic_software2.sh
```

# Chapter 9
## 9.2.1. Installation of LFS-Bootscripts
tar -xvf lfs-bootscripts-20230728.tar.xz
cd lfs-bootscripts-20230728
make install

## 9.4.1.2. Creating Custom Udev Rules
bash /usr/lib/udev/init-net-rules.sh
cat /etc/udev/rules.d/70-persistent-net.rules
> cat: /etc/udev/rules.d/70-persistent-net.rules: No such file or directory
```
In some cases, such as when MAC addresses have been assigned to a network card manually, or in a virtual environment such as Qemu or Xen, the network rules file may not be generated because addresses are not consistently assigned. In these cases, this method cannot be used.
```

## 9.5.1. Creating Network Interface Configuration Files
cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF


## 9.5.2. Creating the /etc/resolv.conf File
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

# domain <Your Domain Name>
nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF


## 9.5.3. Configuring the System Hostname
echo "<lfs>" > /etc/hostname

## 9.5.4. Customizing the /etc/hosts File
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
# 127.0.1.1 <FQDN> <HOSTNAME>
# <192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

## 9.6.2. Configuring Sysvinit
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
