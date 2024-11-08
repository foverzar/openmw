#!/bin/bash
set -xe

dkp-pacman -R
apt update && apt install -y build-essential
source $DEVKITPRO/switchvars.sh

OPENMW_SOURCE_DIR=$1

### Dependencies

## OpenSceneGraph
git clone -b 3.6 https://github.com/foverzar/OpenSceneGraph.git
cd OpenSceneGraph
mkdir switchbuild && cd switchbuild
cmake \
-G"Unix Makefiles" \
-DSWITCH_LIBNX=ON \
-DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" \
-DCMAKE_BUILD_TYPE=Release \
-DPKG_CONFIG_EXECUTABLE="$DEVKITPRO/portlibs/switch/bin/aarch64-none-elf-pkg-config" \
-DCMAKE_INSTALL_PREFIX="$DEVKITPRO/portlibs/switch" \
-DOPENGL_PROFILE="GL2" \
-DDYNAMIC_OPENTHREADS=OFF \
-DDYNAMIC_OPENSCENEGRAPH=OFF \
-DBUILD_OSG_PLUGIN_OSG=ON \
-DBUILD_OSG_PLUGIN_DDS=ON \
-DBUILD_OSG_PLUGIN_TGA=ON \
-DBUILD_OSG_PLUGIN_BMP=ON \
-DBUILD_OSG_PLUGIN_JPEG=ON \
-DBUILD_OSG_PLUGIN_PNG=ON \
-DBUILD_OSG_PLUGIN_FREETYPE=ON \
-DOSG_CPP_EXCEPTIONS_AVAILABLE=TRUE \
-DOSG_GL1_AVAILABLE=ON \
-DOSG_GL2_AVAILABLE=ON \
-DOSG_GL3_AVAILABLE=OFF \
-DOSG_GLES1_AVAILABLE=OFF \
-DOSG_GLES2_AVAILABLE=OFF \
-DOSG_GL_LIBRARY_STATIC=ON \
-DBUILD_OSG_APPLICATIONS=OFF \
-DBUILD_OSG_PLUGINS_BY_DEFAULT=OFF \
-DBUILD_OSG_DEPRECATED_SERIALIZERS=OFF \
-D_OPENTHREADS_ATOMIC_USE_GCC_BUILTINS=ON \
..

make -j `nproc`
make install

cd ../..

## MyGUI

git clone -b nx https://github.com/foverzar/mygui
cd mygui
mkdir switchbuild && cd switchbuild
cmake \
-G"Unix Makefiles" \
-DSWITCH_LIBNX=ON \
-DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" \
-DCMAKE_BUILD_TYPE=Release \
-DPKG_CONFIG_EXECUTABLE="$DEVKITPRO/portlibs/switch/bin/aarch64-none-elf-pkg-config" \
-DCMAKE_INSTALL_PREFIX="$DEVKITPRO/portlibs/switch" \
-DMYGUI_RENDERSYSTEM=ON \
-DMYGUI_BUILD_DEMOS=OFF \
-DMYGUI_BUILD_TOOLS=OFF \
-DMYGUI_BUILD_PLUGINS=OFF \
-DMYGUI_STATIC=ON \
-DCMAKE_CXX_STANDARD=14 \
..

make -j `nproc`
make install

cd ../..

## Boost

git clone -b boost-1.69.0 https://github.com/boostorg/boost
cd boost

# Replace with patched iostreams and filesystem
git rm libs/iostreams
git submodule add https://github.com/foverzar/boost-iostreams.git libs/iostreams
git rm libs/filesystem
git submodule add https://github.com/foverzar/boost-filesystem.git libs/filesystem

git submodule update --init

cd libs/iostreams
git checkout boost-1.69.0-nx
cd -

cd libs/filesystem
git checkout boost-1.69.0-nx
cd -

./bootstrap.sh --prefix="$PORTLIBS_PREFIX"

cat > project-config.jam << HEREDOC
# Boost.Build Configuration
# Automatically generated by bootstrap.sh

import option ;
import feature ;

# Compiler configuration. This definition will be used unless
# you already have defined some toolsets in your user-config.jam
# file.
if ! gcc in [ feature.values <toolset> ]
{
    using gcc : arm : aarch64-none-elf-g++ ;
}

using zlib : 1.2.11 : <search>/opt/devkitpro/portlibs/switch/lib <name>libz <include>/opt/devkitpro/portlibs/switch/include ;
using bzip2 : 1.0.6 : <search>/opt/devkitpro/portlibs/switch/lib <name>libbz2 <include>/opt/devkitpro/portlibs/switch/include ;

project : default-build <toolset>gcc ;

# Python configuration
import python ;
if ! [ python.configured ]
{
    using python : 3.7 : /usr ;
}

# List of --with-<library> and --without-<library>
# options. If left empty, all libraries will be built.
# Options specified on the command line completely
# override this variable.
libraries =  ;

# These settings are equivivalent to corresponding command-line
# options.
option.set prefix : /usr/local ;
option.set exec-prefix : /usr/local ;
option.set libdir : /usr/local/lib ;
option.set includedir : /usr/local/include ;

# Stop on first error
option.set keep-going : false ;
HEREDOC

./b2 \
  --with-filesystem --with-system --with-program_options --with-iostreams \
  --prefix="$PORTLIBS_PREFIX" \
  architecture=arm address-model=64 \
  toolset=gcc-arm \
  threading=multi threadapi=pthread \
  link=static runtime-link=static \
  cxxflags="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE -ftls-model=local-exec -ffunction-sections -fdata-sections -D__SWITCH__" \
  cflags="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIE -ftls-model=local-exec -ffunction-sections -fdata-sections -D__SWITCH__" \
  variant=release \
  target-os=bsd \
  -sNO_BZIP2=0 \
  -sNO_ZLIB=0 \
  -sNO_COMPRESSION=0 \
  --reconfigure install

cd ..

## OpenAL

git clone https://github.com/fgsfdsfgs/openal-soft
cd openal-soft
make -f Makefile.nx
make -f Makefile.nx install

### Build OpenMW

#-I/opt/devkitpro/portlibs/switch/include/AL -lopenal
mkdir openmwswitchbuild && cd openmwswitchbuild
cmake \
-G"Unix Makefiles" \
-DSWITCH_LIBNX=ON \
-DCMAKE_CXX_FLAGS="-fpermissive -include /opt/devkitpro/devkitA64/aarch64-none-elf/include/c++/14.2.0/cstdint -include /opt/devkitpro/devkitA64/aarch64-none-elf/include/c++/14.2.0/limits -L/opt/devkitpro/portlibs/switch/lib -ldav1d" \
-DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/Switch.cmake" \
-DCMAKE_BUILD_TYPE=Release \
-DPKG_CONFIG_EXECUTABLE="$DEVKITPRO/portlibs/switch/bin/aarch64-none-elf-pkg-config" \
-DCMAKE_INSTALL_PREFIX="$DEVKITPRO/portlibs/switch" \
-DMyGUI_LIBRARY="$DEVKITPRO/portlibs/switch/lib/libMyGUIEngineStatic.a" \
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
$OPENMW_SOURCE_DIR