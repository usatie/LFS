## 8.3. Man-pages-6.06
## (Only files, `man` command still not available)
cd /sources
tar -xvf man-pages-6.06.tar.xz
cd man-pages-6.06

rm -v man3/crypt*
make prefix=/usr install

cd /sources
rm -rf man-pages-6.06

## 8.4. Iana-Etc-20240125
tar -xvf iana-etc-20240125.tar.gz
cd iana-etc-20240125 

cp services protocols /etc

cd /sources
rm -rf iana-etc-20240125

## 8.5. Glibc-2.39
cd /sources
tar xvf glibc-2.39.tar.xz
cd glibc-2.39

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

# Omit the next command because I already know my locale is America/Los_Angeles
# tzselect
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

cd /sources
rm -rf glibc-2.39

## 8.6. Zlib-1.3.1
cd /sources/
tar -xvf zlib-1.3.1.tar.gz
cd zlib-1.3.1

./configure --prefix=/usr

make
make check
make install
rm -fv /usr/lib/libz.a

cd /sources
rm -rf zlib-1.3.1

## 8.7. Bzip2-1.0.8
cd /sources/
tar -xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8

patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install

# Install the shared library
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

# Install the shared bzip2 binary, and replace two copies of bzip2 with symlinks
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

# Remove a useless static library
rm -fv /usr/lib/libbz2.a

cd /sources
rm -rf bzip2-1.0.8

## 8.8. Xz-5.4.6
cd /sources
tar -xvf xz-5.4.6.tar.xz
cd xz-5.4.6

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.6
make
make check
make install

cd /sources
rm -rf xz-5.4.6

## 8.9. Zstd-1.5.5
cd /sources
tar -xvf zstd-1.5.5.tar.gz
cd zstd-1.5.5

make prefix=/usr
make check
make prefix=/usr install

# Remove the static library:
rm -v /usr/lib/libzstd.a

cd /sources
rm -rf zstd-1.5.5

## 8.10. File-5.45
cd /sources
tar -xvf file-5.45.tar.gz
cd file-5.45

./configure --prefix=/usr
make
make check
make install

cd /sources
rm -rf file-5.45

## 8.11. Readline-8.2
cd /sources
tar -xvf readline-8.2.tar.gz
cd readline-8.2

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

patch -Np1 -i ../readline-8.2-upstream_fixes-3.patch

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2

make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install

# install the documentation
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2

cd /sources
rm -rf readline-8.2

## 8.12. M4-1.4.19
cd /sources
tar -xvf m4-1.4.19.tar.xz
cd m4-1.4.19 

./configure --prefix=/usr
make
make check
make install

cd /sources
rm -rf m4-1.4.19

## 8.13. Bc-6.7.5
cd /sources
tar -xvf bc-6.7.5.tar.xz
cd bc-6.7.5

# Prepare Bc for compilation
CC=gcc ./configure --prefix=/usr -G -O3 -r

make
make test
make install

cd /sources
rm -rf bc-6.7.5

## 8.14. Flex-2.6.4
cd /sources
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4 

./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make
make check
make install

# create a symbolic link named lex that runs flex in lex emulation mode
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

cd /sources
rm -rf flex-2.6.4

## 8.15. Tcl-8.6.13
cd /sources
tar -xvf tcl8.6.13-src.tar.gz
cd tcl8.6.13

# Prepare Tcl for compilation
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

# install the documentation
cd ..
tar -xf ../tcl8.6.13-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.13
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.13

cd /sources
rm -rf  tcl8.6.13

## 8.16 Expect-5.45.4
cd /sources
tar -xvf expect5.45.4.tar.gz
cd expect5.45.4

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

cd /sources
rm -rf expect5.45.4

## 8.17. DejaGNU-1.6.3
cd /sources
tar -xvf dejagnu-1.6.3.tar.gz
cd dejagnu-1.6.3

mkdir -v build
cd       build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd /sources
rm -rf dejagnu-1.6.3

## 8.18. Pkgconf-2.1.1
cd /sources
tar -xvf pkgconf-2.1.1.tar.xz
cd pkgconf-2.1.1 

./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.1.1
make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd /sources
rm -rf pkgconf-2.1.1

## 8.19. Binutils-2.42
cd /sources
tar -xvf binutils-2.42.tar.xz
cd binutils-2.42

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

# Remove useless static libraries
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a

cd /sources/
rm -rf binutils-2.42

## 8.20. GMP-6.3.0
cd /sources
tar -xvf gmp-6.3.0.tar.xz
cd gmp-6.3.0

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
cd /sources
tar -xvf mpfr-4.2.1.tar.xz
cd mpfr-4.2.1

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
cd /sources
tar -xvf mpc-1.3.1.tar.gz
cd mpc-1.3.1

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
cd /sources
tar -xvf attr-2.5.2.tar.gz
cd attr-2.5.2

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
cd /sources
tar -xvf acl-2.3.2.tar.xz
cd acl-2.3.2

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2
make
make install

cd ..
rm -rf acl-2.3.2

## 8.25. Libcap-2.69
cd /sources
tar -xvf libcap-2.69.tar.xz
cd libcap-2.69

sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install

cd ..
rm -rf libcap-2.69

## 8.26. Libxcrypt-4.4.36
cd /sources
tar -xvf libxcrypt-4.4.36.tar.xz
cd libxcrypt-4.4.36

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
cd /sources
tar -xvf shadow-4.14.5.tar.xz
cd shadow-4.14.5

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

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

cd ..
rm -rf shadow-4.14.5
