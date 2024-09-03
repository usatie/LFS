mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

mkdir $LFS/setup && cd $LFS/setup
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv
wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources

# Verify integrity
cd $LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
pushd $LFS/sources
  md5sum -c md5sums
popd

# Download missing one
wget https://lfs.gnlug.org/pub/lfs/lfs-packages/12.1/expat-2.6.0.tar.xz --directory-prefix=$LFS/sources

# Verify integrity
pushd $LFS/sources
  md5sum -c md5sums
popd

# Make sure the files are owned by root
chown root:root $LFS/sources/*
