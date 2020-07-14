set(CMAKE_SYSTEM_NAME Linux)
set(target x86_64-unknown-linux-musl)

set(CMAKE_C_COMPILER    "/usr/local/opt/llvm/bin/clang")
set(CMAKE_CXX_COMPILER  "/usr/local/opt/llvm/bin/clang++")
set(CMAKE_AR            "/usr/local/bin/x86_64-elf-ar")
set(CMAKE_OBJCOPY       "/usr/local/bin/x86_64-elf-objcopy")

set(CMAKE_C_COMPILER_TARGET ${target})
set(CMAKE_CXX_COMPILER_TARGET ${target})
set(CMAKE_SYSROOT ${CMAKE_CURRENT_LIST_DIR})
include_directories(SYSTEM ${CMAKE_SYSROOT}/include)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS "-nostdinc -nostdlib -v")
set(CMAKE_C_LINK_FLAGS "-static -l:crt1.o -l:crti.o -l:crtn.o -lc -v")
set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld")
