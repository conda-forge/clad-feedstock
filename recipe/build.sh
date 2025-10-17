#!/bin/bash

set -x

mkdir build
cd build

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

# FIXME: Although Clad is built as a shared library on Linux arm,
# the tests do not find the .so in the location it expects
if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCLAD_DISABLE_TESTS=ON"
fi

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
      -DLLVM_EXTERNAL_LIT=`which lit` \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      $SRC_DIR/source
    
make -j${CPU_COUNT}


if [[ "$(uname)" == "Linux"* ]]; then
  # The llvm-tools-8 package do not have FileCheck. Clad's test Misc/RunDemos.C
  # fails with clang-9.
  # Make FileCheck findable.
  ln -s $BUILD_PREFIX/libexec/llvm/FileCheck $BUILD_PREFIX/bin/FileCheck

  # Some conda builds decide to define the CLANG env variable. This confuses
  # lit as it tries to use compiler defined in that env variable.
  unset CLANG
  # FIXME: Although Clad is built as a shared library on Linux arm,
  # the tests do not find the .so in the location it expects
  if [[ "$target_platform" == "linux-64" ]]; then
    make -j${CPU_COUNT} check-clad VERBOSE=1
  fi
fi

make install

if [[ "$clangdev" == "20.*" ]]; then
  echo "Making xeus-cpp based Jupyter kernels"
  mkdir -p $PREFIX/share/jupyter/kernels/
  cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
  sed -i "s#@PREFIX@#$PREFIX#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

  CLANG_RESOURCE_DIR=$(clang -print-resource-dir)
  # Replace the PREFIX part so that when conda install the package updates the path
  CLANG_RESOURCE_DIR=$(echo $CLANG_RESOURCE_DIR | sed "s#$BUILD_PREFIX##g")
  sed -i "s#@RESOURCE_DIR@#$PREFIX/$CLANG_RESOURCE_DIR#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

  sed -i "s#@SHLIB_EXT@#$SHLIB_EXT#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

  CLAD_VERSION="v$PKG_VERSION"
  sed -i "s#@CLAD_VERSION@#$CLAD_VERSION#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json

  cat $PREFIX/share/jupyter/kernels/*-Clad/*.json
fi

exit 0
