# https://www.linuxfromscratch.org/lfs/view/stable/chapter05/binutils-pass1.html
cd $LFS/sources
tar -xvf binutils-2.42.tar.xz
cd binutils-2.42
mkdir -v build
cd build/
time { ../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --enable-gprofng=no --disable-werror --enable-default-hash-style=gnu && make && make install; } | tee $LFS/log/52_binutils

cd $LFS/sources
rm -rf binutils-2.42

# https://www.linuxfromscratch.org/lfs/view/stable/chapter05/gcc-pass1.html
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

time { ../configure --target=$LFS_TGT --prefix=$LFS/tools --with-glibc-version=2.39 --with-sysroot=$LFS --with-newlib --without-headers --enable-default-pie --enable-default-ssp --disable-nls --disable-shared --disable-multilib --disable-threads --disable-libatomic --disable-libgomp --disable-libquadmath --disable-libssp --disable-libvtv --disable-libstdcxx --enable-languages=c,c++ && make && make install; } | tee $LFS/log/53_gcc

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h >   `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

# https://www.linuxfromscratch.org/lfs/view/stable/chapter05/linux-headers.html
cd $LFS/sources
tar -xvf linux-6.7.4.tar.xz && cd linux-6.7.4

time { make mrproper && make headers && find usr/include -type f ! -name '*.h' -delete && cp -rv usr/include $LFS/usr; } | tee $LFS/log/54_linux_api_headers

cd $LFS/sources
rm -rf linux-6.7.4

# https://www.linuxfromscratch.org/lfs/view/stable/chapter05/glibc.html
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
time { ../configure  --prefix=/usr --host=$LFS_TGT --build=$(../scripts/config.guess) --enable-kernel=4.19 --with-headers=$LFS/usr/include --disable-nscd libc_cv_slibdir=/usr/lib && make && make DESTDIR=$LFS install; } | tee $LFS/log/55_glibc

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm -v a.out 

cd $LFS/sources
rm -rf glibc-2.39

# https://www.linuxfromscratch.org/lfs/view/stable/chapter05/gcc-libstdc++.html
cd $LFS/sources/

tar -xvf gcc-13.2.0.tar.xz && cd gcc-13.2.0

mkdir -v build
cd       build

time { ../libstdc++-v3/configure --host=$LFS_TGT --build=$(../config.guess) --prefix=/usr --disable-multilib --disable-nls --disable-libstdcxx-pch --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0 && make && make DESTDIR=$LFS install; } | tee $LFS/log/56_libstdc++

rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

cd $LFS/sources/
rm -rf gcc-13.2.0
