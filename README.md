# Cross-compilation toolchain

Cross-compilation toolchain using clang, cmake, musl and libc++

## Installation

Preparation:

```bash
brew install llvm x86_64-elf-binutils
```

Qt Creator CMake configuratuion:

```qtcreator
CMAKE_MAKE_PROGRAM:INTERNAL=/usr/local/bin/ninja
CMAKE_TOOLCHAIN_FILE:INTERNAL=/PATH_TO/toolchain.cmake
```
