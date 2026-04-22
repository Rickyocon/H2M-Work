# ==========================================================
# Dell Command | Update Universal 5.7
# Enterprise-safe installer
# No Win32_Product
# No installer popups
# ==========================================================

$ErrorActionPreference = "Stop"

Write-Output "=== Starting DCU Universal 5.7 Deployment ==="

# ----------------------------------------------------------
# Function: Uninstall Dell Command Update (Classic/Universal)
# ----------------------------------------------------------
function Remove-DCU {
    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($keyPath in $uninstallKeys) {
        Get-ChildItem $keyPath -ErrorAction SilentlyContinue | ForEach-Object {
            $app = Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue
            if ($app.DisplayName -like "Dell Command | Update*") {

                Write-Output "Removing: $($app.DisplayName)"

                if ($app.UninstallString -match "\{.*\}") {
                    $guid = $Matches[0]
                    Start-Process "msiexec.exe" `
                        -ArgumentList "/x $guid /qn /norestart" `
                        -Wait
                }
            }
        }
    }
}

# ----------------------------------------------------------
# 1. Remove all existing DCU variants
# ----------------------------------------------------------
Remove-DCU

# ----------------------------------------------------------
# 2. Install .NET Desktop Runtime 8.0.26
# ----------------------------------------------------------
Write-Output "Installing .NET Desktop Runtime 8.0.26..."

Start-Process ".\windowsdesktop-runtime-8.0.26-win-x64.exe" `
    -ArgumentList "/install /quiet /norestart" `
    -Wait

# Give .NET time to finalize registry writes
Start-Sleep -Seconds 15

# ----------------------------------------------------------
# 3. Install DCU Universal 5.7
# ----------------------------------------------------------
Write-Output "Installing Dell Command | Update Universal 5.7..."

Start-Process ".\Dell-Command-Update-Windows-Universal-Application_FGK9X_WIN64_5.7.0_A00.EXE" `
    -ArgumentList "/s" `
    -Wait

# ----------------------------------------------------------
# 4. Validate installation
# ----------------------------------------------------------
$dcuCli = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

if (-not (Test-Path $dcuCli)) {
    throw "Dell Command Update Universal failed to install"
}

# Ensure service is running
Start-Service DellClientManagementService -ErrorAction SilentlyContinue

# Run validation scan
& $dcuCli /scan | Out-Null

Write-Output "=== Dell Command Update Universal 5.7 SUCCESS ==="
exit 0
