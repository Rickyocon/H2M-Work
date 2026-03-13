$logDir = "C:\Support\RingCentral"
$localLog = "$logDir\RingCentralForTeamsInstall.log"

New-Item -Path $logDir -ItemType Directory -Force | Out-Null

Start-Transcript -Path $localLog -Append

$packageId = "RingCentral.RingCentralTeamsDesktopPlugin"

# Resolve path to winget.exe
$wingetDir = Get-ChildItem "C:\Program Files\WindowsApps" -Directory -Filter "Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object -Last 1

if (-not $wingetDir) {
    Write-Output "ERROR: Winget package directory not found."
    Stop-Transcript
    exit 1
}

$wingetExe = Join-Path $wingetDir.FullName "winget.exe"

if (-not (Test-Path $wingetExe)) {
    Write-Output "ERROR: winget.exe not found at expected location: $wingetExe"
    Stop-Transcript
    exit 1
}

Write-Output "Using winget path: $wingetExe"

& $wingetExe install `
    $packageId `
    --exact `
    --accept-source-agreements `
    --accept-package-agreements

$exitCode = $LASTEXITCODE

if ($exitCode -eq 0 -or $exitCode -eq 1978335212) {
    Write-Output "Install successful or already installed."
    Stop-Transcript
    exit 0
}
else {
    Write-Output "Install failed with exit code $exitCode"
    Stop-Transcript
    exit $exitCode
}