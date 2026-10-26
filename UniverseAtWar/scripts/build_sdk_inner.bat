@echo on
set ROOT=%~dp0..\
set PATH=C:\Program Files\LLVM\bin;C:\Program Files\CMake\bin;C:\Program Files\Git\cmd;%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%
set "VSDIR=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
call "%VSDIR%\VC\Auxiliary\Build\vcvarsarm64.bat"
set "PATH=C:\Program Files\LLVM\bin;%PATH%"
where clang
where cmake
where ninja
where git
clang --version
cmake --version
git config --global core.longpaths true
cd /d "%ROOT%"
if exist "rexglue-sdk\CMakeLists.txt" goto :configure
REM The SDK patches are written for this exact commit ("Release v0.10.0" on main).
git clone --no-checkout https://github.com/rexglue/rexglue-sdk.git rexglue-sdk
if errorlevel 1 goto :fail
git -C rexglue-sdk checkout c94f5ebdcb3c9d1a460ca48e04f9758448f8d518
if errorlevel 1 goto :fail
git -C rexglue-sdk submodule update --init --recursive
if errorlevel 1 goto :fail
:configure
cd /d "%ROOT%rexglue-sdk"
call "%ROOT%scripts\apply_sdk_patches.bat"
if errorlevel 1 goto :fail
REM Windows checks out git symlinks as text files (e.g. libmspack\cabextract\mspack\lzxd.c): replace them with real copies.
set "PYEXE="
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do if exist "%%D\python.exe" set "PYEXE=%%D\python.exe"
if "%PYEXE%"=="" (echo ==== PYTHON MISSING & goto :fail)
"%PYEXE%" "%ROOT%scripts\fix_git_symlinks.py" "%ROOT%rexglue-sdk"
if errorlevel 1 goto :fail
cmake --preset win-arm64 -DREXGLUE_ENABLE_TRACY=OFF
if errorlevel 1 goto :fail
cmake --build out/build/win-arm64 --config Release --target install -j 6
if errorlevel 1 goto :fail
echo ==== SUCCESS
exit /b 0
:fail
echo ==== FAILED
exit /b 1
