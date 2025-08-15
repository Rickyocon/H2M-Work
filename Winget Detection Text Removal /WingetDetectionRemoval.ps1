$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogPath\WingetDetectionRemoval.log" -Append

# Define paths
$SupportPath = "C:\Support"

$SuportFolderError = "Support Folder Does Not Exist"
$Winget_UpdatePrint = "Winget_Update.ps1 Deleted Successfully"
$WingetDetectionPrint = "Winget_Update_Detection.txt Deleted Successfully"
$WingetProccessingPrint = "Winget-Proccessing.ps1 Deleted Successfully"

# Ensure Support folder exists
if (-not (Test-Path -Path $SupportPath)) {
    Write-Output $SuportFolderError
}

# Cleanup
$UpdateScript = "$SupportPath\Winget_Update.ps1"
$DetectionFile = "$SupportPath\Winget_Update_Detection.txt"
$ProcessingScript = "$SupportPath\Winget-Proccessing.ps1"

Remove-Item $UpdateScript -Force -ErrorAction SilentlyContinue
Remove-Item $DetectionFile -Force -ErrorAction SilentlyContinue
Remove-Item $ProcessingScript -Force -ErrorAction SilentlyContinue

# Check if files were deleted
if (-not (Test-Path -Path $UpdateScript)) {
    Write-Output $Winget_UpdatePrint
} else {
    Write-Output "Winget_Update.ps1 could not be deleted. There was either an error or the file does not exist."
}

if (-not (Test-Path -Path $DetectionFile)) {
    Write-Output $WingetDetectionPrint
} else {
    Write-Output "Winget_Update_Detection.txt could not be deleted. There was either an error or the file does not exist."
}

if (-not (Test-Path -Path $ProcessingScript)) {
    Write-Output $WingetProccessingPrint
} else {
    Write-Output "Winget-Proccessing.ps1 could not be deleted. There was either an error or the file does not exist."
}

Stop-Transcript
