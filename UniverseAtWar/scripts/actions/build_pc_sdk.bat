@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
REM Downloads the ReXGlue SDK, applies the patches and builds the PC tools (rexglue.exe).
REM Halo 3, Black Ops and Black Ops II copy this SDK, so it is needed once on a new PC.
if not exist "%ROOT%logs" mkdir "%ROOT%logs"
echo Building the PC SDK... this takes a long time. (log: logs\01_sdk_build.log)
cmd /c ""%ROOT%scripts\build_sdk_inner.bat" > "%ROOT%logs\01_sdk_build.log" 2>&1"
if errorlevel 1 (echo SDK BUILD FAILED - see the logs folder. & pause & exit /b 1)
echo SDK built.
pause
