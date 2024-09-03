# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/m4.html
cd $LFS/sources/
tar -xvf m4-1.4.19.tar.xz && cd m4-1.4.19

time { ./configure --prefix=/usr --host=$LFS_TGT --build=$(build-aux/config.guess) && make && make DESTDIR=$LFS install; } | tee $LFS/log/62_m4

cd $LFS/sources/
rm -rf m4-1.4.19

## https://www.linuxfromscratch.org/lfs/view/stable/chapter06/ncurses.html
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
	    --enable-widec | tee $LFS/log/63_ncurses_configure
time { make && make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install; } | tee $LFS/log/63_ncurses
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

cd $LFS/sources
rm -rf ncurses-6.4-20230520

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/bash.html
cd $LFS/sources/
tar -xvf bash-5.2.21.tar.gz && cd bash-5.2.21

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

make

make DESTDIR=$LFS install

ln -sv bash $LFS/bin/sh

cd $LFS/sources/
rm -rf bash-5.2.21

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/coreutils.html
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

cd $LFS/sources/
rm -rf coreutils-9.4

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/diffutils.html
cd $LFS/sources/
tar -xvf diffutils-3.10.tar.xz && cd diffutils-3.10

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess) && make && make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf diffutils-3.10

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/file.html
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

cd $LFS/sources/
rm -rf file-5.45 

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/findutils.html
cd $LFS/sources/
tar -xvf findutils-4.9.0.tar.xz && cd findutils-4.9.0 

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf findutils-4.9.0 

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/gawk.html
cd $LFS/sources/
tar -xvf gawk-5.3.0.tar.xz && cd gawk-5.3.0

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf gawk-5.3.0

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/grep.html
cd $LFS/sources/
tar -xvf grep-3.11.tar.xz && cd grep-3.11

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf grep-3.11

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/gzip.html
cd $LFS/sources/
tar -xvf gzip-1.13.tar.xz && cd gzip-1.13

./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf gzip-1.13

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/make.html
cd $LFS/sources/
tar -xvf make-4.4.1.tar.gz && cd make-4.4.1 

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf make-4.4.1 

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/patch.html
cd $LFS/sources/
tar -xvf patch-2.7.6.tar.xz && cd patch-2.7.6

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf patch-2.7.6

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/sed.html
cd $LFS/sources/
tar -xvf sed-4.9.tar.xz && cd sed-4.9

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf sed-4.9

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/tar.html
cd $LFS/sources/
tar -xvf tar-1.35.tar.xz && cd tar-1.35

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

cd $LFS/sources/
rm -rf tar-1.35

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/xz.html
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

cd $LFS/sources/
rm -rf xz-5.4.6

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/binutils-pass2.html
cd $LFS/sources/
tar -xvf binutils-2.42.tar.xz && cd binutils-2.42

sed '6009s/$add_dir//' -i ltmain.sh

mkdir build
cd build

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

cd $LFS/sources/
rm -rf binutils-2.42

# https://www.linuxfromscratch.org/lfs/view/stable/chapter06/gcc-pass2.html
cd $LFS/sources/
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

cd $LFS/sources/
rm -rf gcc-13.2.0
