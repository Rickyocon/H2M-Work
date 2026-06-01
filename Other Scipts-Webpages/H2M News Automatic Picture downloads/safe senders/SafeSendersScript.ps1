$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$LogPath\SafeSendersScript.log" -Append


# Define paths
$SupportPath = "C:\Support"
$AppServerPath = "\\app-server\APPS\_Intune Applications\1 Source\PowerShell\SafeSenders"
$SafeSenderPath = "$SupportPath\SafeSenders"

# Ensure Support folder exists
if (-not (Test-Path -Path $SupportPath)) {
    New-Item -Path $SupportPath -ItemType Directory -Force | Out-Null
}


New-Item -Path "$SupportPath\SafeSenders" -ItemType Directory -Force | Out-Null

Copy-Item -Path "$AppServerPath\SafeSenders.txt" -Destination "$SafeSenderPath\SafeSenders.txt" -Force
Copy-Item -Path "$AppServerPath\SafeSendersScript.ps1" -Destination "$SafeSenderPath\SafeSendersScript.ps1" -Force