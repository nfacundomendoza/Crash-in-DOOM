@echo off
setlocal
cd /d "%~dp0"
set "CRASH_DOOM_WAD=%~dp0DOOM2.WAD"
if not exist "%CRASH_DOOM_WAD%" set "CRASH_DOOM_WAD=%~dp0compartir\DOOM2.WAD"
if not exist "%CRASH_DOOM_WAD%" set "CRASH_DOOM_WAD=D:\SteamLibrary\steamapps\common\Ultimate Doom\base\doom2\DOOM2.WAD"
if not "%~1"=="" set "CRASH_DOOM_WAD=%~f1"
if not exist "%CRASH_DOOM_WAD%" (
  echo Falta DOOM2.WAD. Copialo a esta carpeta o arrastralo sobre JUGAR.cmd.
  pause
  exit /b 1
)
if not exist "%~dp0saves" mkdir "%~dp0saves"
"%~dp0tools\gzdoom\gzdoom.exe" -iwad "%CRASH_DOOM_WAD%" -file "%~dp0crash-in-doom.pk3" -config "%~dp0crash.ini" -savedir "%~dp0saves" -noautoload -window -warp 1 -skill 2 -exec "%~dp0start.cfg" +logfile "%~dp0last-run.log"
