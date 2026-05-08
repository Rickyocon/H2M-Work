#Logic:
#1) AD computer -> OU name (first OU=...)
#2) OU name -> Tag (Common/Spares/etc.)
#3) Find Intune managed device by deviceName
#4) Use managedDevice.azureADDeviceId to find the Entra device object
#5) Update extensionAttributes.extensionAttribute1

#Scopes needed:
#- Device.ReadWrite.All
#- DeviceManagementManagedDevices.Read.All

# -------------------------
# Require PowerShell 7+
# you must run this in your terminal first : Connect-MgGraph -Scopes Device.ReadWrite.All,DeviceManagementManagedDevices.Read.All
# youll be promted to sign in, use your admin account
# -------------------------


# =============================
# STARTUP
# =============================
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "AD → Entra Device Attribute Sync" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# =============================
# REQUIRE POWERSHELL 7
# =============================
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw "Run this script in PowerShell 7 (pwsh)."
}

# =============================
# MODULES
# =============================
Write-Host "Loading modules..." -ForegroundColor Cyan
Import-Module ActiveDirectory -ErrorAction Stop
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
Write-Host "Modules loaded successfully." -ForegroundColor Green
Write-Host ""

# =============================
# RUN MODE SELECTION
# =============================
Write-Host "Select run mode:" -ForegroundColor Cyan
Write-Host "[1] Dry Run (no Entra changes)"
Write-Host "[2] Real Run (write changes to Entra)"

$mode = Read-Host "Enter number"

switch ($mode) {
    "1" {
        $DryRun = $true
        Write-Host "`nMODE: DRY RUN" -ForegroundColor Yellow
    }
    "2" {
        $DryRun = $false
        Write-Host "`nMODE: REAL RUN" -ForegroundColor Red

        $confirm = Read-Host "Are you sure you want to WRITE changes to Entra? (YES to continue)"
        if ($confirm -ne "YES") {
            Write-Host "Aborted by user." -ForegroundColor Yellow
            return
        }
    }
    default {
        throw "Invalid selection."
    }
}

Write-Host ""

# =============================
# CONFIG
# =============================
$SearchBaseOU = "OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
$OnlyEnabled = $true
$AttrName    = "extensionAttribute1"

$OfficeTagMap = @{
    "Boca Raton"        = "Boca"
    "Central Jersey"    = "Central Jersey"
    "Connecticut"       = "Connecticut"
    "Interns"           = "Intern"
    "Melville"          = "Melville"
    "NYC"               = "NYC"
    "Parsippany"        = "Parsippany"
    "Remote"            = "Remote"
    "Suffern"           = "Suffern"
    "Troy"              = "Troy"
    "Westchester"       = "Westchester"
    "_Common Machines"  = "Common"
    "_Spares"           = "Spare"
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$CsvPath   = Join-Path $env:USERPROFILE "Downloads\Entra_ExtAttr_Sync_$Timestamp.csv"

# =============================
# FUNCTIONS
# =============================
function Get-OfficeFromDn {
    param([string]$DN)

    $ous = ($DN -split ',') |
        Where-Object { $_ -like 'OU=*' } |
        ForEach-Object { $_ -replace '^OU=' }

    if (-not $ous) { return $null }

    if ($ous.Count -ge 2 -and $ous[1] -eq 'Melville') {
        return 'Melville'
    }

    return $ous[0]
}

# =============================
# OFFICE SELECTION
# =============================
Write-Host "Select office to process:" -ForegroundColor Cyan
Write-Host ""

$menu = @{}
$i = 1
foreach ($office in $OfficeTagMap.Keys | Sort-Object) {
    Write-Host "[$i] $office"
    $menu[$i] = $office
    $i++
}

$selection = Read-Host "`nEnter number"
if (-not $menu.ContainsKey([int]$selection)) {
    throw "Invalid selection."
}

$SelectedOffice = $menu[[int]$selection]
$TargetTag      = $OfficeTagMap[$SelectedOffice]

Write-Host ""
Write-Host "Office selected : $SelectedOffice" -ForegroundColor Green
Write-Host "Target Entra tag: $TargetTag" -ForegroundColor Green
Write-Host ""

# =============================
# GET AD COMPUTERS
# =============================
Write-Host "Querying Active Directory..." -ForegroundColor Cyan

$adComputers = Get-ADComputer `
    -SearchBase $SearchBaseOU `
    -Filter * `
    -Properties DistinguishedName,ObjectGuid,Enabled |
    Where-Object { if ($OnlyEnabled) { $_.Enabled } else { $true } }

Write-Host "Found $($adComputers.Count) AD computers total." -ForegroundColor Green
Write-Host ""

# =============================
# PROCESS DEVICES
# =============================
$results = @()
$deviceIndex = 1

foreach ($c in $adComputers) {

    $office = Get-OfficeFromDn $c.DistinguishedName
    if ($office -ne $SelectedOffice) { continue }

    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[$deviceIndex] Processing $($c.Name)" -ForegroundColor Cyan

    Write-Host "Looking up Intune device..." -ForegroundColor Yellow
    $managed = Get-MgDeviceManagementManagedDevice `
        -Filter "deviceName eq '$($c.Name)'" `
        -Top 5 |
        Sort-Object lastSyncDateTime -Descending |
        Select-Object -First 1

    if (-not $managed -or -not $managed.azureADDeviceId) {
        Write-Host "No Intune device found. Skipping." -ForegroundColor DarkYellow
        $deviceIndex++
        continue
    }

    $entra = Get-MgDevice -Filter "deviceId eq '$($managed.azureADDeviceId)'" -Top 1
    $full  = Get-MgDevice -DeviceId $entra.Id -Property "extensionAttributes"
    $current = $full.extensionAttributes.$AttrName

    Write-Host "Current Entra value: $current"
    Write-Host "Expected value     : $TargetTag"

    if ($current -eq $TargetTag) {
        Write-Host "NO CHANGE REQUIRED" -ForegroundColor Green
        $results += [pscustomobject]@{
            Device=$c.Name; Status="NOCHANGE"; Current=$current; Target=$TargetTag
        }
        $deviceIndex++
        continue
    }

    if ($DryRun) {
        Write-Host "DRY RUN: Would update Entra value." -ForegroundColor Yellow
        $status = "WOULD-UPDATE"
    }
    else {
        Write-Host "Updating Entra..." -ForegroundColor Red
        Update-MgDevice -DeviceId $entra.Id -BodyParameter @{
            extensionAttributes = @{ extensionAttribute1 = $TargetTag }
        }
        Write-Host "Update successful." -ForegroundColor Green
        $status = "UPDATED"
    }

    $results += [pscustomobject]@{
        Device=$c.Name; Status=$status; Current=$current; Target=$TargetTag
    }

    $deviceIndex++
}

# =============================
# SUMMARY
# =============================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

$results | Group-Object Status | Format-Table Count, Name -AutoSize
$results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Force

Write-Host ""
Write-Host "CSV exported to:" -ForegroundColor Green
Write-Host $CsvPath

Write-Host ""
Write-Host "Script complete." -ForegroundColor Cyan