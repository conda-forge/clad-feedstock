#!/bin/bash

set -x

#export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot

# Check if shared object is in place.
test -f $PREFIX/lib/clad${SHLIB_EXT}

# Check installed compiler sanity.
if [[ "$(uname)" == "Linux"* ]]; then
  if [[ "$clangdev" == "8.*" || "$clangdev" == "9.*" ]]; then
    #export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot
    #export CONDA_BUILD_SYSROOT=$PREFIX/$HOST/sysroot
    GCCVERSION=$(basename $(dirname $($GXX -print-libgcc-file-name)))
    export CPLUS_INCLUDE_PATH=$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION:$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION/$HOST:$CONDA_PREFIX/$HOST/sysroot/usr/include:$CPLUS_INCLUDE_PATH
    export C_INCLUDE_PATH=$CONDA_PREFIX/$HOST/usr/include:$C_INCLUDE_PATH
    ln -s $CONDA_PREFIX/lib/gcc/$HOST/$GCCVERSION/crtbegin.o $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/gcc/$HOST/$GCCVERSION/crtbeginS.o $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/gcc/$HOST/$GCCVERSION/crtend.o $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/gcc/$HOST/$GCCVERSION/crtendS.o $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/gcc/$HOST/$GCCVERSION/libgcc.a $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/libgcc_s.so $CONDA_BUILD_SYSROOT/usr/lib/
    ln -s $CONDA_PREFIX/lib/libgcc_s.so.1 $CONDA_BUILD_SYSROOT/usr/lib/

    export CFLAGS="$CFLAGS -isysroot $CONDA_BUILD_SYSROOT"
    export CXXFLAGS="$CXXFLAGS -isysroot $CONDA_BUILD_SYSROOT"
  fi
fi

clang --version
echo "" | clang $CXXFLAGS -fsyntax-only -xc++ - -v
echo "#include <vector>" | clang $CXXFLAGS -fsyntax-only -xc++ - -v

# Check if we can process a simple program.
clang++ $CXXFLAGS -xc++ -I$PREFIX/include -fplugin=$PREFIX/lib/clad${SHLIB_EXT} -osanity test.cpp

# Make sure we do not link anything llvm or clang related

if [[ "$(uname)" == "Linux"* ]]; then
  ldd $PREFIX/lib/clad${SHLIB_EXT}  | grep -i llvm && exit 1
  ldd $PREFIX/lib/clad${SHLIB_EXT}  | grep -i clang && exit 1
fi

if [[ "$(uname)" == "Darwin"* ]]; then
  otool -L $PREFIX/lib/clad${SHLIB_EXT}  | grep -i llvm && exit 1
  otool -L $PREFIX/lib/clad${SHLIB_EXT}  | grep -i clang && exit 1
fi

# Let's make a sanity check for cling first.
if [[ $clangdev == *"cling"* ]]; then
  echo "
#include \"clad/Differentiator/Differentiator.h\"

double sq (double x) { return x*x; }
auto d_sq = clad::differentiate(sq, \"x\");
if (d_sq.execute(1) == 2) printf(\"success\");

" | cling -fplugin=$PREFIX/lib/clad${SHLIB_EXT} | grep "success"

fi

if [[ "$(uname)" == "Linux"* ]]; then
# FIXME: Xeus-Cpp does not support stream redirection, re-enable once we have it.
#  if [[ $clangdev == *"cling"* || $clangdev == "18.*" ]]; then
  if [[ $clangdev == *"cling"* ]]; then
    # Try running a kernel test for xeus-cling and xeus-cpp (in case of 18).
    python $RECIPE_DIR/jupyter_Clad_kernel_test.py
  fi
fi

# Run all tests we ran as part of the build but now with clad installed from a
# package.

LLVM_CONFIG=llvm-config

LLVM_VERSION=$(llvm-config --version)
LLVM_VERSION_MAJOR=${LLVM_VERSION%%.*}
LLVM_BIN_DIR=$(llvm-config --bindir)
LLVM_LIB_DIR=$(llvm-config --libdir)
LLVM_HOST_TARGET=$(llvm-config --host-target)
echo "
## Autogenerated LLVM/clad configuration. Do not edit!
import sys

config.clang_version_major = $LLVM_VERSION_MAJOR
config.llvm_tools_dir = \"$LLVM_BIN_DIR\"
config.llvm_libs_dir = \"$LLVM_LIB_DIR\"
config.llvm_lib_output_intdir = \"$LLVM_LIB_DIR\"
config.clad_obj_root = \"\"
config.target_triple = \"$LLVM_HOST_TARGET\"
config.shlibext = \"${SHLIB_EXT}\"
config.have_enzyme = \"\"

import lit.llvm
lit.llvm.initialize(lit_config, config)

# Let the main config do the real work.
lit_config.load_config(config, \"source/test/lit.cfg\")
" > lit.site.cfg

cat lit.site.cfg

# The unittests are dead now, don't try to discover and run them.
rm -fr source/test/Unit/

ln -s $PREFIX/libexec/llvm/FileCheck $PREFIX/bin/FileCheck

# Find back clang/Differentiator/Differentiator.h. Does not work because lit
# deletes the "possibly dangerous env variables".
# FIXME: We need a patch in clad.
#export CPLUS_INCLUDE_PATH="$PREFIX/include/"

#CLANG="clang" CLADLIB="$PREFIX/lib/clad${SHLIB_EXT}"  \
#lit --debug -sv --param clad_site_config=lit.site.cfg source/test


# Check jupyter
# python $RECIPE_DIR/jupyter_Clad_kernel_test.py  # [clangdev == "9.*" and not win]
