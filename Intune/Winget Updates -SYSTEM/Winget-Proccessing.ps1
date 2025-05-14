$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogPath\WingetUpdateScript.log" -Append

# Define paths
$SupportPath = "C:\Support"
$AppServerPath = "\\app-server\APPS\_Intune Applications\1 Source\PowerShell\WingetEXE-Path"

# Cleanup
Remove-Item "$SupportPath\Winget_Update.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$SupportPath\Winget_Update_Detection.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "$SupportPath\Winget-Proccessing.ps1" -Force -ErrorAction SilentlyContinue

# Re-add from local package
Copy-Item -Path "$AppServerPath\Winget_Update.ps1" -Destination "$SupportPath\Winget_Update.ps1" -Force
Copy-Item -Path "$AppServerPath\Winget-Proccessing.ps1" -Destination "$SupportPath\Winget-Proccessing.ps1" -Force

# Create detection file
New-Item -Path "$SupportPath\Winget_Update_Detection.txt" -ItemType File -Force | Out-Null

#Start-Sleep -Seconds 30

# Run the update script
powershell.exe -ExecutionPolicy Bypass -File "C:\Support\Winget_Update.ps1"

Stop-Transcript


