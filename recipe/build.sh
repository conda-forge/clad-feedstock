#!/bin/bash

mkdir build
cd build

cmake ${CMAKE_ARGS} \
      $SRC_DIR/source

make -j${CPU_COUNT}
make install

if [[ ${clangdev} == '5.*' ]]; then
    echo "Making xeus-cling based Jupyter kernels"
    mkdir -p $<span class="x x-first x-last">PREFIX</span>/share/jupyter/kernels/
    cp -r $RECIPE_DIR/kernels/* $<span class="x x-first x-last">PREFIX</span>/share/jupyter/kernels/
else
    echo "Not making Jupyter kernels"
fi
