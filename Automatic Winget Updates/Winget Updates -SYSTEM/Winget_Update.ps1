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

Write-Output "Checking for available winget upgrades..."
$upgrades = & $wingetExe upgrade --accept-source-agreements --accept-package-agreements


#Add Pins Here: & $wingetExe pin add --id "APPS ID"  (To find app ID's -> windows key + R -> cmd -> winget search 'app your looking to pin' -> Youll see the app name and an app ID (or use winget list))
Write-Output "Pinning Microsoft.Office to prevent auto-upgrade..."
& $wingetExe pin add --id Microsoft.Office

if ($upgrades -match "No applicable upgrade found") {
    Write-Output "All packages are already up to date."
} else {
    Write-Output "Upgrading all available packages (excluding pinned ones)..."
    & $wingetExe upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Output "Upgrade process complete."
}

Stop-Transcript
