#!/bin/bash

set -x

mkdir build
cd build

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

if [[ "$(uname)" == "Darwin"* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ -n "$GXX" ]]; then
  echo "#include <vector>
  int main() {}" | $GXX $CXXFLAGS -xc++ - -v
fi

# Check clang's sanity.
echo "#include <vector>
int main() {}" | $CONDA_PREFIX/bin/clang $CXXFLAGS -xc++ - -v

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
      -DLLVM_EXTERNAL_LIT=`which lit` \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      $SRC_DIR/source

make -j${CPU_COUNT}


if [[ "$(uname)" == "Linux"* ]]; then
  # The llvm-tools-8 package do not have FileCheck. Clad's test Misc/RunDemos.C
  # fails with clang-9.
  if ! [[ "$clangdev" == "8.*" || "$clangdev" == "9.*" || "$clangdev" == "cling" ]]; then
      # Make FileCheck findable.
      ln -s $BUILD_PREFIX/libexec/llvm/FileCheck $BUILD_PREFIX/bin/FileCheck

      # Some conda builds decide to define the CLANG env variable. This confuses
      # lit as it tries to use compiler defined in that env variable.
      unset CLANG
      make -j${CPU_COUNT} check-clad VERBOSE=1
  fi
fi

make install

echo "Making xeus-cling based Jupyter kernels"
mkdir -p $PREFIX/share/jupyter/kernels/
cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
sed -i "s#@PREFIX@#$PREFIX#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

CLANG_RESOURCE_DIR=$(clang -print-resource-dir)
echo $CLANG_RESOURCE_DIR | grep 17 || exit 1
sed -i "s#@RESOURCE_DIR@#$CLANG_RESOURCE_DIR#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

sed -i "s#@SHLIB_EXT@#$SHLIB_EXT#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

exit 0
