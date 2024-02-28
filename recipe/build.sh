#!/bin/bash

set -x

mkdir build
cd build

if [[ "$(uname)" == "Linux"* ]]; then
  export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot
  GCCVERSION=$(basename $(dirname $($GXX -print-libgcc-file-name)))
  export CPLUS_INCLUDE_PATH=$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION:$CONDA_PREFIX/$HOST/include/c++/$GCCVERSION/$HOST
fi

if [[ "$(uname)" == "Darwin"* ]]; then
  # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
  CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
      $SRC_DIR/source

make -j${CPU_COUNT}
make install

if [[ ${clangdev} == '13.*' ]]; then
    echo "Making xeus-cling based Jupyter kernels"
    mkdir -p $PREFIX/share/jupyter/kernels/
    cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
    sed -i "s#@PREFIX@#$PREFIX#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json
    sed -i "s#@SHLIB_EXT@#$SHLIB_EXT#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json
else
    echo "Not making Jupyter kernels"
fi
