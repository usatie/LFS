## 8.28 GCC-13.2.0
cd /sources
tar -xvf gcc-13.2.0.tar.xz
cd gcc-13.2.0

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
../contrib/test_summary | grep -A7 Summ

make install
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log

grep -B4 '^ /usr/include' dummy.log

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

grep "/lib.*/libc.so.6 " dummy.log

grep found dummy.log

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd /sources
rm -rf gcc-13.2.0


# 8.29. Ncurses-6.4-20230520
cd /sources
tar -xvf ncurses-6.4-20230520.tar.xz
cd ncurses-6.4-20230520

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make

make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.4
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so

cp -v -R doc -T /usr/share/doc/ncurses-6.4-20230520

cd /sources
rm -rf ncurses-6.4-20230520

# 8.30. Sed-4.9
cd /sources/
tar -xvf sed-4.9.tar.xz
cd sed-4.9

./configure --prefix=/usr

# Compile the package and generate the HTML documentation
make
make html

# To test the results
chown -R tester .
su tester -c "PATH=$PATH make check"

# Install the package and its documentation:
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd /sources/
rm -rf sed-4.9

# 8.31. Psmisc-23.6
cd /sources/
tar -xvf psmisc-23.6.tar.xz
cd psmisc-23.6

./configure --prefix=/usr
# Compile the package:
make
# To run the test suite, run:
make check
# Install the package:
make install

cd /sources/
rm -rf psmisc-23.6

# 8.32. Gettext-0.22.4
cd /sources/
tar -xvf gettext-0.22.4.tar.xz
cd gettext-0.22.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.4

# Compile the package:
make

# To test the results (this takes a long time, around 3 SBUs), issue:
make check

# Install the package:
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd /sources/
rm -rf gettext-0.22.4

# 8.33. Bison-3.8.2
cd /sources/
tar -xvf bison-3.8.2.tar.xz
cd bison-3.8.2

# Prepare Bison for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
# Compile the package:
make
# To test the results (about 5.5 SBU), issue:
make check
# Install the package:
make install

cd /sources/
rm -rf bison-3.8.2

# 8.34. Grep-3.11
cd /sources/
tar -xvf grep-3.11.tar.xz
cd grep-3.11

# First, remove a warning about using egrep and fgrep that makes tests on some packages fail:
sed -i "s/echo/#echo/" src/egrep.sh
# Prepare Grep for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf grep-3.11

# 8.35. Bash-5.2.21
cd /sources/
tar -xvf bash-5.2.21.tar.gz
cd bash-5.2.21

# First, fix some issues identified upstream:
patch -Np1 -i ../bash-5.2.21-upstream_fixes-1.patch

# Prepare Bash for compilation:
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.21

# Compile the package:
make

# Prepare tests
chown -R tester .
su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

# Install the package:
make install

# Run the newly compiled bash program (replacing the one that is currently being executed):
exec /usr/bin/bash --login

cd /sources/
rm -rf bash-5.2.21

# 8.36. Libtool-2.4.7
cd /sources/
tar -xvf libtool-2.4.7.tar.xz
cd libtool-2.4.7

# Prepare Libtool for compilation:
./configure --prefix=/usr

# Compile the package:
make

# To test the results, issue:
make -k check
## a lot of failures
## ERROR: 138 tests were run,
## 66 failed (59 expected failures).
## 31 tests were skipped.


# Install the package:
make install

# Remove a useless static library:
rm -fv /usr/lib/libltdl.a

cd /sources/
rm -rf libtool-2.4.7

# 8.37. GDBM-1.23
cd /sources/
tar -xvf gdbm-1.23.tar.gz
cd gdbm-1.23

# Prepare GDBM for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf gdbm-1.23

# 8.38. Gperf-3.1
cd /sources/
tar -xvf gperf-3.1.tar.gz
cd gperf-3.1

# Prepare Gperf for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
# Compile the package:
make
# The tests are known to fail if running multiple simultaneous tests (-j option greater than 1). To test the results, issue:
make -j1 check
# Install the package:
make install

cd /sources/
rm -rf gperf-3.1

# 8.39. Expat-2.6.0
cd /sources/
tar -xvf expat-2.6.0.tar.xz
cd expat-2.6.0

# Prepare Expat for compilation:
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.0
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install
# install the documentation:
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.0

cd /sources/
rm -rf expat-2.6.0

# 8.40. Inetutils-2.5
cd /sources/
tar -xvf inetutils-2.5.tar.xz
cd inetutils-2.5

# Prepare Inetutils for compilation:
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install
# Move a program to the proper location:
mv -v /usr/{,s}bin/ifconfig

cd /sources/
rm -rf inetutils-2.5

# 8.41. Less-643
cd /sources/
tar -xvf less-643.tar.gz
cd less-643

# Prepare Less for compilation:
./configure --prefix=/usr --sysconfdir=/etc

# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf less-643

# 8.42. Perl-5.38.2
cd /sources/
tar -xvf perl-5.38.2.tar.xz
cd perl-5.38.2

# use the libraries installed on the system
export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads

# Compile the package:
make
# To test the results (approximately 11 SBU), issue:
TEST_JOBS=$(nproc) make test_harness
# Install the package and clean up:
make install
unset BUILD_ZLIB BUILD_BZIP2

cd /sources/
rm -rf perl-5.38.2

# 8.43. XML::Parser-2.47
cd /sources/
tar -xvf XML-Parser-2.47.tar.gz
cd XML-Parser-2.47

# Prepare XML::Parser for compilation:
perl Makefile.PL
# Compile the package:
make
# To test the results, issue:
make test
# Install the package:
make install

cd /sources/
rm -rf XML-Parser-2.47

# 8.44. Intltool-0.51.0
cd /sources/
tar -xvf intltool-0.51.0.tar.gz
cd intltool-0.51.0

# First fix a warning that is caused by perl-5.22 and later:
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

# Prepare Intltool for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd /sources/
rm -rf intltool-0.51.0

# 8.45. Autoconf-2.72
cd /sources/
tar -xvf autoconf-2.72.tar.xz
cd autoconf-2.72

# Prepare Autoconf for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf autoconf-2.72

# 8.46. Automake-1.16.5
cd /sources/
tar -xvf automake-1.16.5.tar.xz
cd automake-1.16.5

# Prepare Automake for compilation:
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
# Compile the package:
make
# Using four parallel jobs speeds up the tests, even on systems with less logical cores, due to internal delays in individual tests. To test the results, issue:
make -j$(($(nproc)>4?$(nproc):4)) check
# Install the package:
make install

cd /sources/
rm -rf automake-1.16.5

# 8.47. OpenSSL-3.2.1
cd /sources/
tar -xvf openssl-3.2.1.tar.gz
cd openssl-3.2.1

# Prepare OpenSSL for compilation:
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
# Compile the package:
make
# To test the results, issue:
HARNESS_JOBS=$(nproc) make test

# Install the package:
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
# Add the version to the documentation directory name, to be consistent with other packages:
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.2.1
# If desired, install some additional documentation:
cp -vfr doc/* /usr/share/doc/openssl-3.2.1

cd /sources/
rm -rf openssl-3.2.1


# 8.48. Kmod-31
cd /sources/
tar -xvf kmod-31.tar.xz
cd kmod-31

# Prepare Kmod for compilation:
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib

# Compile the package:
make

# Install the package and create symlinks for compatibility with Module-Init-Tools (the package that previously handled Linux kernel modules):

make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done

ln -sfv kmod /usr/bin/lsmod

cd /sources/
rm -rf kmod-31

# 8.49. Libelf from Elfutils-0.190
cd /sources/
tar -xvf elfutils-0.190.tar.bz2
cd elfutils-0.190

# Prepare Libelf for compilation:
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
# Compile the package:
make
# To test the results, issue:
make check
# Install only Libelf:
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd /sources/
rm -rf elfutils-0.190

# 8.50. Libffi-3.4.4
cd /sources/
tar -xvf libffi-3.4.4.tar.gz
cd libffi-3.4.4

# Prepare Libffi for compilation:
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native

# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf libffi-3.4.4

# 8.51. Python-3.12.2
cd /sources/
tar -xvf Python-3.12.2.tar.xz
cd Python-3.12.2

# Prepare Python for compilation:
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations

# Compile the package:
make
# Install the package:
make install

# creates a configuration file:
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

# install the preformatted documentation:
install -v -dm755 /usr/share/doc/python-3.12.2/html
tar --no-same-owner \
    -xvf ../python-3.12.2-docs-html.tar.bz2
cp -R --no-preserve=mode python-3.12.2-docs-html/* \
    /usr/share/doc/python-3.12.2/html

cd /sources/
rm -rf Python-3.12.2

# 8.52. Flit-Core-3.9.0
cd /sources/
tar -xvf flit_core-3.9.0.tar.gz
cd flit_core-3.9.0

# Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
# Install the package:
pip3 install --no-index --no-user --find-links dist flit_core

cd /sources/
rm -rf flit_core-3.9.0

# 8.53. Wheel-0.42.0
cd /sources/
tar -xvf wheel-0.42.0.tar.gz
cd wheel-0.42.0

# Compile Wheel with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
# Install Wheel with the following command:
pip3 install --no-index --find-links=dist wheel

cd /sources/
rm -rf wheel-0.42.0

# 8.54. Setuptools-69.1.0
cd /sources/
tar -xvf setuptools-69.1.0.tar.gz
cd setuptools-69.1.0

# Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
# Install the package:
pip3 install --no-index --find-links dist setuptools

cd /sources/
rm -rf setuptools-69.1.0

# 8.55. Ninja-1.11.1
cd /sources/
tar -xvf ninja-1.11.1.tar.gz
cd ninja-1.11.1

# Using the optional procedure below allows a user to limit the number of parallel processes via an environment variable, NINJAJOBS. For example, setting:
export NINJAJOBS=4
# If desired, make ninja recognize the environment variable NINJAJOBS by running the stream editor:
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
# Build Ninja with:
python3 configure.py --bootstrap

# To test the results, issue:
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
# Install the package:
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

cd /sources/
rm -rf ninja-1.11.1

# 8.56. Meson-1.3.2
cd /sources/
tar -xvf meson-1.3.2.tar.gz
cd meson-1.3.2

# Compile Meson with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package:
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd /sources/
rm -rf meson-1.3.2

# 8.57. Coreutils-9.4
cd /sources/
tar -xvf coreutils-9.4.tar.xz
cd coreutils-9.4

# The following patch fixes this non-compliance and other internationalization-related bugs.
patch -Np1 -i ../coreutils-9.4-i18n-1.patch

# Fix a security vulnerability in the split utility:
sed -e '/n_out += n_hold/,+4 s|.*bufsize.*|//&|' \
    -i src/split.c

# prepare Coreutils for compilation:
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

# Compile the package:
make

# run the tests that are meant to be run as user root:
make NON_ROOT_USERNAME=tester check-root

# add a temporary group and make the user tester a part of it:
groupadd -g 102 dummy -U tester

# Fix some of the permissions so that the non-root user can compile and run the tests:
chown -R tester . 

# Now run the tests:
su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
# FAIL tests/tty/tty.sh (exit status: 1)
# https://www.reddit.com/r/LFS/comments/1edojif/lfs_stable_121_chapter_857_coreutils94/


# Remove the temporary group:
groupdel dummy

# Install the package:
make install

# Move programs to the locations specified by the FHS:
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

cd /sources/
rm -rf coreutils-9.4

# 8.58. Check-0.15.2
cd /sources/
tar -xvf check-0.15.2.tar.gz
cd check-0.15.2

# Prepare Check for compilation:
./configure --prefix=/usr --disable-static
# Build the package:
make
# Compilation is now complete. To run the Check test suite, issue the following command:
make check
# Install the package:
make docdir=/usr/share/doc/check-0.15.2 install

cd /sources/
rm -rf check-0.15.2

# 8.59. Diffutils-3.10
cd /sources/
tar -xvf diffutils-3.10.tar.xz
cd diffutils-3.10

# Prepare Diffutils for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf diffutils-3.10

# 8.60. Gawk-5.3.0
cd /sources/
tar -xvf gawk-5.3.0.tar.xz
cd gawk-5.3.0

# First, ensure some unneeded files are not installed:
sed -i 's/extras//' Makefile.in
# Prepare Gawk for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
chown -R tester .
su tester -c "PATH=$PATH make check"
# Install the package:
rm -f /usr/bin/gawk-5.3.0
make install

# The installation process already created awk as a symlink to gawk, create its man page as a symlink as well:
ln -sv gawk.1 /usr/share/man/man1/awk.1
# If desired, install the documentation:
mkdir -pv                                   /usr/share/doc/gawk-5.3.0
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0

cd /sources/
rm -rf gawk-5.3.0

# 8.61. Findutils-4.9.0
cd /sources/
tar -xvf findutils-4.9.0.tar.xz
cd findutils-4.9.0

# Prepare Findutils for compilation:
./configure --prefix=/usr --localstatedir=/var/lib/locate

# Compile the package:
make
# To test the results, issue:
chown -R tester .
su tester -c "PATH=$PATH make check"
# Install the package:
make install

cd /sources/
rm -rf findutils-4.9.0

# 8.62. Groff-1.23.0
cd /sources/
tar -xvf groff-1.23.0.tar.gz
cd groff-1.23.0

# Prepare Groff for compilation:
PAGE=letter ./configure --prefix=/usr
# Build the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf groff-1.23.0

# 8.63. GRUB-2.12
cd /sources/
tar -xvf grub-2.12.tar.xz
cd grub-2.12

unset {C,CPP,CXX,LD}FLAGS

# Add a file missing from the release tarball:
echo depends bli part_gpt > grub-core/extra_deps.lst
# Prepare GRUB for compilation:
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
# Compile the package:
make
# Install the package:
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd /sources/
rm -rf grub-2.12

# 8.64. Gzip-1.13
cd /sources/
tar -xvf gzip-1.13.tar.xz
cd gzip-1.13

# Prepare Gzip for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf gzip-1.13

# 8.65. IPRoute2-6.7.0
cd /sources/
tar -xvf iproute2-6.7.0.tar.xz
cd iproute2-6.7.0

# The arpd program included in this package will not be built since it depends on Berkeley DB, which is not installed in LFS. However, a directory and a man page for arpd will still be installed. Prevent this by running the commands shown below.
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
# Compile the package:
make NETNS_RUN_DIR=/run/netns
# This package does not have a working test suite.
# Install the package:
make SBINDIR=/usr/sbin install
# If desired, install the documentation:
mkdir -pv             /usr/share/doc/iproute2-6.7.0
cp -v COPYING README* /usr/share/doc/iproute2-6.7.0

cd /sources/
rm -rf iproute2-6.7.0

# 8.66. Kbd-2.6.4
cd /sources/
tar -xvf kbd-2.6.4.tar.xz
cd kbd-2.6.4

# The following patch fixes this issue for i386 keymaps:
patch -Np1 -i ../kbd-2.6.4-backspace-1.patch
# Remove the redundant resizecons program (it requires the defunct svgalib to provide the video mode files - for normal use setfont sizes the console appropriately) together with its manpage.
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
# Prepare Kbd for compilation:
./configure --prefix=/usr --disable-vlock

# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install
# If desired, install the documentation:
cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4

cd /sources/
rm -rf kbd-2.6.4

# 8.67. Libpipeline-1.5.7
cd /sources/
tar -xvf libpipeline-1.5.7.tar.gz
cd libpipeline-1.5.7

# Prepare Libpipeline for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf libpipeline-1.5.7

# 8.68. Make-4.4.1
cd /sources/
tar -xvf make-4.4.1.tar.gz
cd make-4.4.1

# Prepare Make for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
chown -R tester .
su tester -c "PATH=$PATH make check"
# Install the package:
make install

cd /sources/
rm -rf make-4.4.1

# 8.69. Patch-2.7.6
cd /sources/
tar -xvf patch-2.7.6.tar.xz
cd patch-2.7.6

# Prepare Patch for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf patch-2.7.6

# 8.70. Tar-1.35
cd /sources/
tar -xvf tar-1.35.tar.xz
cd tar-1.35

# Prepare Tar for compilation:
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

# Compile the package:
make
# To test the results, issue:
make check
# This is known to fail
# 233: capabilities: binary store/restore              FAILED (capabs_raw01.at:28)
# Install the package:
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35

cd /sources/
rm -rf tar-1.35

# 8.71. Texinfo-7.1
cd /sources/
tar -xvf texinfo-7.1.tar.xz
cd texinfo-7.1

# Prepare Texinfo for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install
# Optionally, install the components belonging in a TeX installation:
make TEXMF=/usr/share/texmf install-tex

# The Info documentation system uses a plain text file to hold its list of menu entries. The file is located at /usr/share/info/dir. Unfortunately, due to occasional problems in the Makefiles of various packages, it can sometimes get out of sync with the info pages installed on the system. If the /usr/share/info/dir file ever needs to be recreated, the following optional commands will accomplish the task:
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd

cd /sources/
rm -rf texinfo-7.1

# 8.72. Vim-9.1.0041
cd /sources/
tar -xvf vim-9.1.0041.tar.gz
cd vim-9.1.0041

# First, change the default location of the vimrc configuration file to /etc:
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
# Prepare Vim for compilation:
./configure --prefix=/usr
# Compile the package:
make
# To prepare the tests, ensure that user tester can write to the source tree:
chown -R tester .
# Now run the tests as user tester:
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
   &> vim-test.log

# Install the package:
make install

# create a symlink for both the binary and the man page in the provided languages:
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

# The following symlink allows the documentation to be accessed via /usr/share/doc/vim-9.1.0041, making it consistent with the location of documentation for other packages:
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0041

# Create a default vim configuration file by running the following:
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# Documentation for other available options can be obtained by running the following command:
vim -c ':options'

cd /sources/
rm -rf vim-9.1.0041

# 8.73. MarkupSafe-2.1.5
cd /sources/
tar -xvf MarkupSafe-2.1.5.tar.gz
cd MarkupSafe-2.1.5

# Compile MarkupSafe with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
# This package does not come with a test suite.
# Install the package:
pip3 install --no-index --no-user --find-links dist Markupsafe

cd /sources/
rm -rf MarkupSafe-2.1.5

# 8.74. Jinja2-3.1.3
cd /sources/
tar -xvf Jinja2-3.1.3.tar.gz
cd Jinja2-3.1.3

# Build the package:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
# Install the package:
pip3 install --no-index --no-user --find-links dist Jinja2

cd /sources/
rm -rf Jinja2-3.1.3

# 8.75. Udev from Systemd-255
cd /sources/
tar -xvf systemd-255.tar.gz
cd systemd-255

# Remove two unneeded groups, render and sgx, from the default udev rules:
sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
# Remove one udev rule requiring a full Systemd installation:
sed '/systemd-sysctl/s/^/#/' -i rules.d/99-systemd.rules.in
# Adjust the hardcoded paths to network configuration files for the standalone udev installation:
sed '/NETWORK_DIRS/s/systemd/udev/' -i src/basic/path-lookup.h
# Prepare Udev for compilation:
mkdir -p build
cd       build
meson setup \
      --prefix=/usr                 \
      --buildtype=release           \
      -Dmode=release                \
      -Ddev-kvm-mode=0660           \
      -Dlink-udev-shared=false      \
      -Dlogind=false                \
      -Dvconsole=false              \
      ..

# Get the list of the shipped udev helpers and save it into an environment variable (exporting it is not strictly necessary, but it makes building as a regular user or using a package manager easier):
export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')
# Only build the components needed for udev:
ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers
# Install the package:
install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network

# Install some custom rules and support files useful in an LFS environment:
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install

# Install the man pages:
tar -xf ../../systemd-man-pages-255.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*

#Finally, unset the udev_helpers variable:
unset udev_helpers

# Information about hardware devices is maintained in the /etc/udev/hwdb.d and /usr/lib/udev/hwdb.d directories. Udev needs that information to be compiled into a binary database /etc/udev/hwdb.bin. Create the initial database:
udev-hwdb update

cd /sources/
rm -rf systemd-255

# 8.76. Man-DB-2.12.0
cd /sources/
tar -xvf man-db-2.12.0.tar.xz
cd man-db-2.12.0

# Prepare Man-DB for compilation:
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.0 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
# Compile the package:
make
# To test the results, issue:
make check
# Install the package:
make install

cd /sources/
rm -rf man-db-2.12.0

# 8.77. Procps-ng-4.0.4
cd /sources/
tar -xvf procps-ng-4.0.4.tar.xz
cd procps-ng-4.0.4

# Prepare Procps-ng for compilation:
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static                        \
            --disable-kill

# Compile the package:
make
# To run the test suite, run:
make -k check
# Install the package:
make install

cd /sources/
rm -rf procps-ng-4.0.4

# 8.78. Util-linux-2.39.3
cd /sources/
tar -xvf util-linux-2.39.3.tar.xz
cd util-linux-2.39.3

# First, disable a problematic test:
sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am

# Prepare Util-linux for compilation:
./configure --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3

# Compile the package:
make
# If desired, run the test suite as a non-root user:
chown -R tester .
su tester -c "make -k check"
# Install the package:
make install

cd /sources/
rm -rf util-linux-2.39.3

# 8.79. E2fsprogs-1.47.0
cd /sources/
tar -xvf e2fsprogs-1.47.0.tar.gz
cd e2fsprogs-1.47.0

# The E2fsprogs documentation recommends that the package be built in a subdirectory of the source tree:
mkdir -v build
cd       build
# Prepare E2fsprogs for compilation:
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
# Compile the package:
make
# To run the tests, issue:
make check
# 374 tests succeeded	1 tests failed
# Tests failed: m_assume_storage_prezeroed 
# Install the package:
make install
# Remove useless static libraries:
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
# This package installs a gzipped .info file but doesn't update the system-wide dir file. Unzip this file and then update the system dir file using the following commands:
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
# If desired, create and install some additional documentation by issuing the following commands:
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

# /etc/mke2fs.conf contains the default value of various command line options of mke2fs. You may edit the file to make the default values suitable for your need. For example, some utilities (not in LFS or BLFS) cannot recognize a ext4 file system with metadata_csum_seed feature enabled. If you need such an utility, you may remove the feature from the default ext4 feature list with the command:
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

cd /sources/
rm -rf e2fsprogs-1.47.0

# 8.80. Sysklogd-1.5.1
cd /sources/
tar -xvf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1

# First, fix a problem that causes a segmentation fault in klogd under some conditions, and fix an obsolete program construct:
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
# Compile the package:
make
# This package does not come with a test suite.
# Install the package:
make BINDIR=/sbin install

# Create a new /etc/syslog.conf file by running the following:
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

cd /sources/
rm -rf sysklogd-1.5.1

# 8.81. Sysvinit-3.08

cd /sources/
tar -xvf sysvinit-3.08.tar.xz
cd sysvinit-3.08

# First, apply a patch that removes several programs installed by other packages, clarifies a message, and fixes a compiler warning:
patch -Np1 -i ../sysvinit-3.08-consolidated-1.patch
# Compile the package:
make
# This package does not come with a test suite.
# Install the package:
make install

cd /sources/
rm -rf sysvinit-3.08

# 8.83. Stripping
## Skip this

# 8.84. Cleaning Up
# Finally, clean up some extra files left over from running tests:
rm -rf /tmp/*
# There are also several files in the /usr/lib and /usr/libexec directories with a file name extension of .la. These are "libtool archive" files. On a modern Linux system the libtool .la files are only useful for libltdl. No libraries in LFS are expected to be loaded by libltdl, and it's known that some .la files can break BLFS package builds. Remove those files now:
find /usr/lib /usr/libexec -name \*.la -delete
# The compiler built in Chapter 6 and Chapter 7 is still partially installed and not needed anymore. Remove it with:
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
# Finally, remove the temporary 'tester' user account created at the beginning of the previous chapter.
userdel -r tester


# next
cd /sources/
tar -xvf 
cd 

cd /sources/
rm -rf 

# filenames

ls: cannot access '/sources': No such file or directory
acl-2.3.2.tar.xz
attr-2.5.2.tar.gz
autoconf-2.72.tar.xz
automake-1.16.5.tar.xz
bash-5.2.21.tar.gz
bash-5.2.21-upstream_fixes-1.patch
bc-6.7.5.tar.xz
binutils-2.42.tar.xz
bison-3.8.2
bison-3.8.2.tar.xz
bzip2-1.0.8-install_docs-1.patch
bzip2-1.0.8.tar.gz
check-0.15.2.tar.gz
coreutils-9.4-i18n-1.patch
coreutils-9.4.tar.xz
dejagnu-1.6.3.tar.gz
diffutils-3.10.tar.xz
e2fsprogs-1.47.0.tar.gz
elfutils-0.190.tar.bz2
expat-2.6.0.tar.xz
expect5.45.4.tar.gz
file-5.45.tar.gz
findutils-4.9.0.tar.xz
flex-2.6.4.tar.gz
flit_core-3.9.0.tar.gz
gawk-5.3.0.tar.xz
gcc-13.2.0
gcc-13.2.0.tar.xz
gdbm-1.23.tar.gz
gettext-0.22.4.tar.xz
glibc-2.39-fhs-1.patch
glibc-2.39.tar.xz
gmp-6.3.0.tar.xz
gperf-3.1.tar.gz
grep-3.11.tar.xz
groff-1.23.0.tar.gz
grub-2.12.tar.xz
gzip-1.13.tar.xz
iana-etc-20240125.tar.gz
inetutils-2.5.tar.xz
intltool-0.51.0.tar.gz
iproute2-6.7.0.tar.xz
Jinja2-3.1.3.tar.gz
kbd-2.6.4-backspace-1.patch
kbd-2.6.4.tar.xz
kmod-31.tar.xz
less-643.tar.gz
lfs-bootscripts-20230728.tar.xz
libcap-2.69.tar.xz
libffi-3.4.4.tar.gz
libpipeline-1.5.7.tar.gz
libtool-2.4.7.tar.xz
libxcrypt-4.4.36.tar.xz
linux-6.7.4.tar.xz
m4-1.4.19.tar.xz
make-4.4.1.tar.gz
man-db-2.12.0.tar.xz
man-pages-6.06.tar.xz
MarkupSafe-2.1.5.tar.gz
meson-1.3.2.tar.gz
mpc-1.3.1.tar.gz
mpfr-4.2.1.tar.xz
ncurses-6.4-20230520
ncurses-6.4-20230520.tar.xz
ninja-1.11.1.tar.gz
openssl-3.2.1.tar.gz
patch-2.7.6.tar.xz
perl-5.38.2.tar.xz
pkgconf-2.1.1.tar.xz
procps-ng-4.0.4.tar.xz
psmisc-23.6.tar.xz
Python-3.12.2
python-3.12.2-docs-html.tar.bz2
readline-8.2.tar.gz
readline-8.2-upstream_fixes-3.patch
sed-4.9.tar.xz
setuptools-69.1.0.tar.gz
shadow-4.14.5.tar.xz
sysklogd-1.5.1.tar.gz
systemd-255.tar.gz
systemd-man-pages-255.tar.xz
sysvinit-3.08-consolidated-1.patch
sysvinit-3.08.tar.xz
tar-1.35.tar.xz
tcl8.6.13-html.tar.gz
tcl8.6.13-src.tar.gz
texinfo-7.1.tar.xz
tzdata2024a.tar.gz
udev-lfs-20230818.tar.xz
util-linux-2.39.3.tar.xz
vim-9.1.0041.tar.gz
wheel-0.42.0.tar.gz
XML-Parser-2.47.tar.gz
xz-5.4.6.tar.xz
zlib-1.3.1.tar.gz
zstd-1.5.5.tar.gz
