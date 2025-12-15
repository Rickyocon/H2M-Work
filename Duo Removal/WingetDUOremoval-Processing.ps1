$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogPath\WingetProcessingDuoRemoval.log" -Append

# Define paths
New-Item -Path "C:\Support\WingetDuoRemoval" -ItemType directory -Force | Out-Null
$SupportPath = "C:\Support\WingetDuoRemoval"
$AppServerPath = "\\app-server\APPS\_Intune Applications\1 Source\PowerShell\Winget"

# Ensure Support folder exists
if (-not (Test-Path -Path "C:\Support")) {
    New-Item -Path "C:\Support" -ItemType Directory -Force | Out-Null
}

# Re-add from local package
Copy-Item -Path "$AppServerPath\WingetDUOremoval.ps1" -Destination "$SupportPath" -Force

# Create detection file
New-Item -Path "$SupportPath\Winget_Duo_Removal_Detection.txt" -ItemType File -Force | Out-Null

# Run the update script
powershell.exe -ExecutionPolicy Bypass -File "C:\Support\WingetDuoRemoval\WingetDUOremoval.ps1"

Stop-Transcript