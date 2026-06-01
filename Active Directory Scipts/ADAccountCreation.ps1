<#
.SYNOPSIS
   New-User Creation GUI – collects required fields, generates a password,
   creates a new AD user under OU=_Account Creation,DC=h2m,DC=com, sets location & department attributes,
   assigns baseline & location/department-based group memberships, and allows selecting additional groups via checkboxes.

.NOTES
   Author      : Patrick Joseph
   Run context : PowerShell 5.1+ (64-bit) with RSAT/ActiveDirectory installed
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#──────────────────────────────────────────────────────────────────────────────────────────────
# EDIT THESE <<< CHANGE-ME >>> VALUES to suit your environment
#──────────────────────────────────────────────────────────────────────────────────────────────
$SearchBase = "DC=h2m,DC=com"                          # <<<  AD base (if needed)
$NewUserOU  = "OU=_Account Creation,DC=h2m,DC=com"      # <<<  OU where new accounts live
$UPNSuffix  = "@h2m.com"                               # <<<  UPN suffix
$SMTPSuffix = "@H2M.com"                               # <<<  SMTP suffix

# ─── Define “baseline” groups to assign to every new user ─────────────────────────────────
$GlobalGroups = @(
        "Secure Client VPN"
)

# ─── Define location-specific group memberships ────────────────────────────────────────────
$LocationGroups = @{
    "01 - 538 Melville"     = @("Everyone-538")
    "01 - 290 Melville"     = @("Everyone-290")
    "02 - Parsippany"       = @("Everyone-Parsippany")
    "03 - Troy"             = @("Everyone-Albany")
    "04 - Suffern"          = @("Everyone-Suffern")
    "05 - Purchase"         = @("Everyone-Westchester")
    "06 - Wall"             = @("Everyone-Central-Jersey")
    "07 - New York"         = @("Everyone-NYC")
    "08 - Windsor"          = @("Everyone-Windsor-1563094087")
    "09 - Pembroke Pines"   = @("Everyone-Boca")
    "09 - Boca Raton"       = @("Everyone-Boca")
}

# ─── Define department-specific group memberships ─────────────────────────────────────────
$DeptGroups = @{
    "1100" = @("Dept 1100")
    "1200" = @("Dept 1200")
    "1300" = @("Dept 1300")
    "1400" = @("Dept 1400")
    "1500" = @("Dept 1500")
    "1600" = @("Dept 1600")
    "1700" = @("Dept 1700")
    "1800" = @("Dept 1800")
    "1900" = @("Dept 1900")
    "2200" = @("Dept 2200")
    "2400" = @("Dept 2400")
    "3100" = @("Dept 3100")
    "3200" = @("Dept 3200")
    "4000" = @("Dept 4000")
    "4100" = @("Dept 4100")
    "4300" = @("Dept 4300")
    "4900" = @("Dept 4900")
    "5100" = @("Dept 5100")
    "6100" = @("Dept 6100")
    "6300" = @("Dept 6300")
    "6400" = @("Dept 6400")
    "7000" = @("Dept 7000")
    "7100" = @("Dept 7100")
    "7300" = @("Dept 7300")
    "7400" = @("Dept 7400")
    "8100" = @("Dept 8100")
}

# ─── Define additional groups available via checkboxes ────────────────────────────────────
#  Edit this array to show whichever extra groups you want the user to choose at creation time
$CheckboxGroups = @(
    "Acad Users Group",
    "BIMCAD1",
    "Cadd Users",
    "Civil 3D Users"
)
#──────────────────────────────────────────────────────────────────────────────────────────────

Start-Transcript -Path 'C:\script_logs\UserCreation.log' -Append
Import-Module ActiveDirectory

#──────────────────────────────────────────────────────────────────────────────────────────────
# 1) Define a lookup from the full Office dropdown string → AD location attributes
#──────────────────────────────────────────────────────────────────────────────────────────────
$OfficeLookup = @{

    "01 - 538 Melville" = @{
        streetAddress              = "538 Broad Hollow Road"
        l                          = "Melville"
        st                         = "NY"
        postalCode                 = "11747"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "538 Broad Hollow"
    }

    "01 - 290 Melville" = @{
        streetAddress              = "290 Broad Hollow Road"
        l                          = "Melville"
        st                         = "NY"
        postalCode                 = "11747"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "290 Broad Hollow"
    }

    "02 - Parsippany" = @{
        streetAddress              = "119 Cherry Hill Rd Suite 110"
        l                          = "Parsippany"
        st                         = "NJ"
        postalCode                 = "07054"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Parsippany"
    }

    "03 - Troy" = @{
        streetAddress              = "433 River St, Suite 8002"
        l                          = "Troy"
        st                         = "NY"
        postalCode                 = "12180"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Troy"
    }

    "04 - Suffern" = @{
        streetAddress              = "2 Executive Boulevard, Suite 401"
        l                          = "Suffern"
        st                         = "NY"
        postalCode                 = "10901"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Suffern"
    }

    "05 - Purchase" = @{
        streetAddress              = "2700 Westchester Ave, Suite 415"
        l                          = "Purchase"
        st                         = "NY"
        postalCode                 = "10577"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Westchester"
    }

    "06 - Wall" = @{
        streetAddress              = "4810 Belmar Blvd"
        l                          = "Wall Township"
        st                         = "NJ"
        postalCode                 = "07719"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Central NJ"
    }

    "07 - New York" = @{
        streetAddress              = "230 West 38th St, 14th Floor"
        l                          = "New York"
        st                         = "NY"
        postalCode                 = "10018"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "NYC"
    }

    "08 - Windsor" = @{
        streetAddress              = "360 Bloomfield Ave, Suite 406"
        l                          = "Windsor"
        st                         = "CT"
        postalCode                 = "06095"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Windsor"
    }

    "09 - Pembroke Pines" = @{
        streetAddress              = "880 SW 145th Ave, Suite 106"
        l                          = "Pembroke Pines"
        st                         = "FL"
        postalCode                 = "33027"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Pembroke Pines"
    }

    "10 - Boca Raton" = @{
        streetAddress              = "951 Yamato Rd, Suite 20"
        l                          = "Boca Raton"
        st                         = "FL"
        postalCode                 = "33431"
        co                         = "United States"
        company                    = "H2M"
        physicalDeliveryOfficeName = "Boca"
    }
}

#──────────────────────────────────────────────────────────────────────────────────────────────
function Show-NewUserForm {
    <#
      .SYNOPSIS
          Presents a WinForms dialog to collect:
            • First Name
            • Last Name
            • Employee #
            • Job Title
            • Manager (Username/samAccountName)
            • Office Phone
            • Mobile Phone
            • Office Code   (dropdown: “01 - 538 Melville”, “01 - 290 Melville”, …)
            • Department    (dropdown: “<Name> - <4-digit Code>”)
            • O365 License  (dropdown: “Business Standard” / “E3” / “E5”)
            • Additional Groups (checkboxes)

      .OUTPUTS
          PSCustomObject with properties:
            FirstName, LastName, EmployeeID, JobTitle, ManagerName,
            OfficePhone, MobilePhone, OfficeFull, DeptFull, O365License,
            SelectedGroups
          or $null if user cancels.
    #>

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName Microsoft.VisualBasic

    # ── helper to add aligned Label+TextBox ───────────────────────────────────────────────
    function Add-Row {
        param(
            [string]$Caption,
            [int]   $RowIndex,
            [ref]   $TextBox
        )
        $baseY = 20
        $stepY = 40

        $lbl = New-Object Windows.Forms.Label
        $lbl.Text    = $Caption
        $lbl.Left    = 25
        $lbl.Top     = $baseY + ($RowIndex * $stepY)
        $lbl.AutoSize = $true
        $form.Controls.Add($lbl)

        $tb = New-Object Windows.Forms.TextBox
        $tb.Left   = 150
        $tb.Top    = $lbl.Top - 3
        $tb.Width  = 180
        $form.Controls.Add($tb)

        $TextBox.Value = $tb
    }

    # ── build the WinForms dialog ─────────────────────────────────────────────────────────
    $form = New-Object Windows.Forms.Form
    $form.Text            = 'New User Creation Tool'
    $form.FormBorderStyle = 'FixedToolWindow'
    # increase height to fit checkboxes
    $form.Width           = 600
    $form.Height          = 780
    $form.StartPosition   = 'CenterScreen'

     # Rows 0–6: TextBoxes for FirstName, LastName, EmployeeID, JobTitle, Manager, OfficePhone, MobilePhone
    $txtFirstName   = $null
    $txtLastName    = $null
    $txtEmployeeID  = $null
    $txtJobTitle    = $null
    $txtManager     = $null
    $txtOfficePhone = $null
    $txtMobilePhone = $null

    Add-Row 'First Name:'                       0 ([ref]$txtFirstName)
    Add-Row 'Last Name:'                        1 ([ref]$txtLastName)
    Add-Row 'Employee #:'                       2 ([ref]$txtEmployeeID)
    Add-Row 'Job Title:'                        3 ([ref]$txtJobTitle)
    Add-Row 'Manager (Username):'               4 ([ref]$txtManager)
    Add-Row 'Office Phone:'                     5 ([ref]$txtOfficePhone)
    Add-Row 'Mobile Phone:'                     6 ([ref]$txtMobilePhone)

    # Row 7: Office Code dropdown
    $lblOfficeCode = New-Object Windows.Forms.Label
    $lblOfficeCode.Text    = 'Office Code:'
    $lblOfficeCode.Left    = 25
    $lblOfficeCode.Top     = 20 + (7 * 40)
    $lblOfficeCode.AutoSize = $true
    $form.Controls.Add($lblOfficeCode)

    $cmbOfficeCode = New-Object Windows.Forms.ComboBox
    $cmbOfficeCode.Left          = 150
    $cmbOfficeCode.Top           = $lblOfficeCode.Top - 3
    $cmbOfficeCode.Width         = 300
    $cmbOfficeCode.DropDownStyle = 'DropDownList'

    $officeChoices = @(
        "01 - 538 Melville",
        "01 - 290 Melville",
        "02 - Parsippany",
        "03 - Troy",
        "04 - Suffern",
        "05 - Purchase",
        "06 - Wall",
        "07 - New York",
        "08 - Windsor",
        "09 - Pembroke Pines",
        "09 - Boca Raton"
    )
    foreach ($key in $officeChoices) {
        [void]$cmbOfficeCode.Items.Add($key)
    }
    $cmbOfficeCode.SelectedIndex = 0
    $form.Controls.Add($cmbOfficeCode)

    # Row 8: Department dropdown
    $departmentList = @(
       
        "Mechanical Engineering - 2200",
        "Electrical Engineering - 2400",
        "Plumbing / Fire Protection Engineering - 2300",
        "Architecture Studio - 3100",
        "Architecture Studio - 3300",
        "Architecture Studio - 3500",
        "Structural Engineering Real Estate - 3200",
        "Structural Engineering Municipal - 4200",
        "Water and Wastewater Engineering - 4100",
        "Water and Wastewater Engineering - 4500",
        "Environmental Services - 6100",
        "Civil Engineering - 7100",
        "Survey - 7300",
        "Planning and GIS - 7400",
        "Construction Services - 8100",
        "Coatings Services - 4300",
        "Human Resources - 1200",
        "Marketing - 1300",
        "Finance - 1400",
        "Information Technology - 1500",
        "Risk Management - 1600",
        "Facilities - 1700",
        "Core of Excellence - 1800",
        "Project Management Office - 1810", 
        "Business Development - 1900",
        "Market: Education - 1901",
        "Market: Public Safety - 1905",
        "Market: Energy - 1910",
        "Market: Insurance - 1920",
        "Market: Municipal - 1925",
        "Market: Public Agency - 1930",
        "Market: Real Estate - 1935",
        "Market: Water / Wastewater - 1945",
        "MEP Administration - 2000",        
        "Architecture Administration - 3031",
        "Architecture Administration - 3033",
        "Architecture Administration - 3035",
        "Water and Wastewater Administration - 4000",
        "Environmental Administration - 6000",
        "Civil Administration - 7000",
        "Construction Services Administration - 8000",
        "Office Administration - 0000"    
        
    )

    $lblDept = New-Object Windows.Forms.Label
    $lblDept.Text    = 'Department:'
    $lblDept.Left    = 25
    $lblDept.Top     = 20 + (8 * 40)
    $lblDept.AutoSize = $true
    $form.Controls.Add($lblDept)

    $cmbDepartment = New-Object Windows.Forms.ComboBox
    $cmbDepartment.Left          = 150
    $cmbDepartment.Top           = $lblDept.Top - 3
    $cmbDepartment.Width         = 400
    $cmbDepartment.DropDownStyle = 'DropDownList'
    foreach ($entry in $departmentList) {
        [void]$cmbDepartment.Items.Add($entry)
    }
    $cmbDepartment.SelectedIndex = 0
    $form.Controls.Add($cmbDepartment)

    # Row 9: O365 License dropdown
    $lblO365 = New-Object Windows.Forms.Label
    $lblO365.Text    = 'O365 License Type:'
    $lblO365.Left    = 25
    $lblO365.Top     = 20 + (9 * 40)
    $lblO365.AutoSize = $true
    $form.Controls.Add($lblO365)

    $cmbO365 = New-Object Windows.Forms.ComboBox
    $cmbO365.Left          = 150
    $cmbO365.Top           = $lblO365.Top - 3
    $cmbO365.Width         = 180
    $cmbO365.DropDownStyle = 'DropDownList'
    @("", 'Business Standard', 'E3', 'E5') | ForEach-Object { [void]$cmbO365.Items.Add($_) }
    $cmbO365.SelectedIndex = 2 # Default to E3
    $form.Controls.Add($cmbO365)

    # Row 10: Additional Groups (checkboxes)
    $lblAddGroups = New-Object Windows.Forms.Label
    $lblAddGroups.Text    = 'Additional Groups:'
    $lblAddGroups.Left    = 25
    $lblAddGroups.Top     = 20 + (10 * 40)
    $lblAddGroups.AutoSize = $true
    $form.Controls.Add($lblAddGroups)

    # Create checkboxes for each group in $CheckboxGroups
    $checkboxes = @()
    for ($i = 0; $i -lt $CheckboxGroups.Count; $i++) {
        $cb = New-Object Windows.Forms.CheckBox
        $cb.Text   = $CheckboxGroups[$i]
        $cb.Left   = 150
        $cb.Top    = ($lblAddGroups.Top + 20) + ($i * 30)
        $cb.AutoSize = $true
        $form.Controls.Add($cb)
        $checkboxes += $cb
    }

    # Add OK and Cancel buttons
    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text         = 'OK'
    $btnOK.Width        = 80
    $btnOK.Left         = 380
    $btnOK.Top          = ($lblAddGroups.Top + 20) + ($CheckboxGroups.Count * 30) + 10
    $btnOK.DialogResult = 'OK'
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text         = 'Cancel'
    $btnCancel.Width        = 80
    $btnCancel.Left         = 480
    $btnCancel.Top          = $btnOK.Top
    $btnCancel.DialogResult = 'Cancel'
    $form.Controls.Add($btnCancel)

    # Show the form
    if ($form.ShowDialog() -ne 'OK') {
        return $null
    }

    # Collect checkbox selections
    $selected = @()
    foreach ($cb in $checkboxes) {
        if ($cb.Checked) { $selected += $cb.Text }
    }

    # Harvest inputs
    [pscustomobject]@{
        FirstName      = $txtFirstName.Text.Trim()
        LastName       = $txtLastName.Text.Trim()
        EmployeeID     = $txtEmployeeID.Text.Trim()
        JobTitle       = $txtJobTitle.Text.Trim()
        ManagerName    = $txtManager.Text.Trim()
        OfficePhone    = $txtOfficePhone.Text.Trim()
        MobilePhone    = $txtMobilePhone.Text.Trim()
        OfficeFull     = $cmbOfficeCode.Text
        DeptFull       = $cmbDepartment.Text
        O365License    = $cmbO365.Text
        SelectedGroups = $selected
    }
}
#──────────────────────────────────────────────────────────────────────────────────────────────

# 1. Show the form and get results
$result = Show-NewUserForm
if (-not $result) {
    Write-Host 'Operation cancelled by user.'
    Stop-Transcript
    return
}

# 2. Verify required fields are not blank
foreach ($prop in 'FirstName','LastName','EmployeeID','JobTitle','OfficeFull','DeptFull','O365License') {
    if (-not $result.$prop) {
        Write-Warning "The field '$prop' cannot be empty. Aborting."
        Stop-Transcript
        return
    }
}

# 3. Parse Department → Name vs Code
if ($result.DeptFull -match '^(.*?)\s*-\s*(\d{4})$') {
    $DeptName = $Matches[1].Trim()
    $DeptCode = $Matches[2]
} else {
    $DeptName = $result.DeptFull.Trim()
    $DeptCode = ''
}

# 4. Parse OfficeFull → two-digit OfficeCode (for password)
$officeFull = $result.OfficeFull
if ($officeFull -match '^(\d{2})') {
    $OfficeCode = $Matches[1]
} else {
    $OfficeCode = ''
}

# Build full department string with office code
$DeptFullWithOffice = "$DeptName - $OfficeCode$DeptCode"

# 5. Lookup location attributes by the full string
if ($OfficeLookup.ContainsKey($officeFull)) {
    $locAttrs = $OfficeLookup[$officeFull]
} else {
    Write-Warning "No location info defined for '$officeFull'. Using blank defaults."
    $locAttrs = @{
        streetAddress              = ''
        l                          = ''
        st                         = ''
        postalCode                 = ''
        co                         = ''
        company                    = ''
        physicalDeliveryOfficeName = ''
    }
}

# 6. Build sAMAccountName & display name
$FirstName = $result.FirstName
$LastName  = $result.LastName
$fullName  = "$FirstName $LastName"
$sam = "$($result.FirstName.Substring(0,1).ToUpper())$($result.LastName.Substring(0,1).ToUpper())$($result.LastName.Substring(1).ToLower())"

# 7. Generate password: “_F#L_<OfficeCode><DeptCode>!@#”
$pwdPlain = "_$($FirstName.Substring(0,1).ToUpper())`#$($LastName.Substring(0,1).ToUpper())" +
            "_$OfficeCode$DeptCode!@#"
$securePwd = ConvertTo-SecureString $pwdPlain -AsPlainText -Force

# 8. Create the new AD user
try {
    $newUser = New-ADUser `
        -Path $NewUserOU `
        -Name $fullName `
        -GivenName $FirstName `
        -Surname $LastName `
        -DisplayName $fullName `
        -SamAccountName $sam `
        -UserPrincipalName ("$sam$UPNSuffix") `
        -AccountPassword $securePwd `
        -Enabled $true `
        -ChangePasswordAtLogon $false `
        -Title $result.JobTitle `
        -OfficePhone $result.OfficePhone `
        -EmployeeNumber $result.EmployeeID `
        -PassThru
} catch {
    Write-Warning "Failed to create AD user $fullName. $_"
    Stop-Transcript
    return
}

# 9. Build the Replace‐hashtable: Department, Manager (if any), plus location attributes
$replaceHash = @{ Department = $DeptFullWithOffice }

if ($result.ManagerName) {
    try {
        $mgrUser = Get-ADUser -Filter "samAccountName -eq '$($result.ManagerName)'" -ErrorAction Stop
        $replaceHash['Manager'] = $mgrUser.DistinguishedName
    } catch {
        Write-Warning "Manager '$($result.ManagerName)' not found. Skipping Manager assignment."
    }
}


# Merge in all location attributes (streetAddress, l, st, postalCode, co, company, physicalDeliveryOfficeName)
foreach ($k in $locAttrs.Keys) {
    $replaceHash[$k] = $locAttrs[$k]
}

Set-ADUser -Identity $newUser -Replace $replaceHash

# 10. Set telephoneNumber, mobile, mail, extensionAttribute1, set extensionAttribute2 to be auto added to setup group
Set-ADUser -Identity $newUser -Add @{
    telephoneNumber     = $result.OfficePhone
    mobile              = $result.MobilePhone
    c                   = "US"
    mail                = "$sam$SMTPSuffix"
    extensionAttribute1 = $result.O365License
    extensionAttribute2 = "Setup"
}

# 11. Assign group memberships

# 11a. Baseline groups
foreach ($g in $GlobalGroups) {
    try {
        Add-ADGroupMember -Identity $g -Members $newUser -ErrorAction Stop
    } catch {
        Write-Warning "Failed to add '$sam' to baseline group '$g': $_"
    }
}

# 11b. Location-specific groups (based on exact $officeFull)
if ($LocationGroups.ContainsKey($officeFull)) {
    foreach ($grp in $LocationGroups[$officeFull]) {
        try {
            Add-ADGroupMember -Identity $grp -Members $newUser -ErrorAction Stop
        } catch {
            Write-Warning "Failed to add '$sam' to location group '$grp': $_"
        }
    }
}

# 11c. Department-specific groups (based on four-digit $DeptCode)
if ($DeptGroups.ContainsKey($DeptCode)) {
    foreach ($grp in $DeptGroups[$DeptCode]) {
        try {
            Add-ADGroupMember -Identity $grp -Members $newUser -ErrorAction Stop
        } catch {
            Write-Warning "Failed to add '$sam' to department group '$grp': $_"
        }
    }
}

# 11d. Additional user-selected groups (via checkboxes)
if ($result.SelectedGroups) {
    foreach ($grp in $result.SelectedGroups) {
        try {
            $adGroup = Get-ADGroup -Identity $grp -Properties GroupCategory
            if ($adGroup.GroupCategory -eq 'Security') {
                Add-ADGroupMember -Identity $grp -Members $newUser -ErrorAction Stop
            } else {
                Write-Warning "'$grp' is a distribution group and cannot have members added via Add-ADGroupMember."
            }
        } catch {
            Write-Warning "Failed to add '$sam' to selected group '$grp': $_"
        }
    }
}

# 12. Final summary to console
Write-Host ""
Write-Host "  Created AD user : $fullName  (samAccountName: $sam)"
Write-Host "  OU            : $NewUserOU"
Write-Host "  Employee #    : $($result.EmployeeID)"
Write-Host "  Department    : $DeptFullWithOffice"
Write-Host "  OfficeFull    : $officeFull  (Code = $OfficeCode)"
Write-Host "  Injected location attributes from lookup:"
foreach ($k in $locAttrs.Keys) {
    Write-Host "    $k = $($locAttrs[$k])"
}
Write-Host "  Manager       : $($replaceHash['Manager'])"
Write-Host "  O365 License  : $($result.O365License)"
Write-Host "  Password      : $pwdPlain"
Write-Host "  Group membership assignments:"
Write-Host "    Baseline groups: $($GlobalGroups -join ', ')"
Write-Host "    Location groups: $(
    if ($LocationGroups.ContainsKey($officeFull)) { $LocationGroups[$officeFull] -join ', ' } else { '<none>' }
  )"
Write-Host "    Department groups: $(
    if ($DeptGroups.ContainsKey($DeptCode)) { $DeptGroups[$DeptCode] -join ', ' } else { '<none>' }
  )"
Write-Host "    Additional selected groups: $(
    if ($result.SelectedGroups) { $result.SelectedGroups -join ', ' } else { '<none>' }
  )"
Write-Host ""

Stop-Transcript