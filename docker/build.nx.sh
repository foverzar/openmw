#!/usr/bin/env bash
set -xe

# Creating build directory...
mkdir -p build
cd build

source $DEVKITPRO/switchvars.sh
# Running CMake..
cmake \
    -G"Unix Makefiles" \
    -DSWITCH_LIBNX=ON \
    -DCMAKE_CXX_FLAGS="-v -fpermissive -include cstdint -include limits" \
    -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPKG_CONFIG_EXECUTABLE="$PORTLIBS_PREFIX/bin/aarch64-none-elf-pkg-config" \
    -DCMAKE_INSTALL_PREFIX="$PORTLIBS_PREFIX" \
    -DMyGUI_LIBRARY="$PORTLIBS_PREFIX/lib/libMyGUIEngineStatic.a" \
    -DBUILD_BSATOOL=OFF \
    -DBUILD_NIFTEST=OFF \
    -DBUILD_ESMTOOL=OFF \
    -DBUILD_LAUNCHER=OFF \
    -DBUILD_MWINIIMPORTER=OFF \
    -DBUILD_ESSIMPORTER=OFF \
    -DBUILD_OPENCS=OFF \
    -DBUILD_WIZARD=OFF \
    -DBUILD_MYGUI_PLUGIN=OFF \
    -DOSG_STATIC=TRUE \
    ..

# Building with $NPROC CPU...
make -j $NPROC