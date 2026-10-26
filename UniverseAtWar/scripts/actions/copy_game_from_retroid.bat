@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
REM Copies the Universe at War game files (Data + default.xex) from the Retroid back to the PC,
REM for when the disc image is lost. Needs option 6 done first (for adb) and the Retroid plugged in.
call "%ROOT%scripts\paths.bat"
set "ADB=%ROOT%android-tools\sdk\platform-tools\adb.exe"
set "PKGDIR=/sdcard/Android/data/com.uaw.recomp/files"
set "LOG=%ROOT%logs\23_copy_from_retroid.log"
if not exist "%ROOT%logs" mkdir "%ROOT%logs"
echo ==== %DATE% %TIME% > "%LOG%"
if not exist "%ADB%" (echo Android tools not installed yet - run option 6 first. & pause & exit /b 1)
"%ADB%" start-server >> "%LOG%" 2>&1
"%ADB%" get-state 2>nul | findstr device >nul
if errorlevel 1 (
  echo.
  echo Retroid not found. Check: USB cable plugged in, USB debugging on,
  echo and tap "Allow" on the Retroid's "Allow USB debugging?" prompt. Then try again.
  echo NO DEVICE >> "%LOG%"
  pause & exit /b 1
)
"%ADB%" shell ls %PKGDIR%/game/default.xex >nul 2>&1
if errorlevel 1 (echo The game files are not on the Retroid. & echo NO GAME FILES >> "%LOG%" & pause & exit /b 1)
"%ADB%" shell du -sh %PKGDIR%/game >> "%LOG%" 2>&1
if not exist "%GAME%" mkdir "%GAME%"
echo Copying the game files from the Retroid (about 6 GB, several minutes)...
echo   to: %GAME%
"%ADB%" exec-out tar -cf - -C %PKGDIR%/game Data default.xex | tar -xf - -C "%GAME%" >> "%LOG%" 2>&1
if not exist "%GAME%\default.xex" (echo Copy failed - see the logs folder. & echo COPY FAILED >> "%LOG%" & pause & exit /b 1)
dir /s "%GAME%" | findstr /c:"File(s)" >> "%LOG%"
echo ==== DONE >> "%LOG%"
echo.
echo Game files copied to the PC.
pause
