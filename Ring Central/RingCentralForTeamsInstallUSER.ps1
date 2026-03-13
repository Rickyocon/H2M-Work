$logDir = "C:\Support\RingCentral"
$localLog = "$logDir\RingCentralForTeamsInstall.log"

New-Item -Path $logDir -ItemType Directory -Force | Out-Null

Start-Transcript -Path $localLog -Append

# Install RingCentral Teams Desktop Plugin via winget

$packageId = "RingCentral.RingCentralTeamsDesktopPlugin"

Write-Host "Checking if winget is available..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget is not installed or not in PATH. Exiting."
    exit 1
}

Write-Host "Installing package: $packageId"

winget install `
    $packageId `
    --exact `
    --accept-package-agreements `
    --accept-source-agreements `

if ($LASTEXITCODE -eq 0) {
    Write-Host "Installation completed successfully."
}
else {
    Write-Host "Installation failed with exit code $LASTEXITCODE"
}

Stop-Transcript