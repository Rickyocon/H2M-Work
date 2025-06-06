# Set local and network log paths
$localLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetUpdateUpgradeScript.log"
$networkRoot = "\\h2m.com\shares\files_shared\WingetUpateUserLogs"
$userName = $env:USERNAME
$userFolder = Join-Path $networkRoot $userName
$networkLog = Join-Path $userFolder "WingetUpdateUpgradeScript.log"

# Remove any existing local log
Remove-Item $localLog -Force -ErrorAction SilentlyContinue

# Start transcript locally
Start-Transcript -Path $localLog -Append

# Resolve path to winget.exe
$wingetDir = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" |
    Sort-Object -Property Path |
    Select-Object -Last 1

if (-not $wingetDir) {
    Write-Output "ERROR: Winget package directory not found."
    Stop-Transcript
    exit 1
}

$wingetExe = Join-Path $wingetDir.Path "winget.exe"

if (-not (Test-Path $wingetExe)) {
    Write-Output "ERROR: winget.exe not found at expected location: $wingetExe"
    Stop-Transcript
    exit 1
}

Write-Output "Using winget path: $wingetExe"
Write-Output "Checking for available winget upgrades..."
$upgrades = & $wingetExe upgrade --accept-source-agreements --accept-package-agreements

# PIN Section
Write-Output "Pinning required applications to prevent auto-upgrade..."
& $wingetExe pin add --id Microsoft.Office
& $wingetExe pin add --id HydrologicEngineeringCenter.HEC-RAS
& $wingetExe pin add --id Carrier.HourlyAnalysisProgram
& $wingetExe pin add --id DuoSecurity.Duo2FAAuthenticationforGǪ
& $wingetExe pin add --id DuoSecurity.Duo2FAAuthenticationforWinGǪ
& $wingetExe pin add --id DuoSecurity.Duo2FAAuthenticationforWindoGǪ
& $wingetExe pin add --id DuoSecurity.Duo2FAAuthenticationforWindows
& $wingetExe pin add --id DuoSecurity.Duo2FAAuthenticationfoGǪ
& $wingetExe pin add --id Microsoft.Teams.Free
& $wingetExe pin add --id Git.Git
& $wingetExe pin add --id Clockify.Clockify
& $wingetExe pin add --id Asana.Asana
& $wingetExe pin add --id Anaconda.Miniconda3
& $wingetExe pin add --id JohnMacFarlane.Pandoc

if ($upgrades -match "No applicable upgrade found") {
    Write-Output "All packages are already up to date."
} else {
    Write-Output "Upgrading all available packages (excluding pinned ones)..."
    & $wingetExe upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Output "Upgrade process complete."
}

Stop-Transcript

# Copy transcript to network share
try {
    if (-not (Test-Path $userFolder)) {
        New-Item -Path $userFolder -ItemType Directory -Force | Out-Null
    }

    Copy-Item -Path $localLog -Destination $networkLog -Force
    Write-Output "Transcript successfully copied to network share: $networkLog"
} catch {
    Write-Output "Failed to copy transcript to network share: $_"
}
