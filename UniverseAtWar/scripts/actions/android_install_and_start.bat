@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
REM Android step 3: install the app on the phone over USB, copy the game files (first time only), start it.
REM Needs: phone plugged in with USB debugging on (accept the "Allow USB debugging?" prompt on the phone).

set "ADB=%ROOT%android-tools\sdk\platform-tools\adb.exe"
call "%ROOT%scripts\paths.bat"
set "PKGDIR=/sdcard/Android/data/com.uaw.recomp/files"
set "LOG=%ROOT%logs\22_install.log"
echo ==== %DATE% %TIME% > "%LOG%"
"%ADB%" start-server >> "%LOG%" 2>&1
"%ADB%" devices -l >> "%LOG%" 2>&1
"%ADB%" get-state 2>nul | findstr device >nul
if errorlevel 1 (
  echo.
  echo Phone not found. Check: USB cable plugged in, USB debugging on,
  echo and tap "Allow" on the phone's "Allow USB debugging?" prompt. Then try again.
  echo NO DEVICE >> "%LOG%"
  pause & exit /b 1
)
echo Installing the app...
set "REKEY=%ROOT%..\UniverseAtWar\scripts\retroid_rekey.bat"
set "BACKUP=%ROOT%retroid_backup"
"%ADB%" install -r "%ROOT%UniverseAtWar.apk" >> "%LOG%" 2>&1
if errorlevel 1 goto :install_failed
REM A saves backup still waiting to go back (from an earlier try) is restored below.
if exist "%BACKUP%\retroid_files.tar" set "RESTORE_BACKUP=1"
:installed
REM Android only lets the app itself create its folder, so start it once and close it.
"%ADB%" shell am start -n com.uaw.recomp/.UawActivity >> "%LOG%" 2>&1
timeout /t 6 /nobreak >nul
"%ADB%" shell am force-stop com.uaw.recomp >> "%LOG%" 2>&1
REM After moving to the new signing key: put the game files that were moved aside back in place.
call "%REKEY%" putback "%ADB%" com.uaw.recomp "%LOG%" || (pause & exit /b 1)
"%ADB%" shell ls -la %PKGDIR% >> "%LOG%" 2>&1
"%ADB%" shell ls %PKGDIR%/game/default.xex >nul 2>&1
if errorlevel 1 (
  echo Copying the game files to the phone - about 6 GB, this takes several minutes...
  REM Stream the files through tar: adb push cannot create folders inside Android/data on newer Android.
  pushd "%GAME%"
  tar -cf - Data default.xex | "%ADB%" exec-in tar -xf - -C %PKGDIR%/game >> "%LOG%" 2>&1
  popd
  "%ADB%" shell ls %PKGDIR%/game/default.xex >nul 2>&1
  if errorlevel 1 (echo Copy failed - see the logs folder. & pause & exit /b 1)
  "%ADB%" shell du -sh %PKGDIR%/game >> "%LOG%" 2>&1
) else (
  echo Game files already on the phone.
)
if defined RESTORE_BACKUP call "%REKEY%" restore "%ADB%" com.uaw.recomp "%BACKUP%" "%LOG%" || (pause & exit /b 1)
REM Files copied in over USB belong to the Retroid's "shell" user; let the app read and write them.
"%ADB%" shell "chmod -R a+rwX %PKGDIR%/game %PKGDIR%/update %PKGDIR%/userdata %PKGDIR%/*.log 2>/dev/null; ls -la %PKGDIR% %PKGDIR%/userdata %PKGDIR%/userdata/cache" >> "%LOG%" 2>&1
"%ADB%" pull %PKGDIR%/uaw.log "%ROOT%logs\android_uaw_firstrun.log" >> "%LOG%" 2>&1
"%ADB%" shell rm -f %PKGDIR%/uaw.log >> "%LOG%" 2>&1
"%ADB%" shell rm -f %PKGDIR%/args.txt %PKGDIR%/profile_on >> "%LOG%" 2>&1
"%ADB%" logcat -c >> "%LOG%" 2>&1
echo Starting the game on the phone...
"%ADB%" shell am start -n com.uaw.recomp/.UawActivity >> "%LOG%" 2>&1
echo ==== DONE >> "%LOG%"
echo.
echo The game should now be opening on your phone.
pause
exit /b 0

:install_failed
findstr /c:"INSTALL_FAILED_UPDATE_INCOMPATIBLE" "%LOG%" >nul
if errorlevel 1 (echo Install failed - see the logs folder. & pause & exit /b 1)
call "%REKEY%" backup_reinstall "%ADB%" com.uaw.recomp "%ROOT%UniverseAtWar.apk" "%BACKUP%" "%LOG%"
if errorlevel 1 (pause & exit /b 1)
set "RESTORE_BACKUP=1"
goto :installed
