#!/bin/bash

mkdir build
cd build

cmake ${CMAKE_ARGS} \
      $SRC_DIR/source

make -j${CPU_COUNT}
make install

if [[ ${clangdev} == '5.*' ]]; then
    echo "Making xeus-cling based jupyter kernels"
else
    echo "Not making jupyter kernels"
fi
