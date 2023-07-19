#!/bin/bash

mkdir build
cd build

cmake ${CMAKE_ARGS} \
      $SRC_DIR/source

make -j${CPU_COUNT}
make install

#there is no support for 5. anymore, uncomment this when xeus-cling will work with 9.

# if [[ ${clangdev} == '5.*' ]]; then
#     echo "Making xeus-cling based Jupyter kernels"
#     mkdir -p $PREFIX/share/jupyter/kernels/
#     cp -r $RECIPE_DIR/kernels/* $PREFIX/share/jupyter/kernels/
#     sed -i "s#@PREFIX@#$PREFIX#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json
#     sed -i "s#@SHLIB_EXT@#$SHLIB_EXT#g" $PREFIX/share/jupyter/kernels/*-Clad/*.json
# else
#     echo "Not making Jupyter kernels"
# fi
