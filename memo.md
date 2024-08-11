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

# 4. Final Preparations
## 4.2. Creating a Limited Directory Layout in the LFS Filesystem
sudo -i
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

## 4.3 Adding the LFS User
sudo -i
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
su - lfs
### fix ($LFS/tools not found)
sudo -i
mkdir $LFS/tools
chown -v lfs $LFS/tools

## 4.4. Setting Up the Environment
### (As lfs user)
su - lfs

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF

source ~/.bash_profile

### (As root)
sudo -i
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

## 5.2 Binutils-2.42 - Pass 1
su - lfs
bash version-check.sh 

cd $LFS/sources
tar -xvf binutils-2.42.tar.xz
cd binutils-2.42
mkdir -v build
cd build/
time { ../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --enable-gprofng=no --disable-werror --enable-default-hash-style=gnu && make && make install; }

## 5.3. GCC-13.2.0 - Pass 1
tar -xvf gcc-13.2.0.tar.xz 
cd gcc-13.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

mkdir -v build
cd       build

time { ../configure                      --target=$LFS_TGT             --prefix=$LFS/tools           --with-glibc-version=2.39     --with-sysroot=$LFS           --with-newlib                 --without-headers             --enable-default-pie          --enable-default-ssp          --disable-nls                 --disable-shared              --disable-multilib            --disable-threads             --disable-libatomic           --disable-libgomp             --disable-libquadmath         --disable-libssp              --disable-libvtv              --disable-libstdcxx           --enable-languages=c,c++ && make && make install; }
cd ..
$LFS_TGT-gcc -print-libgcc-file-name
cat gcc/limitx.h gcc/glimits.h gcc/limity.h >   `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

## 5.4. Linux-6.7.4 API Headers
### 5.4.1. Installation of Linux API Headers
tar -xvf linux-6.7.4.tar.xz
cd linux-6.7.4

make mrproper

make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

## 5.5. Glibc-2.39
### 5.5.1. Installation of Glibc
su - lfs
tar -xvf glibc-2.39.tar.xz
cd glibc-2.39

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

patch -Np1 -i ../glibc-2.39-fhs-1.patch

mkdir -v build
cd       build

echo "rootsbindir=/usr/sbin" > configparms
time { ../configure                                   --prefix=/usr                            --host=$LFS_TGT                          --build=$(../scripts/config.guess)       --enable-kernel=4.19                     --with-headers=$LFS/usr/include          --disable-nscd                           libc_cv_slibdir=/usr/lib && make && make DESTDIR=$LFS install; }

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm -v a.out 
