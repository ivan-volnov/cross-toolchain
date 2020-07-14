# cmake cross toolchain

A description

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
