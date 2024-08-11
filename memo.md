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
