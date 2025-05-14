# Attempt to register the Winget source package (to avoid source errors like 0x8a15000f)
try {
    Write-Output "Attempting to register Winget source package..."
    $manifest = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.Winget.Source_*\AppXManifest.xml"
    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -Verbose
    Write-Output "Winget source package successfully registered."
}
catch {
    Write-Error "Failed to register Winget source package: $_"
}

Start-Sleep -Seconds 30

Write-Output "Pinning Microsoft.Office to prevent auto-upgrade..."
winget pin add --id Microsoft.Office

Write-Output "Checking for available winget upgrades..."
$upgrades = winget upgrade

if ($upgrades -match "No applicable upgrade found") {
    Write-Output "All packages are already up to date."
} else {
    Write-Output "Upgrading all available packages (excluding pinned ones)..."
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Output "Upgrade process complete."
}
