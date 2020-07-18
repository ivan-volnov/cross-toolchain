#!/usr/bin/env bash

root_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

target=x86_64-unknown-linux-musl
musl_version=1.2.0
llvm_version=10.0.0

export PATH=$root_dir/bin:$(brew --prefix llvm)/bin:$PATH
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




mkdir -p $root_dir/tmp
# rm -fr $root_dir/tmp/*
cd $root_dir/tmp

# musl
wget http://musl.libc.org/releases/musl-$musl_version.tar.gz || exit 1
tar xfz musl-$musl_version.tar.gz || exit 1
cd musl-$musl_version
./configure --disable-shared --enable-debug --prefix=$root_dir
make -j5 install
cd ..

llvm_libs='libcxx libcxxabi libunwind'
for llvm_lib in $llvm_libs; do
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvm_version/$llvm_lib-$llvm_version.src.tar.xz || exit 1
    tar xf $llvm_lib-$llvm_version.src.tar.xz || exit 1
    rm $llvm_lib-$llvm_version.src.tar.xz || exit 1
    mv $llvm_lib-$llvm_version.src $llvm_lib
done
mkdir build
cd build


rm -fr $root_dir/tmp/build/*
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DLIBUNWIND_ENABLE_SHARED=OFF \
    -DCMAKE_INSTALL_PREFIX=$root_dir \
    -DCMAKE_BUILD_TYPE=Release \
    ../libunwind || exit 1
make install -j5 || exit 1

rm -fr $root_dir/tmp/build/*
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DLIBCXXABI_LIBCXX_INCLUDES=$root_dir/tmp/libcxx/include \
    -DLIBCXXABI_LIBUNWIND_INCLUDES=$root_dir/tmp/libunwind/include \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLIBCXXABI_ENABLE_SHARED=OFF \
    -DCMAKE_INSTALL_PREFIX=$root_dir \
    -DCMAKE_BUILD_TYPE=Release \
    ../libcxxabi || exit 1
make install -j5 || exit 1


rm -fr $root_dir/tmp/build/*
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DLIBCXX_LIBCXXABI_INCLUDES_INTERNAL=$root_dir/tmp/libcxxabi/include \
    -DLIBCXX_HAS_MUSL_LIBC=ON \
    -DLIBCXX_HAS_GCC_S_LIB=OFF \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DLIBCXX_ENABLE_SHARED=OFF \
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
    -DLIBCXX_INCLUDE_DOCS=OFF \
    -DLIBCXX_ENABLE_RTTI=OFF \
    -DCMAKE_INSTALL_PREFIX=$root_dir \
    -DCMAKE_BUILD_TYPE=Release \
    ../libcxx || exit 1
make install -j5 || exit 1


# cd ..
# rm -fr $root_dir/tmp
