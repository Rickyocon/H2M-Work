#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Collects the Autopilot hardware hash from the local machine and uploads
    a single-row CSV to a SharePoint document library via Microsoft Graph.

.DESCRIPTION
    Designed to be deployed as an Intune Platform Script (run as SYSTEM).
    No interactive prompts — fill in the configuration block at the top before
    deploying. Each device uploads its own file named <ComputerName>.csv.
    Use Merge-AutopilotHashes.ps1 on your admin machine to consolidate them.

.NOTES
    Prerequisites:
      1. Entra ID app registration with application permission Sites.ReadWrite.All
         (grant admin consent after adding the permission)
      2. A client secret created for the app
      3. The SharePoint document library already exists
         (create the optional subfolder too if using FolderPath)
#>

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
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
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

function Get-SiteId {
    param([hashtable]$Headers)
    # Strip scheme, split host from path  e.g. contoso.sharepoint.com  /sites/IT
    $noScheme = $SharePointSiteUrl -replace '^https://', ''
    $host_, $sitePath = $noScheme -split '/', 2
    $response = Invoke-RestMethod -Headers $Headers -ErrorAction Stop `
        -Uri "https://graph.microsoft.com/v1.0/sites/${host_}:/${sitePath}"
    return $response.id
}

function Get-DriveId {
    param([hashtable]$Headers, [string]$SiteId)
    $response = Invoke-RestMethod -Headers $Headers -ErrorAction Stop `
        -Uri "https://graph.microsoft.com/v1.0/sites/$SiteId/drives"
    $drive = $response.value | Where-Object { $_.name -eq $LibraryName }
    if (-not $drive) {
        $available = ($response.value.name) -join ', '
        throw "Library '$LibraryName' not found. Available libraries: $available"
    }
    return $drive.id
}

#endregion

#region ── Collect hardware hash ────────────────────────────────────────────────

Write-Log "Collecting hardware hash from local WMI..."

try {
    $serial = (Get-WmiObject -Class Win32_BIOS -ErrorAction Stop).SerialNumber.Trim()

    $oa3 = Get-WmiObject -Namespace root/cimv2/mdm/dmmap `
                         -Class MDM_DevDetail_Ext01 `
                         -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" `
                         -ErrorAction Stop
    $hwHash = $oa3.DeviceHardwareData

    if (-not $hwHash) { throw "Hardware hash was empty." }

    Write-Log "Hash collected. Serial: $serial  Computer: $env:COMPUTERNAME"
}
catch {
    Write-Log "Failed to collect hardware hash: $_" -Level Error
    exit 1
}

#endregion

#region ── Build CSV payload ─────────────────────────────────────────────────────

$row = [PSCustomObject]@{
    'Device Serial Number' = $serial
    'Windows Product ID'   = ''
    'Hardware Hash'        = $hwHash
    'Group Tag'            = 'Windows'
    'Assigned User'        = ''
}

# ConvertTo-Csv handles quoting/escaping correctly
$csvBytes = [System.Text.Encoding]::UTF8.GetBytes(
    ($row | ConvertTo-Csv -NoTypeInformation | Out-String)
)

$fileName = "$($env:COMPUTERNAME).csv"

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

#region ── Resolve SharePoint site and library ──────────────────────────────────

try {
    Write-Log "Resolving SharePoint site..."
    $siteId = Get-SiteId -Headers $headers

    Write-Log "Resolving document library '$LibraryName'..."
    $driveId = Get-DriveId -Headers $headers -SiteId $siteId
}
catch {
    Write-Log "SharePoint setup error: $_" -Level Error
    exit 1
}

#endregion

#region ── Upload CSV ────────────────────────────────────────────────────────────

$uploadPath = if ($FolderPath) { "$FolderPath/$fileName" } else { $fileName }

Write-Log "Uploading '$fileName' to '$LibraryName/$uploadPath'..."
try {
    Invoke-RestMethod -Method Put -Headers $headers -ErrorAction Stop `
        -Uri "https://graph.microsoft.com/v1.0/drives/$driveId/root:/$uploadPath`:/content" `
        -ContentType 'text/csv' `
        -Body $csvBytes | Out-Null

    Write-Log "Upload complete."
}
catch {
    Write-Log "Upload failed: $_" -Level Error
    exit 1
}

#endregion
