# 7.7. Gettext-0.22.4
cd /sources/
tar -xvf gettext-0.22.4.tar.xz
cd gettext-0.22.4

./configure --disable-shared && make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources/
rm -rf gettext-0.22.4

# 7.8. Bison-3.8.2
cd /sources/
tar -xvf bison-3.8.2.tar.xz
cd bison-3.8.2

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2 && make && make install

cd /sources/
rm -rf bison-3.8.2

# 7.9. Perl-5.38.2
cd /sources/
tar -xvf perl-5.38.2.tar.xz
cd perl-5.38.2

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

cd /sources/
rm -rf perl-5.38.2

## 7.10. Python-3.12.2
cd /sources
tar -xvf Python-3.12.2.tar.xz
cd Python-3.12.2

./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip && make && make install

cd /sources
rm -rf Python-3.12.2.tar.xz

## 7.11. Texinfo-7.1
cd /sources
tar -xvf texinfo-7.1.tar.xz
cd texinfo-7.1

./configure --prefix=/usr && make && make install

cd /sources
rm -rf texinfo-7.1

## 7.12. Util-linux-2.39.3
cd /sources
tar -xvf util-linux-2.39.3.tar.xz
cd util-linux-2.39.3

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

cd /sources
rm -rf util-linux-2.39.3
