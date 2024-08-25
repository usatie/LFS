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
sed '6009s/$add_dir//' -i ltmain.sh
mkdir build2 && cd build2
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

## 6.18. GCC-14.2.0 - Pass 2
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
