<#
PURPOSE
-------
One-time, interactive script to manually set extensionAttribute1 on a
single Entra ID device.

The user is prompted at runtime for:
- Device name
- extensionAttribute1 value

No editing or copying of the script is required.

USAGE
-----
Run the script in PowerShell 7 (pwsh) and follow the prompts.
#>

#NOTE: You must connect to Microsoft Grpaph First
# you must run this in your terminal first : Connect-MgGraph -Scopes Device.ReadWrite.All,DeviceManagementManagedDevices.Read.All
# youll be promted to sign in, use your admin account

# -------------------------
# PROMPT FOR INPUT
# -------------------------
$DeviceName = Read-Host "Enter the device name (As seen in entra)"
$extensionAttribute1 = Read-Host "Enter extensionAttribute1 value (example: NYC, Melville)"

# -------------------------
# BASIC SAFETY CHECK
# -------------------------
if (-not $DeviceName -or -not $extensionAttribute1) {
    throw "Device name and extensionAttribute1 value are required."
}

# -------------------------
# FIND INTUNE DEVICE
# -------------------------
$md = Get-MgDeviceManagementManagedDevice `
  -Filter "deviceName eq '$DeviceName'" -All |
  Sort-Object lastSyncDateTime -Descending |
  Select-Object -First 1

if (-not $md) {
    throw "No Intune-managed device found with name '$DeviceName'."
}

# -------------------------
# RESOLVE ENTRA DEVICE
# -------------------------
$entra = Get-MgDevice `
  -Filter "deviceId eq '$($md.azureADDeviceId)'" -All |
  Select-Object -First 1

if (-not $entra) {
    throw "Failed to resolve Entra ID device for '$DeviceName'."
}

# -------------------------
# UPDATE ATTRIBUTE
# -------------------------
Update-MgDevice -DeviceId $entra.Id -BodyParameter @{
    extensionAttributes = @{
        extensionAttribute1 = $extensionAttribute1
    }
}

Write-Host "SUCCESS: '$DeviceName' set to extensionAttribute1 = '$extensionAttribute1'" -ForegroundColor Green