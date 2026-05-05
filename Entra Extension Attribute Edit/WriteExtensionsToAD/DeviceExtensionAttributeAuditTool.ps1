Import-Module ActiveDirectory

# -----------------------------
# OFFICE DEFINITIONS
# -----------------------------
$Offices = @{
    "Boca"           = "OU=Boca Raton,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Central Jersey" = "OU=Central Jersey,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Connecticut"    = "OU=Connecticut,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Common"         = "OU=_Common Machines,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Melville"       = "OU=Melville,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "NYC"            = "OU=NYC,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Parsippany"     = "OU=Parsippany,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Remote"         = "OU=Remote,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Spare"          = "OU=_Spares,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Suffern"        = "OU=Suffern,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Troy"           = "OU=Troy,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Westchester"    = "OU=Westchester,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    "Intern"         = "OU=Interns,OU=Workstations,OU=Entra Synced,DC=h2m,DC=com"
    
}

# Outer loop for multiple changes
do {
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
    continue
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
    Write-Host ""
    continue
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
    Write-Host ""
    continue
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
    
    # Ask if user wants to make another change
    Write-Host ""
    $anotherChange = Read-Host "Would you like to make another change? (Y/N)"
    if($anotherChange -match '^[Nn]$'){break}
    
} while ($anotherChange -match '^[Yy]$' -or $true)

Write-Host ""
Write-Host "Script ended." -ForegroundColor Cyan
