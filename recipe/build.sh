#!/bin/bash

set -x

mkdir build
cd build

#if [[ "$(uname)" == "Linux"* ]]; then
#  if [[ "$llvmdev" == "7.*" || "$llvmdev" == "8.*" || "$llvmdev" == "9.*" ]]; then
#    #export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot
#    #export CONDA_BUILD_SYSROOT=$PREFIX/$HOST/sysroot
#    GCCVERSION=$(basename $(dirname $($GXX -print-libgcc-file-name)))
#    export CPLUS_INCLUDE_PATH=$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION:$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION/$HOST
#    export C_INCLUDE_PATH=$CONDA_PREFIX/$HOST/usr/include/
#    CXXFLAGS="${CXXFLAGS} -B $BUILD_PREFIX/bin/x86_64-conda-linux-gnu- -shared-libgcc"
#  fi
#fi

if [[ "$(uname)" == "Darwin"* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ -n "$GXX" ]]; then
  echo "#include <vector>
  int main() {}" | $GXX -xc++ - -v
fi

# Check clang's sanity.
echo "#include <vector>
int main() {}" | clang $CXXFLAGS -xc++ - -v

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
      -DLLVM_EXTERNAL_LIT=`which lit` \
      $SRC_DIR/source

make -j${CPU_COUNT}
# Make FileCheck findable.
ln -s $BUILD_PREFIX/libexec/llvm/FileCheck $BUILD_PREFIX/bin/FileCheck

# Some conda builds decide to define the CLANG env variable. This confuses lit
# as it tries to use compiler defined in that env variable.
unset CLANG
make -j${CPU_COUNT} check-clad VERBOSE=1
make install

echo "Making xeus-cling based Jupyter kernels"
mkdir -p $PREFIX/share/jupyter/kernels/
cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
sed -i "s#@PREFIX@#$PREFIX#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json
sed -i "s#@SHLIB_EXT@#$SHLIB_EXT#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

exit 0
