# Run this in PowerShell as Administrator

Write-Host "===== Autopilot Hash Collection Test =====" -ForegroundColor Cyan

try {
    Write-Host "Collecting serial number..."
    $serial = (Get-WmiObject -Class Win32_BIOS -ErrorAction Stop).SerialNumber.Trim()

    Write-Host "Collecting hardware hash..."
    $oa3 = Get-WmiObject -Namespace root/cimv2/mdm/dmmap `
                         -Class MDM_DevDetail_Ext01 `
                         -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
                         -ErrorAction Stop

    $hwHash = $oa3.DeviceHardwareData

    if (-not $hwHash) {
        throw "Hardware hash came back empty."
    }

    Write-Host "SUCCESS: Hash collected" -ForegroundColor Green
    Write-Host "Serial: $serial"
}
catch {
    Write-Host "ERROR: Failed to collect hardware hash" -ForegroundColor Red
    Write-Host $_
    exit 1
}

# Build output folder
$outputPath = "\\app-server\APPS\AutoPilot\Device Hashes"
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}


# Create CSV row
$row = [PSCustomObject]@{
    'Device Serial Number' = $serial
    'Windows Product ID'   = ''
    'Hardware Hash'        = $hwHash
    'Group Tag'            = 'WIN-OS'
    'Assigned User'        = ''
}


# Save CSV
$outputPath = New-Item -ItemType Directory -Path $outputPath\"$env:COMPUTERNAME"
$fileName = "$env:COMPUTERNAME.csv"
$fullPath = Join-Path $outputPath $fileName

$row | Export-Csv -Path $fullPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "CSV successfully saved to:" -ForegroundColor Green
Write-Host $fullPath
Write-Host "========================================="
