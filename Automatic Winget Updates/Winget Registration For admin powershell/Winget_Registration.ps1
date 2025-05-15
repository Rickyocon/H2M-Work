# Define paths
$SupportPath = "C:\Support"
$AppServerPath = "\\app-server\apps\_Intune Applications\1 Source\PowerShell\WingetRegistration"

Remove-Item "$SupportPath\WingetRegistrationDetection.txt" -Force -ErrorAction SilentlyContinue

# Create detection file
New-Item -Path "$SupportPath\WingetRegistrationDetection.txt" -ItemType File -Force | Out-Null


Copy-Item -Path "$AppServerPath\Winget_Registration.ps1" -Destination "$SupportPath\Winget_Registration.ps1" -Force


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
