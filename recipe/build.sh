#!/bin/bash

set -x

mkdir build
cd build

if [[ "$(uname)" == "Linux"* ]]; then
  export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot
fi

export

export CPLUS_INCLUDE_PATH=$CONDA_PREFIX/$HOST/include/c++/12.3.0:$CONDA_PREFIX/$HOST/include/c++/12.3.0/$HOST

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
      -DCMAKE_CXX_STANDARD=14 \
      $SRC_DIR/source

make VERBOSE=1
#make -j${CPU_COUNT}
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
