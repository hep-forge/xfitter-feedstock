#! /usr/bin/bash

mkdir build
cd build

# ${CMAKE_ARGS} carries conda-build's toolchain/sysroot settings (compiler
# paths, CMAKE_FIND_ROOT_PATH, etc.); without it CMake falls back to its
# own default compiler detection, bypassing the pinned old-glibc sysroot
# and leaking newer host GLIBC symbol versions into the built libraries.
# macOS: CMakeLists.txt adds -lrt to CMAKE_CXX_FLAGS. librt is Linux's;
# macOS has those functions in libSystem and no librt to link.
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i.bak 's/ -pthread -lrt")/ -pthread")/' ../CMakeLists.txt
  rm -f ../CMakeLists.txt.bak
  if grep -q -- '-pthread -lrt' ../CMakeLists.txt; then echo "-lrt not removed" >&2; exit 1; fi
  # The Fortran parts (libff.a and others) are linked by the C++ driver,
  # which does not add gfortran's runtime on macOS (undefined
  # __gfortran_* symbols): name it. libgfortran.dylib is in $PREFIX/lib.
  export LDFLAGS="${LDFLAGS} -lgfortran"
fi
cmake ${CMAKE_ARGS} .. -DCMAKE_INSTALL_PREFIX=$PREFIX

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make -j$NPROC
make install

rsync -razu ../include $PREFIX
