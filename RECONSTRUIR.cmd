@echo off
setlocal
cd /d "%~dp0"
python tools\export_extras.py
if errorlevel 1 goto error
python tools\export_wumpa.py
if errorlevel 1 goto error
python tools\package_mod.py
if errorlevel 1 goto error
echo PK3 reconstruido correctamente.
exit /b 0
:error
echo Error al reconstruir. Revisa Python y las dependencias de requirements.txt.
exit /b 1
