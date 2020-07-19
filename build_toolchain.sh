#!/usr/bin/env bash

root_dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

system_name=Linux
target=x86_64-unknown-linux-musl
musl_version=1.2.0
llvm_version=10.0.0
linux_version=5.7.9

llvm_path=$(brew --prefix llvm)/bin
tmp_dir=/tmp/build_$target
toolchain_dir=$root_dir/$target

export PATH=$(brew --prefix gnu-sed)/libexec/gnubin:$llvm_path:$PATH
export CC=$llvm_path/clang
export CXX=$llvm_path/clang++
export AR=$llvm_path/llvm-ar
export AS=$llvm_path/llvm-as
export LD=$llvm_path/ld.lld
export NM=$llvm_path/llvm-nm
export OBJDUMP=$llvm_path/llvm-objdump
export OBJCOPY=$llvm_path/llvm-objcopy
export RANLIB=$llvm_path/llvm-ranlib
export STRINGS=$llvm_path/llvm-strings
export STRIP=$llvm_path/llvm-strip
export CFLAGS="--target=$target"
export CPPFLAGS="--target=$target"


rm -fr $tmp_dir/*
mkdir -p $tmp_dir/build
mkdir $toolchain_dir


cat > $toolchain_dir/toolchain.cmake << EOF
set(CMAKE_SYSTEM_NAME $system_name)
set(CMAKE_C_COMPILER $CC)
set(CMAKE_CXX_COMPILER $CXX)
set(CMAKE_ASM_COMPILER $CC)
set(CMAKE_AR $AR)
set(CMAKE_RANLIB $RANLIB)
set(CMAKE_OBJCOPY $OBJCOPY)
set(CMAKE_OBJDUMP $OBJDUMP)
set(CMAKE_C_COMPILER_TARGET $target})
set(CMAKE_CXX_COMPILER_TARGET $target)
set(CMAKE_ASM_COMPILER_TARGET $target)
set(CMAKE_SYSROOT \${CMAKE_CURRENT_LIST_DIR})
set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES \${CMAKE_SYSROOT}/include)
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES \${CMAKE_SYSROOT}/include/c++/v1 \${CMAKE_SYSROOT}/include)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS_INIT "-nostdinc -fno-rtti")
set(CMAKE_C_STANDARD_LIBRARIES "-L\${CMAKE_SYSROOT}/lib -l:crt1.o -l:crti.o -l:crtn.o -lc")
set(CMAKE_C_LINK_EXECUTABLE "$LD <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_FLAGS_INIT "\${CMAKE_C_FLAGS_INIT} -stdlib=libc++")
set(CMAKE_CXX_STANDARD_LIBRARIES "-L\${CMAKE_SYSROOT}/lib -l:crt1.o -l:crti.o -l:crtn.o -lc++ -lc++abi -lunwind -lm -lc")
set(CMAKE_CXX_LINK_EXECUTABLE "$LD <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
EOF

sed 's/-lc++//;s/-lc++abi//;s/-lunwind//;s/-lm//;s/-fno-rtti//' $toolchain_dir/toolchain.cmake > $toolchain_dir/toolchain_tmp.cmake


# musl
curl -L --retry 5 http://musl.libc.org/releases/musl-$musl_version.tar.gz | tar xC $tmp_dir || exit 1
cd $tmp_dir/musl-$musl_version || exit 1
./configure --disable-shared --prefix=$toolchain_dir
make -j5 install
rm -fr $tmp_dir/musl-$musl_version &


# linux headers
if [[ "$system_name" == "Linux" ]]; then
    curl -L --retry 5 https://cdn.kernel.org/pub/linux/kernel/v${linux_version:0:1}.x/linux-$linux_version.tar.xz | tar xC $tmp_dir || exit 1
    cd $tmp_dir/linux-$linux_version || exit 1
    mkdir -p $tmp_dir/inc/bits
    cp $toolchain_dir/include/elf.h \
        $toolchain_dir/include/byteswap.h \
        $toolchain_dir/include/features.h \
        $toolchain_dir/include/endian.h \
        $tmp_dir/inc
    touch $tmp_dir/inc/bits/alltypes.h
    make mrproper || exit 1
    make headers_check || exit 1
    make -j5 ARCH=x86_64 HOSTCFLAGS="-I$tmp_dir/inc" INSTALL_HDR_PATH=$toolchain_dir headers_install || exit 1
    rm -fr $tmp_dir/linux-$linux_version $tmp_dir/inc &
fi


llvm_libs='libunwind libcxxabi libcxx'
for llvm_lib in $llvm_libs; do
    curl -L --retry 5 https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvm_version/$llvm_lib-$llvm_version.src.tar.xz | tar xC $tmp_dir || exit 1
    mv $tmp_dir/$llvm_lib-$llvm_version.src $tmp_dir/$llvm_lib || exit 1
done

cd $tmp_dir/build || exit 1
for llvm_lib in $llvm_libs; do
    rm -fr $tmp_dir/build/*
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=$toolchain_dir/toolchain_tmp.cmake \
        -DCMAKE_INSTALL_PREFIX=$toolchain_dir \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DLIBUNWIND_ENABLE_SHARED=OFF \
        -DLIBCXXABI_LIBCXX_INCLUDES=$tmp_dir/libcxx/include \
        -DLIBCXXABI_LIBUNWIND_INCLUDES=$tmp_dir/libunwind/include \
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
        -DLIBCXXABI_ENABLE_SHARED=OFF \
        -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$tmp_dir/libcxxabi/include \
        -DLIBCXX_CXX_ABI_LIBRARY_PATH=$toolchain_dir/lib \
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
rm -fr $toolchain_dir/toolchain_tmp.cmake $tmp_dir
