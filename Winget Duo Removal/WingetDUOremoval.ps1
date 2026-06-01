$localLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetDuoRemoval.log"
$networkRoot = "\\app-server\APPS\Winget\Duo-Removal-Logs"
$userName = $env:USERNAME
$userFolder = Join-Path $networkRoot $userName
$networkLog = Join-Path $userFolder "WingetDuoRemoval.log"

Remove-Item $localLog -Force -ErrorAction SilentlyContinue
Start-Transcript -Path $localLog -Append

# ----------------------------------------------------------
# Resolve winget.exe path (SYSTEM safe)
# ----------------------------------------------------------

$wingetDir = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" |
    Sort-Object -Property Path |
    Select-Object -Last 1

if (-not $wingetDir) {
    Write-Output "ERROR: Winget package directory not found."
    Stop-Transcript
    exit 1
}

$wingetExe = Join-Path $wingetDir.Path "winget.exe"

if (-not (Test-Path $wingetExe)) {
    Write-Output "ERROR: winget.exe not found at expected location: $wingetExe"
    Stop-Transcript
    exit 1
}

Write-Output "Using winget path: $wingetExe"

# ----------------------------------------------------------
# Get installed packages
# ----------------------------------------------------------

Write-Output "Retrieving installed packages using winget list..."

$listRaw = & $wingetExe list --source winget --accept-source-agreements 2>$null

if (-not $listRaw) {
    Write-Output "Failed to retrieve installed package list."
    Stop-Transcript
    goto CopyLog
}

# Split into lines
$listLines = $listRaw -split "`n" | Select-Object -Skip 1   # skip header row

# ----------------------------------------------------------
# Identify Duo packages (robust extraction of Id only)
# ----------------------------------------------------------
$duoPackages = @()

foreach ($line in $listLines) {
    $trim = $line.Trim()
    if ($trim -eq "" -or $trim -match '^-{3,}$') { continue }

    # Try to split columns (Name, Id, Version, Source)
    $parts = $trim -split "\s{2,}"
    $pkgName = if ($parts.Count -ge 1) { $parts[0].Trim() } else { "" }
    $maybeId = if ($parts.Count -ge 2) { $parts[1].Trim() } else { "" }

    # If the second column contains both Id and Version, take the first token
    if ($maybeId -match '\s') { $maybeId = $maybeId.Split()[0] }

    # Try to extract an Id-like token (prefer DuoSecurity.* if present)
    $m = [regex]::Match($trim, '(?i)\b(DuoSecurity\.[A-Za-z0-9_.-]+)\b')
    if (-not $m.Success) {
        # fallback: any Id-like token with dot (e.g. Publisher.Package)
        $m = [regex]::Match($trim, '\b([A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+)\b')
    }
    if ($m.Success) {
        $pkgId = $m.Groups[1].Value
    } elseif ($maybeId) {
        $pkgId = $maybeId
    } else {
        $pkgId = $null
    }

    if (($pkgId -and $pkgId -match '(?i)duo') -or ($pkgName -and $pkgName -match '(?i)duo')) {
        $entry = @{ Name = $pkgName; Id = $pkgId }
        $duoPackages += $entry
    }
}

if (-not $duoPackages -or $duoPackages.Count -eq 0) {
    Write-Output "No DuoSecurity packages detected for removal."
    Stop-Transcript
    goto CopyLog
}

Write-Output "DuoSecurity packages detected for removal:"
$duoPackages | ForEach-Object {
    if ($_.Id) { Write-Output " - Id: $($_.Id)  Name: $($_.Name)" } else { Write-Output " - Name: $($_.Name) (no Id detected)" }
}

# ----------------------------------------------------------
# Uninstall Duo packages (try by Id, then fallback to Name)
# ----------------------------------------------------------
foreach ($pkg in $duoPackages) {
    $didSucceed = $false

    if ($pkg.Id) {
        $targetDisplay = "Id: $($pkg.Id)"
        Write-Output "Uninstalling $($pkg.Id) (by id)..."
        & $wingetExe remove --id $pkg.Id --silent --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { $didSucceed = $true }
    }

    if (-not $didSucceed -and $pkg.Name) {
        $targetDisplay = "Name: $($pkg.Name)"
        Write-Output "Uninstalling $($pkg.Name) (by name)..."
        & $wingetExe uninstall --name "$($pkg.Name)" --silent --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { $didSucceed = $true }
    }

    if ($didSucceed) {
        Write-Output "Successfully uninstalled $targetDisplay."
    } else {
        Write-Output "ERROR uninstalling $targetDisplay (exit code: $LASTEXITCODE). Last winget output may include a reason above."
    }
}
Write-Output "Duo removal process complete."

Stop-Transcript

# ----------------------------------------------------------
# Copy transcript to network share
# ----------------------------------------------------------

CopyLog:
try {
    if (-not (Test-Path $userFolder)) {
        New-Item -Path $userFolder -ItemType Directory -Force | Out-Null
    }

    Copy-Item -Path $localLog -Destination $networkLog -Force
    Write-Output "Transcript successfully copied to network share: $networkLog"
} catch {
    Write-Output "Failed to copy transcript to network share: $_"
}
