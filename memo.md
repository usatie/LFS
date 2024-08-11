## Setup VM (copy&paste)
sudo apt install open-vm-tools-desktop --fix-missing
sudo reboot

## 2.2 Host System Requirements
### To pass version-check.sh
bash version-check.sh
sudo apt install binutils bison gawk texinfo build-essential
ls -la /bin/sh
sudo rm /bin/sh
sudo ln -s bash /bin/sh
bash version-check.sh

### Utility
sudo apt install git vim
echo "alias gss='git status -s'" >> .bash_aliases
echo "alias ga='git add'" >> .bash_aliases
echo "alias gaa='git add --all'" >> .bash_aliases
echo "alias gc='git commit -v'" >> .bash_aliases
echo "alias gco='git checkout'" >> .bash_aliases
echo "alias gcm='git checkout main'" >> .bash_aliases
git config --global user.email 'usatie@gmail.com'
git config user.name 'Shun Usami'
git config --global core.editor "vim"

## 2.4. Creating a New Partition
sudo fdisk /dev/nvme0n < part.txt

## 2.5. Creating a File System on the Partition
sudo mkswap /dev/nvme0n1p3
sudo mkfs -v -t ext4 /dev/nvme0n1p4
sudo mkfs -v -t ext2 /dev/nvme0n1p5

## 2.6. Setting The $LFS Variable
echo "export LFS=/mnt/lfs" >> ~/.bash_profile
echo "export LFS=/mnt/lfs" >> ~/.bashrc
sudo bash -c "echo 'export LFS=/mnt/lfs' >> /root/.bash_profile"
sudo bash -c "echo 'export LFS=/mnt/lfs' >> /root/.bashrc"

## 2.7. Mounting the New Partition
sudo -i
mkdir -pv $LFS
mount -v -t ext4 /dev/nvme0n1p4 $LFS
/sbin/swapon -v /dev/nvme0n1p3
### Edit /etc/fstab
echo "/dev/nvme0n1p3	none	swap	sw	0	0" >> /etc/fstab
echo "/dev/nvme0n1p4	/mnt/lfs	ext4	defaults	1	1" >> /etc/fstab

# 3. Packages and Patches
## 3.1. Introduction
sudo -i
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
cd $LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv
wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
pushd $LFS/sources
  md5sum -c md5sums
popd
wget https://lfs.gnlug.org/pub/lfs/lfs-packages/12.1/expat-2.6.0.tar.xz --directory-prefix=$LFS/sources
pushd $LFS/sources
  md5sum -c md5sums
popd
chown root:root $LFS/sources/*
