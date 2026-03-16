$logDir = "C:\Support\RingCentral"
$logFile = "$logDir\RingCentralForTeamsInstall.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Start-Transcript -Path $logFile -Append

Write-Output "Starting RingCentral Teams Plugin installation..."

$installer = Join-Path $PSScriptRoot "RingCentralForTeamsDesktopPlugin.exe"

if (!(Test-Path $installer)) {
    Write-Output "Installer not found: $installer"
    Stop-Transcript
    exit 1
}

$process = Start-Process -FilePath $installer -ArgumentList "/S" -Wait -PassThru

Write-Output "Installer finished with exit code: $($process.ExitCode)"

Stop-Transcript

exit $process.ExitCode