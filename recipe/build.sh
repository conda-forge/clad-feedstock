#!/bin/bash

mkdir build
cd build

export CONDA_BUILD_SYSROOT=$CONDA_PREFIX/$HOST/sysroot
#echo "#include <vector>" | clang++ --gcc-toolchain=$CONDA_PREFIX -xc++ - -v

cmake ${CMAKE_ARGS} \
      -DCMAKE_SYSROOT=$CONDA_BUILD_SYSROOT \
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
