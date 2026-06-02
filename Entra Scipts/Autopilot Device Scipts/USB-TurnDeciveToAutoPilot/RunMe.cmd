@echo off

set scriptPath=%~dp0AutoPilotUpload.ps1

echo Creating temp directory...
mkdir C:\Temp >nul 2>&1

echo Copying script to C:\Temp...
copy /Y "%scriptPath%" "C:\Temp\AutoPilotUpload.ps1"

echo Running script from C:\Temp...
powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\AutoPilotUpload.ps1"

echo Done.
pause