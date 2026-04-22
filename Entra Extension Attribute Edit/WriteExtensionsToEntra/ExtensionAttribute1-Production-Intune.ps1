<#
PRODUCTION (PowerShell 7): Write Entra device extensionAttribute1 using OU->Tag mapping,
and guarantee we update the correct Entra device when duplicates exist by targeting the Intune-managed device.

Logic:
1) AD computer -> OU name (first OU=...)
2) OU name -> Tag (Common/Spares/etc.)
3) Find Intune managed device by deviceName
4) Use managedDevice.azureADDeviceId to find the Entra device object
5) Update extensionAttributes.extensionAttribute1

Scopes needed:
- Device.ReadWrite.All
- DeviceManagementManagedDevices.Read.All
#>



# -------------------------
# Require PowerShell 7+
# !!!!!!!!!!!you must run this in your terminal first : Connect-MgGraph -Scopes Device.ReadWrite.All,DeviceManagementManagedDevices.Read.All
# youll be promted to sign in, use your admin account
# -------------------------
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw "Run this script in PowerShell 7 (pwsh)."
}

# -------------------------
# CONFIG
# -------------------------
$SearchBaseOU   = "CHNAGE THIS TO YOUR TARGET OU"
$OnlyEnabled    = $true
$AttributeName  = "extensionAttribute1"

$OuToTagMap = @{
    "Dept 1100 Exec." = "Melville"
    "Dept 1200 HR" = "Melville"
    "Dept 1300 Marketing" = "Melville"
    "Dept 1400 Finance" = "Melville"
    "Dept 1500 IT" = "Melville"
    "Dept 1600 Legal" = "Melville"
    "Dept 1700 Facilities" = "Melville"
    "Dept 1800 Core" = "Melville"
    "Dept 2000 Electrical" = "Melville"
    "Dept 3000 Arch" = "Melville"
    "Dept 4000 Water" = "Melville"
    "Dept 6000 Environmental" = "Melville"
    "Dept 7000 Civil - Survey" = "Melville"
    "Dept 8000 Inspector Field" = "Melville"
}

# If Intune record isn't found, do you want fallback to Hybrid joined object?
$FallbackToHybridIfNoIntune = $false

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$CsvPath   = Join-Path $env:USERPROFILE "Downloads\EntraDeviceExtAttr_Write_$Timestamp.csv"

# -------------------------
# FUNCTIONS
# -------------------------
function Get-FirstOuFromDn {
    param([Parameter(Mandatory)][string]$DN)
    $m = [regex]::Match($DN, "OU=([^,]+)")
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Get-TagForOu {
    param([Parameter(Mandatory)][string]$OuName)
    if ($OuToTagMap.ContainsKey($OuName)) { return $OuToTagMap[$OuName] }
    return $null
}

# -------------------------
# MODULES
# -------------------------
Import-Module ActiveDirectory -ErrorAction Stop
Import-Module Microsoft.Graph -ErrorAction Stop

# -------------------------
# GRAPH AUTH (WRITE + Intune read)
# -------------------------
Connect-MgGraph -Scopes @(
    "Device.ReadWrite.All",
    "DeviceManagementManagedDevices.Read.All"
) | Out-Null

# -------------------------
# GET AD COMPUTERS
# -------------------------
Write-Host "`nReading AD computers from:`n$SearchBaseOU`n"

$adComputers = Get-ADComputer -SearchBase $SearchBaseOU -Filter * -Properties ObjectGuid, DistinguishedName, Enabled |
    Where-Object { if ($OnlyEnabled) { $_.Enabled } else { $true } }

Write-Host "Found $($adComputers.Count) AD computers.`n"

# -------------------------
# PROCESS + UPDATE
# -------------------------
$results = foreach ($c in $adComputers) {

    Write-Host "Processing $($c.Name)..." -ForegroundColor DarkGray

    $ouName = Get-FirstOuFromDn -DN $c.DistinguishedName
    $tag    = if ($ouName) { Get-TagForOu -OuName $ouName } else { $null }

    if (-not $ouName) {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $null
            TargetType    = $null
            TargetDevice  = $null
            TargetDeviceId= $null
            CurrentValue  = $null
            ProposedValue = $null
            Status        = "SKIP: no OU parsed"
            Error         = $null
        }
        continue
    }

    if (-not $tag) {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $null
            TargetDevice  = $null
            TargetDeviceId= $null
            CurrentValue  = $null
            ProposedValue = $null
            Status        = "SKIP: OU not mapped"
            Error         = $null
        }
        continue
    }

    # ---------- Prefer Intune-managed device to avoid Entra duplicates ----------
    $managed = $null
    try {
        # Filter is supported, but some tenants can be picky; keep it simple.
        # If you have many devices with same name, you can add additional checks (see notes below).
        $managed = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($c.Name)'" -All |
            Sort-Object lastSyncDateTime -Descending |
            Select-Object -First 1
    } catch {
        $managed = $null
    }

    $entraTarget = $null
    $targetType  = $null

    if ($managed -and $managed.azureADDeviceId) {
        $targetType = "IntuneManaged"
        $entraTarget = Get-MgDevice -Filter "deviceId eq '$($managed.azureADDeviceId)'" -All |
            Select-Object -First 1
    }

    # Optional fallback: Hybrid joined object (ServerAd) via AD objectGuid -> deviceId
    if (-not $entraTarget -and $FallbackToHybridIfNoIntune) {
        $targetType = "HybridFallback"
        $entraTarget = Get-MgDevice -Filter "deviceId eq '$($c.ObjectGuid.Guid)'" -All |
            Where-Object { $_.trustType -eq "ServerAd" } |
            Select-Object -First 1
    }

    if (-not $entraTarget) {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $targetType
            TargetDevice  = $null
            TargetDeviceId= $null
            CurrentValue  = $null
            ProposedValue = $tag
            Status        = "MISSING: no target Entra device"
            Error         = $null
        }
        continue
    }

    # Read current extension attribute
    $full = $null
    $currentValue = $null
    try {
        $full = Get-MgDevice -DeviceId $entraTarget.Id -Property "displayName,deviceId,trustType,extensionAttributes"
        $currentValue = $full.extensionAttributes.$AttributeName
    } catch {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $targetType
            TargetDevice  = $entraTarget.DisplayName
            TargetDeviceId= $entraTarget.DeviceId
            CurrentValue  = $null
            ProposedValue = $tag
            Status        = "ERROR: read failed"
            Error         = $_.Exception.Message
        }
        continue
    }

    if ($currentValue -eq $tag) {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $targetType
            TargetDevice  = $full.displayName
            TargetDeviceId= $full.deviceId
            CurrentValue  = $currentValue
            ProposedValue = $tag
            Status        = "NOCHANGE"
            Error         = $null
        }
        continue
    }

    # Update
    $body = @{
        extensionAttributes = @{
            $AttributeName = $tag
        }
    }

    try {
        Update-MgDevice -DeviceId $entraTarget.Id -BodyParameter $body -ErrorAction Stop
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $targetType
            TargetDevice  = $full.displayName
            TargetDeviceId= $full.deviceId
            CurrentValue  = $currentValue
            ProposedValue = $tag
            Status        = "UPDATED"
            Error         = $null
        }
    } catch {
        [pscustomobject]@{
            ADComputer    = $c.Name
            SourceOU      = $ouName
            TargetType    = $targetType
            TargetDevice  = $full.displayName
            TargetDeviceId= $full.deviceId
            CurrentValue  = $currentValue
            ProposedValue = $tag
            Status        = "ERROR: update failed"
            Error         = $_.Exception.Message
        }
    }
}

# -------------------------
# OUTPUT + LOG
# -------------------------
Write-Host "SUMMARY"
$results | Group-Object Status | Sort-Object Name | Format-Table Count, Name -AutoSize

Write-Host "`nUPDATED (first 500)"
$results | Where-Object Status -eq "UPDATED" | Select-Object -First 500 |
    Format-Table ADComputer, TargetType, TargetDevice, CurrentValue, ProposedValue -AutoSize

Write-Host "`nMISSING/ERROR (first 500)"
$results | Where-Object { $_.Status -like "MISSING*" -or $_.Status -like "ERROR*" } | Select-Object -First 500 |
    Format-Table ADComputer, TargetType, SourceOU, ProposedValue, Status, Error -AutoSize

$results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Force
Write-Host "`nCSV audit exported to:`n$CsvPath"

Disconnect-MgGraph | Out-Null
