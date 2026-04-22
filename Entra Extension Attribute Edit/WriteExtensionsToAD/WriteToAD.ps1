Import-Module ActiveDirectory

# Toggle Dry Run
$DryRun = $true

if ($DryRun) {
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Yellow
}

# Parent OU (includes all sub-OUs)
$TargetOU = "CHNAGE THIS TO YOUR TARGET OU"   # update if needed

Get-ADComputer `
    -SearchBase $TargetOU `
    -Filter * `
    -Properties extensionAttribute1 |
ForEach-Object {

    # Skip if already set correctly
    if ($_.extensionAttribute1 -eq "CHNAGE THIS TO WHAT YOU WANT IT TO BE") {
        Write-Host "Skipping (already set): $($_.Name)" -ForegroundColor Cyan
        return
    }

    if ($DryRun) {
        Write-Host "Would update: $($_.Name)" -ForegroundColor Yellow
    }
    else {
        Set-ADComputer `
            -Identity $_.DistinguishedName `
            -Replace @{ extensionAttribute1 = "CHNAGE THIS TO WHAT YOU WANT IT TO BE" }

        Write-Host "Updated: $($_.Name)" -ForegroundColor Green
    }
}
