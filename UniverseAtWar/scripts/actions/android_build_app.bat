@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
REM Android step 2: build the Android app (UniverseAtWar.apk). Takes a while the first time.
if not exist "%ROOT%logs" mkdir "%ROOT%logs"
echo Building the Android version... (log: logs\21_android_build.log)
cmd /c ""%ROOT%scripts\android_build_inner.bat" > "%ROOT%logs\21_android_build.log" 2>&1"
if errorlevel 1 (
  findstr /c:"==== COMPILER native-llvm" "%ROOT%logs\21_android_build.log" >nul
  if not errorlevel 1 (
    echo The native ARM compiler build failed - building again with Google's compiler...
    copy /y "%ROOT%logs\21_android_build.log" "%ROOT%logs\21_android_build_native_failed.log" >nul
    set "ANDROID_NATIVE_LLVM=0"
    echo native compiler failed %DATE% %TIME% - see 21_android_build_native_failed.log> "%ROOT%logs\native_compiler_failed.txt"
    cmd /c ""%ROOT%scripts\android_build_inner.bat" > "%ROOT%logs\21_android_build.log" 2>&1"
  )
)
if errorlevel 1 (echo BUILD FAILED - see the logs folder. & pause & exit /b 1)
echo.
echo Done: UniverseAtWar.apk is in the UAW-Recomp folder.
pause
