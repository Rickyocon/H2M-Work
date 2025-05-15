# Test if PowerShell 7 is installed
$pwshInstalled = Test-Path "C:\Program Files\PowerShell\7\pwsh.exe"
if ($pwshInstalled) {
    Write-Host "PowerShell 7 is installed."
} else {
    Write-Host "PowerShell 7 is NOT installed."
}

# Test if Winget is recognized (both user and system contexts)
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetPath) {
    Write-Host "Winget is installed and recognized."
} else {
    Write-Host "Winget is NOT installed or recognized."
}

# Test if the PATH includes the necessary directories
$envPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($envPath -like "*WindowsApps*") {
    Write-Host "PATH is correctly configured for SYSTEM context."
} else {
    Write-Host "PATH is NOT correctly configured for SYSTEM context."
}
