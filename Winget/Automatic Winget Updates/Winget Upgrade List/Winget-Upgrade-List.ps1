# Define base log directory (per user)
$WingetUpgradeListLog = "PUT PATH HERE"
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

# Refresh sources (especially important for msstore-related errors)
try {
    winget source update | Out-Null
    Start-Sleep -Seconds 5  # slight delay to let source refresh settle
} catch {
    Write-Output "WARNING: winget source update failed: $_"
}


# Run winget upgrade with interactivity disabled and clean the output
try {
    $wingetOutput = powershell.exe -ExecutionPolicy Bypass winget upgrade --accept-source-agreements --verbose-logs 2>&1

    # Remove lines with non-ASCII characters or spinner/progress artifacts
    $cleanOutput = $wingetOutput | Where-Object {
        $_.Trim() -ne "" -and ($_ -notmatch "^\s*[-\\|/]+\s*$")
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


