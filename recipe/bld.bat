mkdir build
cd build

cmake -G "Ninja" ^
      -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
      -DCMAKE_BUILD_TYPE=Release ^
      %SRC_DIR%/source

echo CMakeFiles\CMakeOutput.log
type CMakeFiles\CMakeOutput.log

echo CMakeFiles\CMakeError.log
type CMakeFiles\CMakeError.log

if errorlevel 1 exit 1

ninja -j%CPU_COUNT%
if errorlevel 1 exit 1

ninja install
if errorlevel 1 exit 1
