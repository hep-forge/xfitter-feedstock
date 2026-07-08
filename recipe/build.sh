#! /usr/bin/bash

mkdir build
cd build

# ${CMAKE_ARGS} carries conda-build's toolchain/sysroot settings (compiler
# paths, CMAKE_FIND_ROOT_PATH, etc.); without it CMake falls back to its
# own default compiler detection, bypassing the pinned old-glibc sysroot
# and leaking newer host GLIBC symbol versions into the built libraries.
cmake ${CMAKE_ARGS} .. -DCMAKE_INSTALL_PREFIX=$PREFIX

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make -j$NPROC
make install

rsync -razu ../include $PREFIX
