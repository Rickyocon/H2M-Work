$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogPath\WingetDuoUninstallDetectionRemoval.log" -Append

# Define paths
$SupportPath = "C:\Support"


$SuportFolderError = "Support Folder Does Not Exist"
$WingetDuoDetectionFolderStatus = "WingetDuoRemoval Folder Deleted Successfully"

# Ensure Support folder exists
if (-not (Test-Path -Path $SupportPath)) {
    Write-Output $SuportFolderError
}

# Cleanup
$WingetDuoDetectionFolder = "$SupportPath\WingetDuoRemoval"

Remove-Item $WingetDuoDetectionFolder -Force -Recurse

if (-not (Test-Path -Path "$SupportPath\WingetDuoRemoval")) {
    Write-Output $WingetDuoDetectionFolderStatus
} else {
    Write-Output "Winget_Update_Detection.txt could not be deleted. There was either an error or the file does not exist."
}

Stop-Transcript
