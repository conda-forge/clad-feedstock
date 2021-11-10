#!/bin/bash

mkdir build
cd build

cmake ${CMAKE_ARGS} \
      $SRC_DIR/source

make -j${CPU_COUNT}
make install

if [[ ${clangdev} == '5.*' ]]; then
    echo "Making xeus-cling based Jupyter kernels"
    mkdir -p $PREFIX/share/jupyter/kernels/
    cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
else
    echo "Not making Jupyter kernels"
fi
