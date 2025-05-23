# Define shared log file base name (not user-specific)
$WingetUpgradeListLog = "\\h2m.com\shares\files_shared\WingetUpgradeList"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computer = $env:COMPUTERNAME
$username = $env:USERNAME

# Define paths for .txt and .csv logs
$logBaseName = "WingetUpgradeLog"
$txtLogFile = Join-Path $WingetUpgradeListLog "$logBaseName.txt"
$csvLogFile = Join-Path $WingetUpgradeListLog "$logBaseName.csv"

# Create the header section
$header = @(
    "=========================================================================="
    "$timestamp - Listing available winget upgrades for $username on $computer"
    "=========================================================================="
)

# Append header to both files
$header | Add-Content -Path $txtLogFile
$header | Add-Content -Path $csvLogFile

# Run winget upgrade with interactivity disabled and clean the output
try {
    $wingetOutput = winget upgrade --accept-source-agreements --disable-interactivity 2>&1
    $cleanOutput = $wingetOutput | Where-Object {
        $_.Trim() -notin @('-', '\', '|', '')
    }

    # Append cleaned output to both files
    $cleanOutput | Add-Content -Path $txtLogFile
    $cleanOutput | Add-Content -Path $csvLogFile

    # Add footer and blank line
    @(
        "=========================================================================="
        ""
    ) | Add-Content -Path $txtLogFile

    @(
        "=========================================================================="
        ""
    ) | Add-Content -Path $csvLogFile
} catch {
    $errorMsg = @(
        "ERROR: Failed to run winget upgrade - $_"
        "=========================================================================="
        ""
    )
    $errorMsg | Add-Content -Path $txtLogFile
    $errorMsg | Add-Content -Path $csvLogFile
}


