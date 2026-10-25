@echo off
title Universe at War recomp
:menu
cls
echo.
echo   =============================================
echo    Universe at War recomp  -  Start here
echo   =============================================
echo.
echo    FIRST-TIME SETUP
echo     1  Download and build the toolkit and the PC version
echo     2  Install the Android build tools
echo.
echo    PLAY
echo     3  Play on PC
echo     4  Retroid: build, install and start the game
echo.
echo     0  Exit
echo.
set "CHOICE="
set /p CHOICE=  Type a number and press Enter: 
set "A=%~dp0scripts\actions"
if "%CHOICE%"=="1" call :pc_build
if "%CHOICE%"=="2" call "%A%\android_install_tools.bat"
if "%CHOICE%"=="3" call "%A%\pc_play.bat"
if "%CHOICE%"=="4" call :retroid_play
if "%CHOICE%"=="0" exit /b 0
goto menu

:pc_build
if not exist "%~dp0logs" mkdir "%~dp0logs"
echo Building the toolkit (log: logs\01_sdk_build.log) - this takes a while...
cmd /c ""%~dp0scripts\build_sdk_inner.bat" > "%~dp0logs\01_sdk_build.log" 2>&1"
if errorlevel 1 (echo TOOLKIT BUILD FAILED - see logs\01_sdk_build.log & pause & exit /b 1)
echo Building the PC version (log: logs\02_game_build.log)...
cmd /c ""%~dp0scripts\game_inner.bat" > "%~dp0logs\02_game_build.log" 2>&1"
if errorlevel 1 (echo GAME BUILD FAILED - see logs\02_game_build.log & pause & exit /b 1)
echo Done.
pause
exit /b 0

:retroid_play
call "%A%\android_build_app.bat"
if errorlevel 1 exit /b 1
call "%A%\android_install_and_start.bat"
exit /b 0
