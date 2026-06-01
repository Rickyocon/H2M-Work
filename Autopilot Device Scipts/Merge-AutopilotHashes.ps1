<#
.SYNOPSIS
    Downloads all per-device Autopilot hash CSVs from SharePoint and merges
    them into a single Intune-ready import CSV.

.DESCRIPTION
    Run this on your admin machine after devices have uploaded their individual
    hash files via Collect-AutopilotHash-Local.ps1.  Downloads every .csv from
    the configured SharePoint library/folder, merges the rows, and writes one
    combined CSV ready for import into Intune > Windows Autopilot > Import.

.PARAMETER OutputPath
    Where to write the merged Intune import CSV.
    Default: C:\AutopilotHashes\AutopilotDevices.csv

.EXAMPLE
    .\Merge-AutopilotHashes.ps1

.EXAMPLE
    .\Merge-AutopilotHashes.ps1 -OutputPath "C:\Temp\AutopilotImport.csv"
#>

[CmdletBinding()]
param(
    [string]$OutputPath = "C:\AutopilotHashes\AutopilotDevices.csv"
)

# ── Configuration — fill these in before deploying ──────────────────────────────
$TenantId          = 'ENTER_TENANT_ID'
$ClientId          = 'ENTER_CLIENT_ID'
$ClientSecret      = 'ENTER_CLIENT_SECRET'

# Full URL of the SharePoint site (no trailing slash)
$SharePointSiteUrl = 'https://DOMAIN.sharepoint.com/sites/IT'
# Display name of the document library
$LibraryName       = ''
# Subfolder inside the library — leave as '' to upload to the library root
$FolderPath        = ''
# ────────────────────────────────────────────────────────────────────────────────

#region ── Helpers ──────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [ValidateSet('Info','Warn','Error')]$Level = 'Info')
    $clr = @{ Info = 'Cyan'; Warn = 'Yellow'; Error = 'Red' }[$Level]
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message" -ForegroundColor $clr
}

function Get-GraphToken {
    $response = Invoke-RestMethod -Method Post -ErrorAction Stop `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -ContentType 'application/x-www-form-urlencoded' `
        -Body @{
            grant_type    = 'client_credentials'
            client_id     = $ClientId
            client_secret = $ClientSecret
            scope         = 'https://graph.microsoft.com/.default'
        }
    return $response.access_token
}

function Get-AllPages {
    # Follows @odata.nextLink pages and returns all values
    param([hashtable]$Headers, [string]$Uri)
    $all = [System.Collections.Generic.List[object]]::new()
    do {
        $page = Invoke-RestMethod -Headers $Headers -Uri $Uri -ErrorAction Stop
        $page.value | ForEach-Object { $all.Add($_) }
        $Uri = $page.'@odata.nextLink'
    } while ($Uri)
    return $all
}

#endregion

#region ── Authenticate ─────────────────────────────────────────────────────────

Write-Log "Acquiring Graph token..."
try {
    $token   = Get-GraphToken
    $headers = @{ Authorization = "Bearer $token" }
}
catch {
    Write-Log "Failed to acquire token: $_" -Level Error
    exit 1
}

#endregion

#region ── Resolve site and library ─────────────────────────────────────────────

try {
    Write-Log "Resolving SharePoint site..."
    $noScheme = $SharePointSiteUrl -replace '^https://', ''
    $host_, $sitePath = $noScheme -split '/', 2
    $site   = Invoke-RestMethod -Headers $headers -ErrorAction Stop `
                  -Uri "https://graph.microsoft.com/v1.0/sites/${host_}:/${sitePath}"
    $siteId = $site.id

    Write-Log "Resolving document library '$LibraryName'..."
    $drives = Invoke-RestMethod -Headers $headers -ErrorAction Stop `
                  -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drives"
    $drive  = $drives.value | Where-Object { $_.name -eq $LibraryName }
    if (-not $drive) {
        $available = ($drives.value.name) -join ', '
        throw "Library '$LibraryName' not found. Available: $available"
    }
    $driveId = $drive.id
}
catch {
    Write-Log "SharePoint setup error: $_" -Level Error
    exit 1
}

#endregion

#region ── List CSV files ────────────────────────────────────────────────────────

Write-Log "Listing CSV files in '$LibraryName$(if ($FolderPath) { "/$FolderPath" })'..."

try {
    $listUri = if ($FolderPath) {
        "https://graph.microsoft.com/v1.0/drives/$driveId/root:/$FolderPath`:/children"
    } else {
        "https://graph.microsoft.com/v1.0/drives/$driveId/root/children"
    }

    $allItems = Get-AllPages -Headers $headers -Uri $listUri
    $csvItems = $allItems | Where-Object { $_.name -like '*.csv' }

    if ($csvItems.Count -eq 0) {
        Write-Log "No CSV files found in the library. Have devices run the collection script yet?" -Level Warn
        exit 0
    }

    Write-Log "Found $($csvItems.Count) CSV file(s)."
}
catch {
    Write-Log "Failed to list files: $_" -Level Error
    exit 1
}

#endregion

#region ── Download and merge ────────────────────────────────────────────────────

$merged  = [System.Collections.Generic.List[PSObject]]::new()
$success = 0
$failed  = 0

foreach ($item in $csvItems) {
    try {
        $content = Invoke-RestMethod -Headers $headers -ErrorAction Stop `
                       -Uri "https://graph.microsoft.com/v1.0/drives/$driveId/items/$($item.id)/content"

        # ConvertFrom-Csv handles the quoted/escaped values correctly
        $rows = $content | ConvertFrom-Csv
        foreach ($row in $rows) {
            if ($row.'Hardware Hash') {
                $merged.Add($row)
            }
        }
        $success++
        Write-Log "  [+] $($item.name)"
    }
    catch {
        $failed++
        Write-Log "  [!] $($item.name) — download failed: $_" -Level Warn
    }
}

Write-Log "Merged $($merged.Count) device(s) from $success file(s). $failed file(s) failed."

#endregion

#region ── Write output ──────────────────────────────────────────────────────────

if ($merged.Count -eq 0) {
    Write-Log "No valid rows to write — output CSV not created." -Level Warn
    exit 0
}

$outDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$merged |
    Select-Object 'Device Serial Number','Windows Product ID','Hardware Hash','Group Tag','Assigned User' |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Log "Intune import CSV written: $OutputPath  ($($merged.Count) device(s))"

#endregion

#region ── Summary ──────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Autopilot Hash Merge — Summary"          -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Files found    : $($csvItems.Count)"
Write-Host "  Files merged   : $success" -ForegroundColor Green
Write-Host "  Files failed   : $failed"  -ForegroundColor $(if ($failed) { 'Yellow' } else { 'White' })
Write-Host "  Devices in CSV : $($merged.Count)"
Write-Host ""
Write-Host "  Output → $OutputPath"
Write-Host "══════════════════════════════════════════" -ForegroundColor Cyan

#endregion
