Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetUpdateUpgradeScript.log" -Append

# Resolve path to winget.exe from App Installer package
$wingetDir = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" | 
    Sort-Object -Property Path | 
    Select-Object -Last 1

if (-not $wingetDir) {
    Write-Output "ERROR: Winget package directory not found."
    exit 1
}

$wingetExe = Join-Path $wingetDir.Path "winget.exe"

if (-not (Test-Path $wingetExe)) {
    Write-Output "ERROR: winget.exe not found at expected location: $wingetExe"
    exit 1
}

Write-Output "Using winget path: $wingetExe"

#Write-Output "Pinning Microsoft.Office to prevent auto-upgrade..."
#try {
#    & $wingetExe pin add --id Microsoft.Office --accept-source-agreements --accept-package-agreements 2>&1 | Tee-Object -Variable pinOutput
#    Write-Output "Pin Output: $pinOutput"
#}
#catch {
#    Write-Output "ERROR during winget pin add: $_"
#}


Write-Output "Checking for available winget upgrades..."
$upgrades = & $wingetExe upgrade

if ($upgrades -match "No applicable upgrade found") {
    Write-Output "All packages are already up to date."
} else {
    Write-Output "Upgrading all available packages (excluding pinned ones)..."
    & $wingetExe upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Output "Upgrade process complete."
}

Stop-Transcript
