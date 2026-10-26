@echo off
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
REM Step 4: launch the recompiled game (first boot test)
call "%ROOT%scripts\paths.bat"
copy /y "%ROOT%rexglue-sdk\out\install\win-arm64\bin\rexgpu-xenos.dll" "%ROOT%project\out\build\win-arm64-release\" >nul
cd /d "%ROOT%project\out\build\win-arm64-release"
if exist "%ROOT%logs\04_run.log" move /y "%ROOT%logs\04_run.log" "%ROOT%logs\04_run_previous.log" >nul
echo Starting Universe at War (recompiled)... log: logs\04_run.log
uaw.exe --gpu_plugin=xenos --mnk_mode=true --render_target_path_d3d12=rtv --occlusion_query_enable=false --user_data_root="%ROOT%userdata" --game_data_root="%GAME%" --log_file="%ROOT%logs\04_run.log" > "%ROOT%logs\04_run_console.log" 2>&1
echo Game exited with code %ERRORLEVEL% >> "%ROOT%logs\04_run_console.log"
echo Game exited (code %ERRORLEVEL%). See the logs folder. You can close this window.
pause
