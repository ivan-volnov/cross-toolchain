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

llvm_libs='compiler-rt libcxx libcxxabi libunwind'
for llvm_lib in $llvm_libs; do
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvm_version/$llvm_lib-$llvm_version.src.tar.xz || exit 1
    tar xf $llvm_lib-$llvm_version.src.tar.xz || exit 1
    rm $llvm_lib-$llvm_version.src.tar.xz || exit 1
    mv $llvm_lib-$llvm_version.src $llvm_lib
done
cp -a compiler-rt compiler-rt-builtins

cd compiler-rt-builtins
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=$target \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_CRT=OFF \
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
    -DCMAKE_INSTALL_PREFIX=$root_dir \
    -DCMAKE_BUILD_TYPE=Release \
    . || exit 1
make install -j8
cd ..

cd libunwind
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DLIBUNWIND_ENABLE_SHARED=OFF \
    -DCMAKE_INSTALL_PREFIX=$root_dir \
    -DCMAKE_BUILD_TYPE=Release \
    . || exit 1
make install -j8
cd ..

# cmake \
#     -DCMAKE_TOOLCHAIN_FILE=$root_dir/toolchain.cmake \
#     -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
#     -DCMAKE_VERBOSE_MAKEFILE=ON \
#     -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=$target \
#     -DCOMPILER_RT_BUILD_BUILTINS=ON \
#     -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
#     -DCOMPILER_RT_BUILD_XRAY=OFF \
#     -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
#     -DCOMPILER_RT_BUILD_CRT=OFF \
#     -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
#     -DLIBCXXABI_LIBCXX_PATH=$root_dir/tmp/libcxx-$llvm_version.src \
#     -DLIBCXXABI_LIBCXX_INCLUDES=$root_dir/tmp/libcxx-$llvm_version.src/include \
#     -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
#     -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
#     -DLIBCXX_LIBCXXABI_INCLUDES_INTERNAL=$root_dir/tmp/libcxxabi-$llvm_version.src/include \
#     -DLIBCXX_HAS_MUSL_LIBC=ON \
#     -DLIBCXX_HAS_GCC_S_LIB=OFF \
#     -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
#     -DLIBUNWIND_ENABLE_SHARED=OFF \
#     -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
#     -DCLANG_DEFAULT_LINKER=lld \
#     -DCLANG_DEFAULT_RTLIB=compiler-rt \
#     -DCMAKE_INSTALL_PREFIX=$root_dir \
#     -DCMAKE_BUILD_TYPE=Release \
#     . || exit 1

# cd ..
# rm -fr $root_dir/tmp
