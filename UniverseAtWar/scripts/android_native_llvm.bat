@echo off
REM Called by every project's android_build_inner.bat (needs NDK and AT set).
REM Google ships the Android NDK compiler only as an x64 program, which runs under emulation
REM on this ARM64 laptop. This makes (once) a copy of the NDK layout whose compiler is the
REM native ARM64 LLVM from C:\Program Files\LLVM, keeping Google's Android headers, libraries
REM and runtime pieces. Result: NATIVE_LLVM=1 and NATIVE_NDK=<folder>, or NATIVE_LLVM=0.
REM Turn off with: set ANDROID_NATIVE_LLVM=0 (the build scripts do this automatically on failure).
set "NATIVE_LLVM=0"
set "NATIVE_NDK="
if "%ANDROID_NATIVE_LLVM%"=="0" (echo ==== native compiler: off, using Google's NDK compiler & exit /b 0)
if /i not "%PROCESSOR_ARCHITECTURE%"=="ARM64" exit /b 0
REM After a failed native build the project keeps using Google's compiler until Claude has a look.
if exist "%ROOT%logs\native_compiler_failed.txt" (echo ==== native compiler: off after an earlier failure, using Google's NDK compiler & exit /b 0)
set "LLVM=C:\Program Files\LLVM"
if not exist "%LLVM%\bin\clang.exe" (echo ==== native compiler: LLVM not found & exit /b 0)
set "LV="
for /d %%V in ("%LLVM%\lib\clang\*") do set "LV=%%~nxV"
if "%LV%"=="" (echo ==== native compiler: LLVM resource folder not found & exit /b 0)
set "HN=%AT%\ndk-native-llvm"
set "NP=%NDK%\toolchains\llvm\prebuilt\windows-x86_64"
set "HP=%HN%\toolchains\llvm\prebuilt\windows-x86_64"
set "VERFILE=%AT%\ndk-native-llvm-check.txt"
"%LLVM%\bin\clang.exe" --version > "%VERFILE%" 2>&1
echo NDK=%NDK% >> "%VERFILE%"
if exist "%HN%\ready.txt" fc /b "%VERFILE%" "%HN%\ready.txt" >nul 2>&1 && goto :ready

echo ==== native compiler: preparing %HN% (one time, about 2 GB)
robocopy "%NDK%\build" "%HN%\build" /E /NFL /NDL /NP /NJH /NJS >nul
if errorlevel 8 goto :nope
if exist "%NDK%\meta" robocopy "%NDK%\meta" "%HN%\meta" /E /NFL /NDL /NP /NJH /NJS >nul
copy /y "%NDK%\source.properties" "%HN%\source.properties" >nul || goto :nope
robocopy "%NP%" "%HP%" /E /NFL /NDL /NP /NJH /NJS >nul
if errorlevel 8 goto :nope
REM Native ARM64 compiler, linker and tools replace Google's x64 ones (others stay as they are).
for %%T in (clang.exe clang++.exe ld.lld.exe lld.exe llvm-ar.exe llvm-ranlib.exe llvm-strip.exe llvm-objcopy.exe llvm-nm.exe llvm-objdump.exe llvm-readelf.exe llvm-readobj.exe llvm-symbolizer.exe) do (
  if exist "%LLVM%\bin\%%T" copy /y "%LLVM%\bin\%%T" "%HP%\bin\%%T" >nul
)
if not exist "%HP%\bin\clang++.exe" copy /y "%LLVM%\bin\clang.exe" "%HP%\bin\clang++.exe" >nul
if not exist "%HP%\bin\ld.lld.exe" if exist "%LLVM%\bin\lld.exe" copy /y "%LLVM%\bin\lld.exe" "%HP%\bin\ld.lld.exe" >nul
REM The compiler's own headers come from LLVM; the Android runtime libraries
REM (builtins, libunwind) come from Google's NDK.
robocopy "%LLVM%\lib\clang\%LV%\include" "%HP%\lib\clang\%LV%\include" /E /NFL /NDL /NP /NJH /NJS >nul
if errorlevel 8 goto :nope
set "NV="
for /d %%V in ("%NP%\lib\clang\*") do set "NV=%%~nxV"
if "%NV%"=="" goto :nope
robocopy "%NP%\lib\clang\%NV%\lib" "%HP%\lib\clang\%LV%\lib" /E /NFL /NDL /NP /NJH /NJS >nul
if errorlevel 8 goto :nope
if exist "%NP%\lib\clang\%NV%\share" robocopy "%NP%\lib\clang\%NV%\share" "%HP%\lib\clang\%LV%\share" /E /NFL /NDL /NP /NJH /NJS >nul

REM Quick test: build and link a small Android C++ library with the new layout.
set "T=%HN%\selftest"
if not exist "%T%" mkdir "%T%"
> "%T%\t.cpp" echo #include ^<string^>
>> "%T%\t.cpp" echo #include ^<vector^>
>> "%T%\t.cpp" echo #include ^<thread^>
>> "%T%\t.cpp" echo extern "C" int selftest(int n) { std::vector^<std::string^> v(n, "x"); std::thread t([]{}); t.join(); return (int)v.size(); }
"%HP%\bin\clang++.exe" --target=aarch64-none-linux-android31 "--sysroot=%HP%\sysroot" -std=c++20 -O2 -fPIC -shared -nostdlib++ -o "%T%\t.so" "%T%\t.cpp" -lc++_shared -fuse-ld=lld
if errorlevel 1 (echo ==== native compiler: self-test FAILED & goto :nope)
if not exist "%T%\t.so" goto :nope
copy /y "%VERFILE%" "%HN%\ready.txt" >nul
echo ==== native compiler: ready (LLVM %LV%)

:ready
set "NATIVE_NDK=%HN%"
set "NATIVE_SYSROOT=%HP:\=/%/sysroot"
set "NATIVE_LLVM=1"
echo ==== COMPILER native-llvm %LV%
exit /b 0

:nope
echo ==== native compiler: could not be set up, using Google's NDK compiler
set "NATIVE_LLVM=0"
set "NATIVE_NDK="
exit /b 0
