# Detection script: Check if winget path exists in the SYSTEM PATH variable

# Define the expected folder name pattern
$expectedPathPattern = "Microsoft.DesktopAppInstaller_"

# Get the SYSTEM PATH variable
$systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

# Check if any path in SYSTEM PATH matches the expected AppInstaller folder
$match = $systemPath -split ';' | Where-Object {
    $_ -like "*$expectedPathPattern*"
}

# Return success if match is found
if ($match) {
    Write-Output "Detected: $match"
    exit 0  # Detection success
} else {
    Write-Output "Not detected: Winget path not in SYSTEM PATH."
    exit 1  # Detection failed
}
