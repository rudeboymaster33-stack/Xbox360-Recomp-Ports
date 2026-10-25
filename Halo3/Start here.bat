@echo off
title Halo 3 recomp
:menu
cls
echo.
echo   =============================================
echo    Halo 3 recomp (Retroid Pocket)  -  Start here
echo   =============================================
echo.
echo    FIRST TIME
echo     1  Unpack the game disc
echo.
echo    PLAY
echo     2  Retroid: build, install and start the game
echo.
echo     0  Exit
echo.
set "CHOICE="
set /p CHOICE=  Type a number and press Enter: 
set "A=%~dp0scripts\actions"
if "%CHOICE%"=="1" call "%A%\unpack_disc.bat"
if "%CHOICE%"=="2" call :retroid_play
if "%CHOICE%"=="0" exit /b 0
goto menu

:retroid_play
call "%A%\android_build_app.bat"
if errorlevel 1 exit /b 1
call "%A%\android_install_and_start.bat"
exit /b 0
