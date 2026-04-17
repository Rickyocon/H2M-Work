Import-Module ActiveDirectory

# Define target OU
$TargetOU = "OU=Dept 1500 IT,OU=Melville,OU=Workstations,OU=Offices,DC=h2m,DC=com"

# Get all computer objects in the OU
$Computers = Get-ADComputer -SearchBase $TargetOU -Filter * -Properties extensionAttribute1

foreach ($Computer in $Computers) {

    Set-ADComputer `
        -Identity $Computer.DistinguishedName `
        -Replace @{extensionAttribute2 = "IT"}

    Write-Host "Updated:" $Computer.Name
}
