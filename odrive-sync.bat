@echo off cd /d %~dp0 set FOLDERPATH="D:\odrive\Dropbox\" set ODRIVEBIN="$HOME\.odrive-agent\bin\" for /r "%FOLDERPATH%" %%i in (*.cloudf) do "%ODRIVEBIN%" sync "%%i" for /r "%FOLDERPATH%" %%i in (*.cloud) do "%ODRIVEBIN%" sync "%%i"