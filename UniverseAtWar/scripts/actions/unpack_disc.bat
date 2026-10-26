@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
call "%ROOT%scripts\paths.bat"
set "PY="
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do if exist "%%D\python.exe" set "PY=%%D\python.exe"
if "%PY%"=="" set "PY=python"
echo Unpacking the Universe at War disc image (takes several minutes)...
echo   from: %GAME_ISO%
echo   to:   %GAME%
echo.
"%PY%" "%ROOT%scripts\unpack_disc.py" "%GAME_ISO%" "%GAME%"
if errorlevel 1 (echo UNPACK FAILED - see the logs folder. & pause & exit /b 1)
echo.
echo Game files unpacked.
pause
