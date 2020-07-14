#!/usr/bin/env bash

root_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

target=x86_64-unknown-linux-musl
musl_version=1.2.0
llvm_version=10.0.0

export PATH=$root_dir/bin:/usr/local/opt/llvm/bin:$PATH
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




mkdir $root_dir/tmp
# rm -fr $root_dir/tmp/*
cd $root_dir/tmp

# llvm_libs='compiler-rt libcxx libcxxabi libunwind'
# for llvm_lib in $llvm_libs; do
#     wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvm_version/$llvm_lib-$llvm_version.src.tar.xz || exit 1
#     tar xf $llvm_lib-$llvm_version.src.tar.xz || exit 1
#     rm $llvm_lib-$llvm_version.src.tar.xz || exit 1
# done


# cmake \
#     -DLIBCXXABI_LIBCXX_PATH=$ROOT/src/libcxx \
#     -DLIBCXXABI_LIBCXX_INCLUDES=$ROOT/src/libcxx/include \
#     -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
#     -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
#     -DLIBCXX_LIBCXXABI_INCLUDES_INTERNAL=$ROOT/src/libcxxabi/include \
#     -DLIBCXX_HAS_MUSL_LIBC=ON \
#     -DLIBCXX_HAS_GCC_S_LIB=OFF \
#     -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
#     -DLIBUNWIND_ENABLE_SHARED=OFF \
#     -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
#     -DCLANG_DEFAULT_LINKER=lld \
#     -DCLANG_DEFAULT_RTLIB=compiler-rt \
#     -DLLVM_DEFAULT_TARGET_TRIPLE="$ARCH"-pc-linux-musl \
#     -DDEFAULT_SYSROOT=/"$ARCH"-pc-linux-musl \
#     -DCMAKE_INSTALL_PREFIX=/"$ARCH"-pc-linux-musl \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DLLVM_TARGET_ARCH="$ARCH" \
#     -DLLVM_TARGETS_TO_BUILD="$TARGETS" \
#     -G Ninja \
#     $ROOT/src/llvm || exit 40
#
# cmake -G Ninja
# ninja

# musl
wget http://musl.libc.org/releases/musl-$musl_version.tar.gz || exit 1
tar xfz musl-$musl_version.tar.gz || exit 1
cd musl-$musl_version
./configure --disable-shared --enable-debug --prefix=$root_dir
make -j5 install


cd ..
rm -fr $root_dir/tmp
