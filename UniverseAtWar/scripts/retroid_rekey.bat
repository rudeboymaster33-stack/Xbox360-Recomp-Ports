@echo off
REM Moves a game on the Retroid to the new PC's app signing key, keeping its saves.
REM The old PC's signing key (android-tools\debug.keystore) was not moved to the new PC, and
REM Android only updates an app signed with the same key. So, once per game:
REM   retroid_rekey.bat backup_reinstall <adb> <package> <apk> <backup folder> <log>
REM     copies everything in Android/data/<package>/files EXCEPT the game files (game\, update\)
REM     to <backup folder>\retroid_files.tar and checks the copy; MOVES the game files (no copy)
REM     to /sdcard/recomp_keep/<package>/ on the Retroid so uninstalling does not delete them;
REM     then uninstalls the old app and installs the new one.
REM   retroid_rekey.bat putback <adb> <package> <log>
REM     right after the new app has created its folder: moves the game files back (no-op if none kept).
REM   retroid_rekey.bat restore <adb> <package> <backup folder> <log>
REM     copies the saves backup back and renames it to retroid_files_restored_*.tar (kept, never deleted).
setlocal
set "MODE=%~1"
set "ADB=%~2"
set "PKG=%~3"
set "DIR=/sdcard/Android/data/%PKG%/files"
set "KEEP=/sdcard/recomp_keep/%PKG%"
if /i "%MODE%"=="putback" goto :putback
if /i "%MODE%"=="restore" goto :restore
if /i not "%MODE%"=="backup_reinstall" (echo retroid_rekey: unknown mode %MODE% & exit /b 1)

set "APK=%~4"
set "BK=%~5"
set "LOG=%~6"
set "TAR=%BK%\retroid_files.tar"
echo.
echo  ======================================================================
echo   The game on the Retroid was signed by the old PC, and Android will
echo   only update it from that PC. To move it to this laptop (once):
echo     1. your saves and settings for this game are copied to the laptop
echo     2. the game files are moved aside on the Retroid ^(a few seconds^)
echo     3. the old app is uninstalled and the new one installed
echo     4. the game files and your saves go back into the new app
echo   Saves backup: %TAR%
echo  ======================================================================
echo.
echo  Press any key to start, or close this window to cancel.
pause >nul
echo ==== REKEY %PKG% %DATE% %TIME% >> "%LOG%"
if not exist "%BK%" mkdir "%BK%"
if exist "%TAR%" (
  echo A saves backup from an earlier try is already there - keeping it and using it.
  goto :verify
)
echo Copying saves and settings from the Retroid...
"%ADB%" shell "cd %DIR% && ls -A" > "%BK%\retroid_contents.txt" 2>>"%LOG%"
type "%BK%\retroid_contents.txt" >> "%LOG%"
"%ADB%" exec-out "cd %DIR% && tar -cf - $(ls -A | grep -v -x -e game -e update)" > "%TAR%.part" 2>>"%LOG%"
if errorlevel 1 (echo Backup failed - nothing was uninstalled. & del "%TAR%.part" 2>nul & exit /b 1)
move /y "%TAR%.part" "%TAR%" >nul

:verify
tar -tf "%TAR%" > "%BK%\retroid_files_list.txt" 2>>"%LOG%"
if errorlevel 1 (echo The backup could not be read - nothing was uninstalled. & exit /b 1)
for %%A in ("%TAR%") do set "SIZE=%%~zA"
echo backup %TAR% %SIZE% bytes >> "%LOG%"
type "%BK%\retroid_files_list.txt" >> "%LOG%"
findstr /b /c:"userdata" "%BK%\retroid_files_list.txt" >nul
if errorlevel 1 (
  echo.
  echo  Note: no saves folder ^(userdata^) was found for this game on the Retroid.
  echo  Press any key to continue anyway, or close this window to cancel.
  pause >nul
)
echo Saves backup OK (%SIZE% bytes).
echo Moving the game files aside on the Retroid...
"%ADB%" shell "mkdir -p %KEEP% && for d in game update; do if [ -d %DIR%/$d ]; then [ -e %KEEP%/$d ] && exit 2; mv %DIR%/$d %KEEP%/ || exit 1; fi; done; ls -la %KEEP%" >> "%LOG%" 2>&1
if errorlevel 1 (echo Moving the game files failed - nothing was uninstalled. & exit /b 1)
"%ADB%" shell "[ ! -e %DIR%/game ] && [ ! -e %DIR%/update ]" >nul 2>&1
if errorlevel 1 (echo The game files did not move - nothing was uninstalled. & exit /b 1)
echo Uninstalling the old app...
"%ADB%" uninstall %PKG% >> "%LOG%" 2>&1
echo Installing the new app...
"%ADB%" install "%APK%" >> "%LOG%" 2>&1
if errorlevel 1 (echo Install failed - your saves are safe on the laptop and the game files in recomp_keep on the Retroid. & exit /b 1)
exit /b 0

:putback
set "LOG=%~4"
"%ADB%" shell "[ -d %KEEP% ]" >nul 2>&1
if errorlevel 1 exit /b 0
echo Moving the game files back into the app...
REM A freshly installed app can take a while to create its folder on its first start
REM (only the app itself may create it), so start it and wait up to a minute.
set "N=0"
:waitdir
"%ADB%" shell "[ -d %DIR% ]" >nul 2>&1
if not errorlevel 1 goto :havedir
set /a N+=1
if %N% GEQ 13 (
  echo The app did not create its folder. The game files are safe in recomp_keep on the Retroid.
  echo NO APP FOLDER after waiting >> "%LOG%"
  "%ADB%" shell am force-stop %PKG% >> "%LOG%" 2>&1
  exit /b 1
)
if %N%==1 echo   waiting for the app to create its folder...
"%ADB%" shell monkey -p %PKG% -c android.intent.category.LAUNCHER 1 >> "%LOG%" 2>&1
timeout /t 5 /nobreak >nul
goto :waitdir
:havedir
"%ADB%" shell am force-stop %PKG% >> "%LOG%" 2>&1
echo app folder found after %N% wait^(s^) >> "%LOG%"
"%ADB%" shell "for d in game update; do if [ -d %KEEP%/$d ]; then rmdir %DIR%/$d 2>/dev/null; if [ -e %DIR%/$d ]; then echo KEEP_NOT_EMPTY $d; else mv %KEEP%/$d %DIR%/ || { echo MOVE_FAILED $d; exit 1; }; fi; fi; done; rmdir %KEEP% /sdcard/recomp_keep 2>/dev/null; ls -la %DIR%" >> "%LOG%" 2>&1
if errorlevel 1 (echo Moving the game files back failed. They are safe in recomp_keep on the Retroid. & exit /b 1)
echo ==== PUTBACK done >> "%LOG%"
exit /b 0

:restore
set "BK=%~4"
set "LOG=%~5"
set "TAR=%BK%\retroid_files.tar"
if not exist "%TAR%" exit /b 0
echo Copying your saves and settings back to the Retroid...
"%ADB%" exec-in tar -xf - -C %DIR% < "%TAR%" >> "%LOG%" 2>&1
if errorlevel 1 (echo Restoring the saves failed - the backup is safe on the laptop. & exit /b 1)
"%ADB%" shell ls -la %DIR% %DIR%/userdata >> "%LOG%" 2>&1
set "STAMPNAME=%DATE:/=-%_%TIME::=-%"
set "STAMPNAME=%STAMPNAME: =0%"
set "STAMPNAME=%STAMPNAME:,=-%"
set "STAMPNAME=%STAMPNAME:.=-%"
ren "%TAR%" "retroid_files_restored_%STAMPNAME%.tar"
echo ==== RESTORED >> "%LOG%"
exit /b 0
