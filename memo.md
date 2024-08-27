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
  aarch64) mkdir -pv $LFS/lib64 ;;
esac

mkdir -pv $LFS/tools

## 4.3 Adding the LFS User
sudo -i
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
  aarch64) chown -v lfs $LFS/lib64 ;; 
esac
su - lfs

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
tar -xvf binutils-2.42.tar.xz && cd binutils-2.42
mkdir -v build
cd build/
time { ../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --enable-gprofng=no --disable-werror --enable-default-hash-style=gnu && make && make install; } | tee output

## 5.3. GCC-13.2.0 - Pass 1
cd $LFS/sources
tar -xvf gcc-13.2.0.tar.xz  && cd gcc-13.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
   sed -e '/m64=/s/lib64/lib/' \
       -i.orig gcc/config/i386/t-linux64
 ;;
  aarch64)
   sed -e '/mabi.lp64=/s/lib64/lib/' \
       -i.orig gcc/config/aarch64/t-aarch64-linux 
 ;;
esac

mkdir -v build
cd       build

time { ../configure --target=$LFS_TGT --prefix=$LFS/tools --with-glibc-version=2.39 --with-sysroot=$LFS --with-newlib --without-headers --enable-default-pie --enable-default-ssp --disable-nls --disable-shared --disable-multilib --disable-threads --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libssp --disable-libvtv --disable-libstdcxx --enable-languages=c,c++ && make && make install; } | tee output
cd ..
$LFS_TGT-gcc -print-libgcc-file-name
cat gcc/limitx.h gcc/glimits.h gcc/limity.h >   `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

## 5.4. Linux-6.7.4 API Headers
### 5.4.1. Installation of Linux API Headers
cd $LFS/sources
tar -xvf linux-6.7.4.tar.xz && cd linux-6.7.4

time { make mrproper && make headers && find usr/include -type f ! -name '*.h' -delete && cp -rv usr/include $LFS/usr; } | tee output


## 5.5. Glibc-2.39
### 5.5.1. Installation of Glibc
su - lfs
cd $LFS/sources
tar -xvf glibc-2.39.tar.xz && cd glibc-2.39

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
    aarch64) ln -sfv ../lib/ld-linux-aarch64.so.1 $LFS/lib64
             ln -sfv ../lib/ld-linux-aarch64.so.1 $LFS/lib64/ld-lsb-aarch64.so.3
    ;;
esac

patch -Np1 -i ../glibc-2.39-fhs-1.patch

mkdir -v build
cd       build

echo "rootsbindir=/usr/sbin" > configparms
time { ../configure  --prefix=/usr --host=$LFS_TGT --build=$(../scripts/config.guess) --enable-kernel=4.19 --with-headers=$LFS/usr/include --disable-nscd libc_cv_slibdir=/usr/lib && make && make DESTDIR=$LFS install; } | tee output

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
```
      [Requesting program interpreter: /lib/ld-linux-aarch64.so.1]
```
rm -v a.out 


## 5.6. Libstdc++ from GCC-13.2.0
cd $LFS/sources/
mv gcc-13.2.0 gcc-13.2.0.gcc-pass1
tar -xvf gcc-13.2.0.tar.xz && cd gcc-13.2.0
mkdir -v build
cd       build
time { ../libstdc++-v3/configure --host=$LFS_TGT --build=$(../config.guess) --prefix=/usr --disable-multilib --disable-nls --disable-libstdcxx-pch --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0 && make && make DESTDIR=$LFS install; } | tee output
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la


## 6.2. M4-1.4.19
su - lfs
cd $LFS/sources/
tar -xvf m4-1.4.19.tar.xz && cd m4-1.4.19
time { ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) && make && make DESTDIR=$LFS install; } | tee output

## 6.3.1. Installation of Ncurses
cd $LFS/sources/
tar -xvf ncurses-6.4-20230520.tar.xz && cd ncurses-6.4-20230520
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
	    --enable-widec
make && make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

### Errors
What should I do?
> This was because I forgot `--enable-widec` option when configure
```
$ ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
ln: failed to create symbolic link '/mnt/lfs/usr/lib/libncurses.so': File exists
$ ls -la $LFS/usr/lib/ | grep curses
lrwxrwxrwx 1 lfs lfs        17 Aug 23 12:41 libcurses.so -> libncurses.so.6.4
lrwxrwxrwx 1 lfs lfs        15 Aug 23 12:41 libncurses.so -> libncurses.so.6
lrwxrwxrwx 1 lfs lfs        17 Aug 23 12:41 libncurses.so.6 -> libncurses.so.6.4
-rwxr-xr-x 1 lfs lfs    452136 Aug 23 12:41 libncurses.so.6.4
```

## 6.4. Bash-5.2.32
cd $LFS/sources/
tar -xvf bash-5.2.21.tar.gz && cd bash-5.2.21
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc              \
            bash_cv_strtold_broken=no
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh

## 6.5. Coreutils-9.5
cd $LFS/sources/
tar -xvf coreutils-9.4.tar.xz && cd coreutils-9.4
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime && make && make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

## 6.6. Diffutils-3.10
cd $LFS/sources/
tar -xvf diffutils-3.10.tar.xz && cd diffutils-3.10
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess) && make && make DESTDIR=$LFS install

## 6.7. File-5.45
cd $LFS/sources/
tar -xvf file-5.45.tar.gz && cd file-5.45 
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

## 6.8. Findutils-4.10.0
cd $LFS/sources/
tar -xvf findutils-4.9.0.tar.xz && cd findutils-4.9.0 
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.9. Gawk-5.3.0
cd $LFS/sources/
tar -xvf gawk-5.3.0.tar.xz && cd gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.10. Grep-3.11
cd $LFS/sources/
tar -xvf grep-3.11.tar.xz && cd grep-3.11
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install


## 6.11. Gzip-1.13
cd $LFS/sources/
tar -xvf gzip-1.13.tar.xz && cd gzip-1.13
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

### Error
```
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13'
  CC       gzip.o
  CC       trees.o
  CC       unlzh.o
  CC       unlzw.o
In file included from gzip.c:75:
./lib/getopt.h:84:10: fatal error: getopt-cdefs.h: No such file or directory
   84 | #include <getopt-cdefs.h>
      |          ^~~~~~~~~~~~~~~~
compilation terminated.
make[2]: *** [Makefile:1946: gzip.o] Error 1
make[2]: *** Waiting for unfinished jobs....
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make[1]: *** [Makefile:2011: install-recursive] Error 1
make[1]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make: *** [Makefile:2320: install] Error 2
lfs:/mnt/lfs/sources/gzip-1.13$ make
make  all-recursive
make[1]: Entering directory '/mnt/lfs/sources/gzip-1.13'
Making all in lib
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13/lib'
make  all-am
make[3]: Entering directory '/mnt/lfs/sources/gzip-1.13/lib'
make[3]: Leaving directory '/mnt/lfs/sources/gzip-1.13/lib'
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13/lib'
Making all in doc
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13/doc'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13/doc'
Making all in .
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13'
  CC       gzip.o
  CC       unpack.o
  CC       unzip.o
  CC       util.o
In file included from gzip.c:75:
./lib/getopt.h:84:10: fatal error: getopt-cdefs.h: No such file or directory
   84 | #include <getopt-cdefs.h>
      |          ^~~~~~~~~~~~~~~~
compilation terminated.
make[2]: *** [Makefile:1946: gzip.o] Error 1
make[2]: *** Waiting for unfinished jobs....
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make[1]: *** [Makefile:2011: all-recursive] Error 1
make[1]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make: *** [Makefile:1792: all] Error 2
lfs:/mnt/lfs/sources/gzip-1.13$ make DESTDIR=$LFS install
make  install-recursive
make[1]: Entering directory '/mnt/lfs/sources/gzip-1.13'
Making install in lib
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13/lib'
make  install-am
make[3]: Entering directory '/mnt/lfs/sources/gzip-1.13/lib'
make[4]: Entering directory '/mnt/lfs/sources/gzip-1.13/lib'
make[4]: Nothing to be done for 'install-exec-am'.
make[4]: Nothing to be done for 'install-data-am'.
make[4]: Leaving directory '/mnt/lfs/sources/gzip-1.13/lib'
make[3]: Leaving directory '/mnt/lfs/sources/gzip-1.13/lib'
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13/lib'
Making install in doc
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13/doc'
make[3]: Entering directory '/mnt/lfs/sources/gzip-1.13/doc'
make[3]: Nothing to be done for 'install-exec-am'.
 /usr/bin/mkdir -p '/mnt/lfs/usr/share/info'
 /usr/bin/install -c -m 644 ./gzip.info '/mnt/lfs/usr/share/info'
 install-info --info-dir='/mnt/lfs/usr/share/info' '/mnt/lfs/usr/share/info/gzip.info'
make[3]: Leaving directory '/mnt/lfs/sources/gzip-1.13/doc'
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13/doc'
Making install in .
make[2]: Entering directory '/mnt/lfs/sources/gzip-1.13'
  CC       gzip.o
  CC       zip.o
  CC       version.o
  AR       libver.a
In file included from gzip.c:75:
./lib/getopt.h:84:10: fatal error: getopt-cdefs.h: No such file or directory
   84 | #include <getopt-cdefs.h>
      |          ^~~~~~~~~~~~~~~~
compilation terminated.
make[2]: *** [Makefile:1946: gzip.o] Error 1
make[2]: *** Waiting for unfinished jobs....
make[2]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make[1]: *** [Makefile:2011: install-recursive] Error 1
make[1]: Leaving directory '/mnt/lfs/sources/gzip-1.13'
make: *** [Makefile:2320: install] Error 2
```

`make clean` fixed the error above
https://www.linuxquestions.org/questions/linux-from-scratch-13/configure-file-not-creating-getopt-cdefs-h-from-it%27s-in-h-file-grep-3-11-a-4175734112/
```
make clean
make
make DESTDIR=$LFS install
```

## 6.12. Make-4.4.1
cd $LFS/sources/
tar -xvf make-4.4.1.tar.gz && cd make-4.4.1 
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.13. Patch-2.7.6
cd $LFS/sources/
tar -xvf patch-2.7.6.tar.xz && cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.14. Sed-4.9
cd $LFS/sources/
tar -xvf sed-4.9.tar.xz && cd sed-4.9
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.15. Tar-1.35
cd $LFS/sources/
tar -xvf tar-1.35.tar.xz && cd tar-1.35
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

## 6.16. Xz-5.6.2
cd $LFS/sources/
tar -xvf xz-5.4.6.tar.xz && cd xz-5.4.6
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.4.6
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la

## 6.17. Binutils-2.43.1 - Pass 2
cd $LFS/sources/
mv binutils-2.42 binutils-2.42.pass1
tar -xvf binutils-2.42.tar.xz && cd binutils-2.42
sed '6009s/$add_dir//' -i ltmain.sh
mkdir build && cd build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

## 6.18. GCC-14.2.0 - Pass 2
mv gcc-13.2.0 gcc-13.2.0.libstdc++
tar -xvf gcc-13.2.0.tar.xz && cd gcc-13.2.0
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
   sed -e '/m64=/s/lib64/lib/' \
       -i.orig gcc/config/i386/t-linux64
 ;;
  aarch64)
   sed -e '/mabi.lp64=/s/lib64/lib/' \
       -i.orig gcc/config/aarch64/t-aarch64-linux 
 ;;
esac
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -v build
cd       build
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc

## 7.2. Changing Ownership
sudo -i
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
  aarch64) chown -R root:root $LFS/lib64 ;;
esac

## 7.3. Preparing Virtual Kernel File Systems
mkdir -pv $LFS/{dev,proc,sys,run}

mount -v --bind /dev $LFS/dev

mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

## 7.4. Entering the Chroot Environment
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

## 7.5. Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

## 7.6. Creating Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

exec /usr/bin/bash --login

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

## 7.7. Gettext-0.22.4
cd /sources/ && tar -xvf gettext-0.22.4.tar.xz && cd gettext-0.22.4
./configure --disable-shared && make && ./configure --disable-shared

## 7.8. Bison-3.8.2
cd /sources/ && tar -xvf bison-3.8.2.tar.xz && cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2 && make && make install

## 7.9. Perl-5.38.2
cd /sources/ && tar -xvf perl-5.38.2.tar.xz && cd perl-5.38.2
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Duseshrplib                                \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl     \
             -Darchlib=/usr/lib/perl5/5.38/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl && make && make install

## 7.10. Python-3.12.2
cd /sources/ && tar -xvf Python-3.12.2.tar.xz && cd Python-3.12.2
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip && make && make install

## 7.11. Texinfo-7.1
cd /sources/ && tar -xvf texinfo-7.1.tar.xz && cd texinfo-7.1
./configure --prefix=/usr && make && make install

## 7.12. Util-linux-2.39.3
cd /sources/ && tar -xvf util-linux-2.39.3.tar.xz && cd util-linux-2.39.3
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib    \
            --runstatedir=/run   \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3 && make && make install

## 7.13. Cleaning up and Saving the Temporary System
### 7.13.1. Cleaning
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

### 7.13.2. Backup
(leave the chroot environment)
exit
(as root)
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}

cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.1-systemd.tar.xz .

```
mkdir -pv $LFS/{dev,proc,sys,run}

mount -v --bind /dev $LFS/dev

mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

## 8.2. Package Management
## 8.3. Man-pages-6.06
> Only files, `man` command still not available
cd /sources/ && tar -xvf man-pages-6.06.tar.xz && cd man-pages-6.06
rm -v man3/crypt*
make prefix=/usr install

## 8.4. Iana-Etc-20240125
tar -xvf iana-etc-20240125.tar.gz && cd iana-etc-20240125 
cp services protocols /etc

## 8.5. Glibc-2.39
cd /sources
mv glibc-2.39 glibc-2.39.chapter5.5
cd /sources/ && tar xvf glibc-2.39.tar.xz && cd glibc-2.39
patch -Np1 -i ../glibc-2.39-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib
make
make check
grep "Timed out" -l $(find -name \*.out)
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

### 8.5.2. Configuring Glibc
#### 8.5.2.1. Adding nsswitch.conf
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

#### 8.5.2.2. Adding Time Zone Data
tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
tzselect
ln -sfv /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

#### 8.5.2.3. Configuring the Dynamic Loader
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

## 8.6. Zlib-1.3.1
cd /sources/ && tar -xvf zlib-1.3.1.tar.gz && cd zlib-1.3.1
./configure --prefix=/usr
make
make check
make install
rm -fv /usr/lib/libz.a

## 8.7. Bzip2-1.0.8
cd /sources/ && tar -xvf bzip2-1.0.8.tar.gz && cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a

## 8.8. Xz-5.4.6
cd /sources
mv xz-5.4.6 xz-5.4.6.chapter5
cd /sources/ && tar -xvf xz-5.4.6.tar.xz && cd xz-5.4.6
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.6
make
make check
make install

## 8.9. Zstd-1.5.5
cd /sources && tar -xvf zstd-1.5.5.tar.gz && cd zstd-1.5.5
make prefix=/usr
make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a

## 8.10. File-5.45
mv file-5.45 file-5.45.chapter5
cd /sources/ && tar -xvf file-5.45.tar.gz && cd file-5.45
./configure --prefix=/usr
make
make check
make install

## 8.11. Readline-8.2
cd /sources/ && tar -xvf readline-8.2.tar.gz && cd readline-8.2
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
patch -Np1 -i ../readline-8.2-upstream_fixes-3.patch
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install

## 8.12. M4-1.4.19
cd /sources/ && tar -xvf m4-1.4.19.tar.xz && cd m4-1.4.19 
./configure --prefix=/usr
make
make check
make install

## 8.13. Bc-6.7.5
cd /sources/ && tar -xvf bc-6.7.5.tar.xz && cd bc-6.7.5
CC=gcc ./configure --prefix=/usr -G -O3 -r
make
make test
make install

## 8.14. Flex-2.6.4
cd /sources/ && tar -xvf flex-2.6.4.tar.gz && cd flex-2.6.4 
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
make check
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

## 8.15. Tcl-8.6.13
cd /sources/ && tar -xvf tcl8.6.13-src.tar.gz && cd tcl8.6.13
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man

make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR

make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd ..
tar -xf ../tcl8.6.13-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.13
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.13

## 8.16 Expect-5.45.4
cd /sources/ && tar -xvf expect5.45.4.tar.gz && cd expect5.45.4
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include \
            --build=aarch64-unknown-linux-gnu
make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

## 8.17. DejaGNU-1.6.3
cd /sources/ && tar -xvf dejagnu-1.6.3.tar.gz && cd dejagnu-1.6.3
mkdir -v build
cd       build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

## 8.18. Pkgconf-2.1.1
cd /sources/ && tar -xvf pkgconf-2.1.1.tar.xz && cd pkgconf-2.1.1 
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.1.1
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

## 8.19. Binutils-2.42
mv binutils-2.42 binutils-2.42.chapter5
cd /sources/ && tar -xvf binutils-2.42.tar.xz && cd binutils-2.42
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib  \
             --enable-default-hash-style=gnu
make tooldir=/usr
make -k check
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
cd /sources/
rm -rf binutils-2.42

## 8.20. GMP-6.3.0
cd /sources/ && tar -xvf gmp-6.3.0.tar.xz && cd gmp-6.3.0
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html
cd /sources
rm -rf gmp-6.3.0

## 8.21. MPFR-4.2.1
cd /sources/ && tar -xvf mpfr-4.2.1.tar.xz && cd mpfr-4.2.1
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1
make
make html
make check
make install
make install-html

cd ..
rm -rf mpfr-4.2.1

## 8.22. MPC-1.3.1
cd /sources/ && tar -xvf mpc-1.3.1.tar.gz && cd mpc-1.3.1
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
make
make html
make check
make install
make install-html

cd ..
rm -rf mpc-1.3.1

## 8.23. Attr-2.5.2
cd /sources/ && tar -xvf attr-2.5.2.tar.gz && cd attr-2.5.2
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
make
make check
make install

cd ..
rm -rf attr-2.5.2

## 8.24. Acl-2.3.2
cd /sources/ && tar -xvf acl-2.3.2.tar.xz && cd acl-2.3.2
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2
make
make install

cd ..
rm -rf acl-2.3.2

## 8.25. Libcap-2.69
cd /sources/ && tar -xvf libcap-2.69.tar.xz && cd libcap-2.69
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install

cd ..
rm -rf libcap-2.69

## 8.26. Libxcrypt-4.4.36
cd /sources/ && tar -xvf libxcrypt-4.4.36.tar.xz && cd libxcrypt-4.4.36
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
make
make check
make install

cd ..
rm -rf libxcrypt-4.4.36

## 8.27. Shadow-4.14.5
cd /sources/ && tar -xvf shadow-4.14.5.tar.xz && cd shadow-4.14.5
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
sed -i 's:DICTPATH.*:DICTPATH\t/lib/cracklib/pw_dict:' etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man

pwconv
grpconv

useradd -D
mkdir -p /etc/default
useradd -D --gid 999
useradd -D

passwd root

cd ..
rm -rf shadow-4.14.5

## 8.28 GCC-13.2.0
cd /sources/ && tar -xvf gcc-13.2.0.tar.xz && cd gcc-13.2.0
case $(uname -m) in
  x86_64)
   sed -e '/m64=/s/lib64/lib/' \
       -i.orig gcc/config/i386/t-linux64
 ;;
  aarch64)
   sed -e '/mabi.lp64=/s/lib64/lib/' \
       -i.orig gcc/config/aarch64/t-aarch64-linux 
 ;;
esac

mkdir -v build
cd       build

../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
make
ulimit -s 32768
chown -R tester .
su tester -c "PATH=$PATH make -k -j4 check"
../contrib/test_summary

## 10.3 Linux-6.6.7
cp -iv arch/arm64/boot/Image /boot/vmlinuz-6.x-lfs-systemd 

## 10.4 Using GRUB to Set Up the Boot Process
grub-install --target=arm64-efi --removable /dev/sda


