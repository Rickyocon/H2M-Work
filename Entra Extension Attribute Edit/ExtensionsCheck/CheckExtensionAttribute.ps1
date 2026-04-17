# ---- CONFIG ----
$SearchBase = "OU=Users,OU=Entra Synced,DC=h2m,DC=com"

# Timestamp (safe for filenames)
$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Get current user's Downloads folder
$DownloadsPath = Join-Path $env:USERPROFILE "Downloads"

# Build output file path
$OutFile = Join-Path $DownloadsPath "Users_ExtAttr4_$TimeStamp.csv"

# ---- QUERY + EXPORT ----
$Users = Get-ADUser -SearchBase $SearchBase `
    -LDAPFilter "(&(objectCategory=person)(objectClass=user)(extensionAttribute4=*))" `
    -Properties displayName,samAccountName,userPrincipalName,mail,department,extensionAttribute4,enabled

$Users |
Select-Object displayName,samAccountName,userPrincipalName,mail,department,enabled,extensionAttribute4 |
Export-Csv $OutFile -NoTypeInformation -Encoding UTF8

# Output summary
Write-Output "Exported $($Users.Count) users to $OutFile"
