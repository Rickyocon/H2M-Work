Import-Module ActiveDirectory

# -----------------------------
# OFFICE DEFINITIONS
# -----------------------------
$Offices = @{
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"
    "Example"      = "OU=Example,OU=Workstations,OU=Entra Synced,DC=YourDC,DC=com"

    
}

# -----------------------------
# USER SELECTION
# -----------------------------
Write-Host ""
Write-Host "Select an office to AUDIT:" -ForegroundColor Cyan

$indexMap = @{}
$i = 1
foreach ($office in $Offices.Keys | Sort-Object) {
    Write-Host "[$i] $office"
    $indexMap[$i] = $office
    $i++
}

$selection = Read-Host "`nEnter number"
if (-not $indexMap.ContainsKey([int]$selection)) {
    Write-Error "Invalid selection. Exiting."
    return
}

$OfficeName = $indexMap[[int]$selection]
$SearchBase = $Offices[$OfficeName]

Write-Host ""
Write-Host "Auditing Office: $OfficeName" -ForegroundColor Green
Write-Host "OU Path: $SearchBase" -ForegroundColor DarkGray
Write-Host ""

# -----------------------------
# DRY-RUN AUDIT
# -----------------------------
$devicesNeedingUpdate = Get-ADComputer `
    -SearchBase $SearchBase `
    -Filter * `
    -Properties extensionAttribute1 |
    Where-Object {
        $_.extensionAttribute1 -ne $OfficeName
    }

if (-not $devicesNeedingUpdate) {
    Write-Host "All devices are correctly tagged." -ForegroundColor Green
    return
}

Write-Host "DRY RUN - Devices missing or incorrect extensionAttribute1:" -ForegroundColor Yellow
$devicesNeedingUpdate |
    Select-Object Name, extensionAttribute1 |
    Format-Table -AutoSize

# -----------------------------
# CONFIRMATION
# -----------------------------
Write-Host ""
$confirm = Read-Host "Apply updates to these devices? (Y/N)"

if ($confirm -notmatch '^[Yy]$') {
    Write-Host "No changes made." -ForegroundColor Cyan
    return
}

# -----------------------------
# APPLY CHANGES
# -----------------------------
Write-Host ""
Write-Host "Applying updates..." -ForegroundColor Yellow

foreach ($device in $devicesNeedingUpdate) {
    Set-ADComputer $device `
        -Replace @{ extensionAttribute1 = $OfficeName }

    Write-Host "Updated: $($device.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Completed. Updated $($devicesNeedingUpdate.Count) devices." -ForegroundColor Green