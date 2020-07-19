#!/usr/bin/env bash

root_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

target=x86_64-unknown-linux-musl
musl_version=1.2.0
llvm_version=10.0.0
linux_version=5.7.9

export PATH=$(brew --prefix gnu-sed)/libexec/gnubin:$(brew --prefix llvm)/bin:$PATH
export CC=clang
export CXX=clang++
export CFLAGS="--target=$target"
export CPPFLAGS="--target=$target"
export AR=llvm-ar
export AS=llvm-as
export LD=ld.lld
export NM=llvm-nm
export OBDUMP=llvm-objdump
export OBJCOPY=llvm-objcopy
export RANLIB=llvm-ranlib
export STRINGS=llvm-strings
export STRIP=llvm-strip


rm -fr $root_dir/tmp/*
mkdir -p $root_dir/tmp/build

# musl
curl -L --retry 5 http://musl.libc.org/releases/musl-$musl_version.tar.gz | tar xC $root_dir/tmp || exit 1
cd $root_dir/tmp/musl-$musl_version || exit 1
./configure --disable-shared --prefix=$root_dir
make -j5 install
rm -fr $root_dir/tmp/musl-$musl_version &

# linux headers
curl -L --retry 5 https://cdn.kernel.org/pub/linux/kernel/v${linux_version:0:1}.x/linux-$linux_version.tar.xz | tar xC $root_dir/tmp || exit 1
cd $root_dir/tmp/linux-$linux_version || exit 1
mkdir -p $root_dir/tmp/inc/bits
cp $root_dir/include/elf.h \
   $root_dir/include/byteswap.h \
   $root_dir/include/features.h \
   $root_dir/include/endian.h \
   $root_dir/tmp/inc
touch $root_dir/tmp/inc/bits/alltypes.h
make mrproper || exit 1
make headers_check || exit 1
make -j5 ARCH=x86_64 HOSTCFLAGS="-I$root_dir/tmp/inc" INSTALL_HDR_PATH=$root_dir headers_install || exit 1
rm -fr $root_dir/tmp/linux-$linux_version &

llvm_libs='libunwind libcxxabi libcxx'
for llvm_lib in $llvm_libs; do
    curl -L --retry 5 https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvm_version/$llvm_lib-$llvm_version.src.tar.xz | tar xC $root_dir/tmp || exit 1
    mv $root_dir/tmp/$llvm_lib-$llvm_version.src $root_dir/tmp/$llvm_lib || exit 1
done

sed 's/-lc++//;s/-lc++abi//;s/-lunwind//;s/-lm//;s/-fno-rtti//' $root_dir/toolchain.cmake > $root_dir/toolchain_tmp.cmake

cd $root_dir/tmp/build || exit 1
for llvm_lib in $llvm_libs; do
    rm -fr $root_dir/tmp/build/*
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain_tmp.cmake \
        -DCMAKE_INSTALL_PREFIX=$root_dir \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DLIBUNWIND_ENABLE_SHARED=OFF \
        -DLIBCXXABI_LIBCXX_INCLUDES=$root_dir/tmp/libcxx/include \
        -DLIBCXXABI_LIBUNWIND_INCLUDES=$root_dir/tmp/libunwind/include \
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
        -DLIBCXXABI_ENABLE_SHARED=OFF \
        -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$root_dir/tmp/libcxxabi/include \
        -DLIBCXX_CXX_ABI_LIBRARY_PATH=$root_dir/lib \
        -DLIBCXX_CXX_ABI=libcxxabi \
        -DLIBCXX_HAS_MUSL_LIBC=ON \
        -DLIBCXX_HAS_GCC_S_LIB=OFF \
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
        -DLIBCXX_ENABLE_SHARED=OFF \
        -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
        -DLIBCXX_INCLUDE_DOCS=OFF \
        -DLIBCXX_ENABLE_RTTI=OFF \
        ../$llvm_lib || exit 1
    make -j5 install || exit 1
done

cd $root_dir
rm -fr $root_dir/toolchain_tmp.cmake $root_dir/tmp
