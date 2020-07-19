# Cross-Compilation Toolchain

Cross-Compilation toolchain using llvm/clang, cmake, musl and libc++ for macOS host

## Technology Stack

- llvm/clang
- cmake
- musl
- libc++
- libcxxabi
- libunwind
- linux kernel headers

## Toolchain Features

- x86_64-unknown-linux-musl target is by default but you can set any
- statically linked
- minimal release build
  - helloworld C takes only 9.5Kb
  - helloworld C++ takes only 756Kb
- -fno-rtti by default

## Install Dependencies

```bash
brew install llvm gnu-sed
```

## Build the Toolchain

```bash
./build.sh
```

## Test it

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.5)
project(helloworld LANGUAGES C)
add_executable(helloworld main.c)
```

### main.c

```c
#include <stdio.h>

int main()
{
    printf("Hello World!\n");
    return 0;
}
```

### Make

```bash
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=/PATH_TO/toolchain.cmake ..
make
```

## Qt Creator CMake configuration

```qtcreator
CMAKE_MAKE_PROGRAM:INTERNAL=/usr/local/bin/ninja
CMAKE_TOOLCHAIN_FILE:INTERNAL=/PATH_TO/toolchain.cmake
```
