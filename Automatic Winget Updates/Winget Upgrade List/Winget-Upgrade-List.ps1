# Define base log directory (per user)
$WingetUpgradeListLog = "\\h2m.com\shares\files_shared\WingetUpgradeList"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computer = $env:COMPUTERNAME
$username = $env:USERNAME

# Create user-specific folder if it doesn't exist
$userFolder = Join-Path $WingetUpgradeListLog $username
if (-not (Test-Path $userFolder)) {
    New-Item -Path $userFolder -ItemType Directory | Out-Null
}

# Define paths for user-specific .txt and .csv logs
$logBaseName = "WingetUpgradeLogFor-$username"
$txtLogFile = Join-Path $userFolder "$logBaseName.txt"
$csvLogFile = Join-Path $userFolder "$logBaseName.csv"

# Create the header section
$header = @(
    "================================================================================================================================="
    "$timestamp - Listing available winget upgrades for $username on $computer"
    "---------------------------------------------------------------------------------------------------------------------------------"
)

# Write header to both files (overwrite each run)
Set-Content -Path $txtLogFile -Value $header
Set-Content -Path $csvLogFile -Value $header

# Run winget upgrade with interactivity disabled and clean the output
try {
    $wingetOutput = winget upgrade --accept-source-agreements --accept-package-agreements 2>&1

    # Remove lines with non-ASCII characters or spinner/progress artifacts
    $cleanOutput = $wingetOutput | Where-Object {
        $_.Trim() -notin @('-', '\', '|', '') -and ($_ -match '^[\x20-\x7E]+$' -or $_ -eq '')
    }

    # Append cleaned output to both files
    Add-Content -Path $txtLogFile -Value $cleanOutput
    Add-Content -Path $csvLogFile -Value $cleanOutput

    # Add footer and blank line
    $footer = @(
        "================================================================================================================================="
        ""
    )
    Add-Content -Path $txtLogFile -Value $footer
    Add-Content -Path $csvLogFile -Value $footer
} catch {
    $errorMsg = @(
        "ERROR: Failed to run winget upgrade - $_"
        "================================================================================================================================="
        ""
    )
    Add-Content -Path $txtLogFile -Value $errorMsg
    Add-Content -Path $csvLogFile -Value $errorMsg
}

