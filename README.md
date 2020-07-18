# Cross-Compilation toolchain

Cross-Compilation toolchain using llvm/clang, cmake, musl and libc++

Work in progress. Currently only C compiler is supported
with x86_64-unknown-linux-musl target

## LLVM installation

```bash
brew install llvm gnu-sed
```

## Build the toolchain

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

### make

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
