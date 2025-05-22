# Define path for Winget Upgrade logs
$WingetUpgradeListLog = "\\h2m.com\shares\files_shared\WingetUpgradeList"

# Collect user and system information
$username = $env:USERNAME
$computer = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Define log file path
$logFile = Join-Path $WingetUpgradeListLog "$username.txt"

# Write the header section
@(
    "================================================================================================================"
    "$timestamp - Listing available winget upgrades for $username on $computer"
) | Set-Content -Path $logFile

# Run winget upgrade and filter out spinner lines
try {
    $wingetOutput = winget upgrade --accept-source-agreements 2>&1
    $cleanOutput = $wingetOutput | Where-Object {
        $_.Trim() -notin @('-', '\', '|', '')
    }
    $cleanOutput | Add-Content -Path $logFile

    # Add footer
    "================================================================================================================" | Add-Content -Path $logFile
} catch {
    @(
        "ERROR: Failed to run winget upgrade - $_"
        "=========================================================================="
    ) | Add-Content -Path $logFile
}


