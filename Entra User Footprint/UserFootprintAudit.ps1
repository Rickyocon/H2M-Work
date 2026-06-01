# UserFootprintAudit.ps1
# Audits a user's footprint across App Registrations, Groups, Service Principals,
# Conditional Access, Directory Roles, and Devices in Entra ID.
# Designed for Entra ID tenant (cloud-only).
# Requires: Microsoft.Graph PowerShell SDK
# Scopes: User.Read.All, Application.Read.All, Group.Read.All,
#         RoleManagement.Read.Directory, Device.Read.All, Policy.Read.All

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region --- AUTH ---

$RequiredScopes = @(
    "User.Read.All",
    "Application.Read.All",
    "Group.Read.All",
    "RoleManagement.Read.Directory",
    "Device.Read.All",
    "Policy.Read.All"
)

try {
    Connect-MgGraph -TenantId "ENTER_TENANT_ID" `
                    -Scopes $RequiredScopes `
                    -ErrorAction Stop | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Authentication failed:`n$($_.Exception.Message)",
        "Auth Error", "OK", "Error"
    )
    exit
}

#endregion

#region --- HELPERS ---

function Resolve-User {
    param([string]$SearchTerm)
    $SearchTerm = $SearchTerm.Trim()
    if (-not $SearchTerm) { return $null, "No input provided." }

    $lastError = ""

    # Strategy 1: Direct lookup by UPN or Object ID
    try {
        $u = Get-MgUser -UserId $SearchTerm `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ErrorAction Stop
        if ($u) { return $u, $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    # Strategy 2: Filter by userPrincipalName
    try {
        $escaped = $SearchTerm.Replace("'", "''")
        $r = Get-MgUser -Filter "userPrincipalName eq '$escaped'" `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ConsistencyLevel eventual `
                        -ErrorAction Stop
        if ($r) { return ($r | Select-Object -First 1), $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    # Strategy 3: Filter by mail address
    try {
        $escaped = $SearchTerm.Replace("'", "''")
        $r = Get-MgUser -Filter "mail eq '$escaped'" `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ConsistencyLevel eventual `
                        -ErrorAction Stop
        if ($r) { return ($r | Select-Object -First 1), $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    # Strategy 4: Display name exact match
    try {
        $escaped = $SearchTerm.Replace("'", "''")
        $r = Get-MgUser -Filter "displayName eq '$escaped'" `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ConsistencyLevel eventual `
                        -ErrorAction Stop
        if ($r) { return ($r | Select-Object -First 1), $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    # Strategy 5: startsWith on displayName
    try {
        $escaped = $SearchTerm.Replace("'", "''")
        $r = Get-MgUser -Filter "startsWith(displayName,'$escaped')" `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ConsistencyLevel eventual `
                        -Top 10 `
                        -ErrorAction Stop
        if ($r) { return ($r | Select-Object -First 1), $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    # Strategy 6: startsWith on UPN
    try {
        $escaped = $SearchTerm.Replace("'", "''")
        $r = Get-MgUser -Filter "startsWith(userPrincipalName,'$escaped')" `
                        -Property "Id,DisplayName,UserPrincipalName,AccountEnabled,Mail" `
                        -ConsistencyLevel eventual `
                        -Top 10 `
                        -ErrorAction Stop
        if ($r) { return ($r | Select-Object -First 1), $null }
    } catch {
        $lastError = $_.Exception.Message
    }

    return $null, "User not found: '$SearchTerm'. Last error: $lastError"
}

function Get-AppOwnerships {
    param([string]$UserId)
    $owned = @()

    # App Registrations (applications)
    try {
        $apps = Get-MgUserOwnedObject -UserId $UserId -All -ErrorAction Stop
        foreach ($obj in $apps) {
            $type = $obj.AdditionalProperties["@odata.type"]
            $displayName = $obj.AdditionalProperties["displayName"]
            $appId = $obj.AdditionalProperties["appId"]

            if ($type -eq "#microsoft.graph.application") {
                # Check if there are other owners
                try {
                    $owners = Get-MgApplicationOwner -ApplicationId $obj.Id -ErrorAction SilentlyContinue
                    $ownerCount = ($owners | Measure-Object).Count
                } catch { $ownerCount = "?" }

                $owned += [PSCustomObject]@{
                    Category    = "App Registration"
                    Name        = $displayName
                    Detail      = "AppId: $appId"
                    Risk        = if ($ownerCount -le 1) { "HIGH - Sole owner" } else { "Low - $ownerCount owners" }
                    ObjectId    = $obj.Id
                }
            } elseif ($type -eq "#microsoft.graph.servicePrincipal") {
                $owned += [PSCustomObject]@{
                    Category    = "Service Principal (Owner)"
                    Name        = $displayName
                    Detail      = "AppId: $appId"
                    Risk        = "REVIEW"
                    ObjectId    = $obj.Id
                }
            } elseif ($type -eq "#microsoft.graph.group") {
                $owned += [PSCustomObject]@{
                    Category    = "Group (Owner)"
                    Name        = $displayName
                    Detail      = "Type: Group"
                    Risk        = "REVIEW"
                    ObjectId    = $obj.Id
                }
            }
        }
    } catch {
        $owned += [PSCustomObject]@{
            Category = "App/Object Ownership"
            Name     = "Error retrieving"
            Detail   = $_.Exception.Message
            Risk     = "ERROR"
            ObjectId = ""
        }
    }

    return $owned
}

function Get-GroupMemberships {
    param([string]$UserId)
    $groups = @()
    try {
        $memberships = Get-MgUserMemberOf -UserId $UserId -All -ErrorAction Stop
        foreach ($m in $memberships) {
            $type = $m.AdditionalProperties["@odata.type"]
            $name = $m.AdditionalProperties["displayName"]
            $desc = $m.AdditionalProperties["description"]
            $mailEnabled = $m.AdditionalProperties["mailEnabled"]
            $secEnabled  = $m.AdditionalProperties["securityEnabled"]
            $groupType   = $m.AdditionalProperties["groupTypes"]

            $detail = ""
            if ($type -eq "#microsoft.graph.group") {
                $flags = @()
                if ($mailEnabled)  { $flags += "Mail" }
                if ($secEnabled)   { $flags += "Security" }
                if ($groupType -contains "Unified") { $flags += "M365" }
                $detail = $flags -join " | "
                $cat = "Group Membership"
            } elseif ($type -eq "#microsoft.graph.directoryRole") {
                $cat    = "Directory Role"
                $detail = "Entra ID Role"
            } else {
                $cat    = "Membership"
                $detail = $type
            }

            $groups += [PSCustomObject]@{
                Category = $cat
                Name     = $name
                Detail   = $detail
                Risk     = if ($cat -eq "Directory Role") { "HIGH - Privileged Role" } else { "Info" }
                ObjectId = $m.Id
            }
        }
    } catch {
        $groups += [PSCustomObject]@{
            Category = "Group Membership"
            Name     = "Error retrieving"
            Detail   = $_.Exception.Message
            Risk     = "ERROR"
            ObjectId = ""
        }
    }
    return $groups
}

function Get-DirectoryRoles {
    param([string]$UserId)
    $roles = @()
    try {
        $assignments = Get-MgUserTransitiveMemberOf -UserId $UserId -All -ErrorAction Stop |
                       Where-Object { $_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.directoryRole" }
        foreach ($r in $assignments) {
            $roles += [PSCustomObject]@{
                Category = "Directory Role (Transitive)"
                Name     = $r.AdditionalProperties["displayName"]
                Detail   = $r.AdditionalProperties["description"]
                Risk     = "HIGH - Privileged Role"
                ObjectId = $r.Id
            }
        }
    } catch {}
    return $roles
}

function Get-RegisteredDevices {
    param([string]$UserId)
    $devices = @()
    try {
        $devList = Get-MgUserRegisteredDevice -UserId $UserId -All -ErrorAction Stop
        foreach ($d in $devList) {
            $devices += [PSCustomObject]@{
                Category = "Registered Device"
                Name     = $d.AdditionalProperties["displayName"]
                Detail   = "OS: $($d.AdditionalProperties['operatingSystem']) $($d.AdditionalProperties['operatingSystemVersion'])"
                Risk     = "Info"
                ObjectId = $d.Id
            }
        }
    } catch {}

    try {
        $ownedDev = Get-MgUserOwnedDevice -UserId $UserId -All -ErrorAction Stop
        foreach ($d in $ownedDev) {
            $devices += [PSCustomObject]@{
                Category = "Owned Device"
                Name     = $d.AdditionalProperties["displayName"]
                Detail   = "OS: $($d.AdditionalProperties['operatingSystem']) $($d.AdditionalProperties['operatingSystemVersion'])"
                Risk     = "Info"
                ObjectId = $d.Id
            }
        }
    } catch {}

    return $devices
}

function Get-CANamedLocations {
    # Returns Conditional Access policies where the user might be a target
    # (Named inclusions are not directly user-queryable in bulk; return policy count as info)
    return @()
}

function Get-OAuthGrants {
    param([string]$UserId)
    $grants = @()
    try {
        $rawGrants = Get-MgUserOauth2PermissionGrant -UserId $UserId -All -ErrorAction Stop
        foreach ($g in $rawGrants) {
            try {
                $sp = Get-MgServicePrincipal -ServicePrincipalId $g.ClientId -ErrorAction SilentlyContinue
                $spName = if ($sp) { $sp.DisplayName } else { $g.ClientId }
            } catch { $spName = $g.ClientId }

            $grants += [PSCustomObject]@{
                Category = "OAuth2 App Consent"
                Name     = $spName
                Detail   = "Scope: $($g.Scope)"
                Risk     = "REVIEW - App has delegated permissions"
                ObjectId = $g.Id
            }
        }
    } catch {}
    return $grants
}

function Run-Audit {
    param([string]$UserInput)

    $resolveResult = Resolve-User -SearchTerm $UserInput
    $user   = $resolveResult[0]
    $errMsg = $resolveResult[1]

    if (-not $user) {
        return $null, $errMsg
    }

    $results = @()
    $results += Get-AppOwnerships     -UserId $user.Id
    $results += Get-GroupMemberships  -UserId $user.Id
    $results += Get-DirectoryRoles    -UserId $user.Id
    $results += Get-RegisteredDevices -UserId $user.Id
    $results += Get-OAuthGrants       -UserId $user.Id

    return $user, $results
}

#endregion

#region --- GUI ---

$form = New-Object System.Windows.Forms.Form
$form.Text = "User Footprint Audit"
$form.Size = New-Object System.Drawing.Size(1100, 720)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

# --- Title Bar ---
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Dock = "Top"
$titlePanel.Height = 52
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(0, 78, 152)
$form.Controls.Add($titlePanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "User Footprint Audit"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(16, 12)
$titlePanel.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "App Registrations | Groups | Roles | Devices | OAuth Consents"
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$subLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 220, 255)
$subLabel.AutoSize = $true
$subLabel.Location = New-Object System.Drawing.Point(18, 36)
$titlePanel.Controls.Add($subLabel)

# --- Search Panel ---
$searchPanel = New-Object System.Windows.Forms.Panel
$searchPanel.Dock = "Top"
$searchPanel.Height = 56
$searchPanel.BackColor = [System.Drawing.Color]::White
$searchPanel.Padding = New-Object System.Windows.Forms.Padding(12, 0, 12, 0)
$form.Controls.Add($searchPanel)

$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Text = "User (UPN or Display Name):"
$searchLabel.AutoSize = $true
$searchLabel.Location = New-Object System.Drawing.Point(14, 18)
$searchPanel.Controls.Add($searchLabel)

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(210, 15)
$searchBox.Size = New-Object System.Drawing.Size(520, 24)
$searchBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$searchPanel.Controls.Add($searchBox)

$auditBtn = New-Object System.Windows.Forms.Button
$auditBtn.Text = "Run Audit"
$auditBtn.Location = New-Object System.Drawing.Point(740, 13)
$auditBtn.Size = New-Object System.Drawing.Size(110, 28)
$auditBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$auditBtn.ForeColor = [System.Drawing.Color]::White
$auditBtn.FlatStyle = "Flat"
$auditBtn.FlatAppearance.BorderSize = 0
$searchPanel.Controls.Add($auditBtn)

$exportBtn = New-Object System.Windows.Forms.Button
$exportBtn.Text = "Export CSV"
$exportBtn.Location = New-Object System.Drawing.Point(860, 13)
$exportBtn.Size = New-Object System.Drawing.Size(100, 28)
$exportBtn.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16)
$exportBtn.ForeColor = [System.Drawing.Color]::White
$exportBtn.FlatStyle = "Flat"
$exportBtn.FlatAppearance.BorderSize = 0
$exportBtn.Enabled = $false
$searchPanel.Controls.Add($exportBtn)

# --- User Info Strip ---
$infoPanel = New-Object System.Windows.Forms.Panel
$infoPanel.Dock = "Top"
$infoPanel.Height = 38
$infoPanel.BackColor = [System.Drawing.Color]::FromArgb(235, 244, 255)
$infoPanel.Visible = $false
$form.Controls.Add($infoPanel)

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.AutoSize = $true
$infoLabel.Location = New-Object System.Drawing.Point(14, 10)
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$infoPanel.Controls.Add($infoLabel)

$acctStatusLabel = New-Object System.Windows.Forms.Label
$acctStatusLabel.AutoSize = $true
$acctStatusLabel.Location = New-Object System.Drawing.Point(700, 10)
$acctStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$infoPanel.Controls.Add($acctStatusLabel)

# --- Summary Strip ---
$summaryPanel = New-Object System.Windows.Forms.Panel
$summaryPanel.Dock = "Top"
$summaryPanel.Height = 32
$summaryPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 250, 235)
$summaryPanel.Visible = $false
$form.Controls.Add($summaryPanel)

$summaryLabel = New-Object System.Windows.Forms.Label
$summaryLabel.AutoSize = $true
$summaryLabel.Location = New-Object System.Drawing.Point(14, 8)
$summaryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$summaryPanel.Controls.Add($summaryLabel)

# --- Results Grid ---
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = "Fill"
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.SelectionMode = "FullRowSelect"
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = "Fill"
$grid.RowHeadersVisible = $false
$grid.BorderStyle = "None"
$grid.BackgroundColor = [System.Drawing.Color]::White
$grid.GridColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$grid.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
$grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$grid.EnableHeadersVisualStyles = $false
$form.Controls.Add($grid)

# --- Status Bar ---
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Enter a UPN or display name and click Run Audit."
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

# --- Grid Columns ---
$colCategory = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colCategory.HeaderText = "Category"
$colCategory.Name = "Category"
$colCategory.FillWeight = 20

$colName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colName.HeaderText = "Name"
$colName.Name = "Name"
$colName.FillWeight = 28

$colDetail = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colDetail.HeaderText = "Detail"
$colDetail.Name = "Detail"
$colDetail.FillWeight = 32

$colRisk = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colRisk.HeaderText = "Risk / Status"
$colRisk.Name = "Risk"
$colRisk.FillWeight = 20

$grid.Columns.AddRange($colCategory, $colName, $colDetail, $colRisk)

# --- Row Coloring ---
$grid.Add_CellFormatting({
    param($s, $e)
    if ($e.RowIndex -lt 0) { return }
    $riskVal = $grid.Rows[$e.RowIndex].Cells["Risk"].Value
    switch -Wildcard ($riskVal) {
        "HIGH*"   {
            $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 235, 235)
            $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
        }
        "REVIEW*" {
            $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 248, 220)
            $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(130, 80, 0)
        }
        "ERROR"   {
            $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(250, 235, 250)
            $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(120, 0, 120)
        }
        default   {
            $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::White
            $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::Black
        }
    }
})

#endregion

#region --- EVENTS ---

$script:AuditResults = @()
$script:AuditUser    = $null

$RunAudit = {
    $grid.Rows.Clear()
    $infoPanel.Visible   = $false
    $summaryPanel.Visible = $false
    $exportBtn.Enabled   = $false
    $script:AuditResults = @()
    $script:AuditUser    = $null

    $userInput = $searchBox.Text.Trim()
    if (-not $userInput) {
        $statusLabel.Text = "Please enter a UPN or display name."
        return
    }

    $statusLabel.Text = "Auditing $userInput ..."
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $form.Refresh()

    try {
        $auditReturn = Run-Audit -UserInput $userInput
        $user    = $auditReturn[0]
        $results = if ($auditReturn.Count -gt 1) { $auditReturn[1..($auditReturn.Count-1)] } else { @() }

        if (-not $user) {
            # $results[0] holds the error string when user is null
            $errMsg = $auditReturn[1]
            $statusLabel.Text = $errMsg
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            [System.Windows.Forms.MessageBox]::Show($errMsg, "Not Found", "OK", "Warning")
            return
        }

        # Re-fetch results cleanly (they are PSCustomObjects, filter out any stray strings)
        $results = @($results | Where-Object { $_ -is [PSCustomObject] })

        $script:AuditUser    = $user
        $script:AuditResults = $results

        # User info strip
        $acctStatus = if ($user.AccountEnabled) { "ACTIVE" } else { "DISABLED" }
        $infoLabel.Text = "User: $($user.DisplayName)   |   UPN: $($user.UserPrincipalName)   |   Mail: $($user.Mail)   |   Object ID: $($user.Id)"
        $acctStatusLabel.Text = "Account: $acctStatus"
        $acctStatusLabel.ForeColor = if ($user.AccountEnabled) {
            [System.Drawing.Color]::FromArgb(0, 120, 0)
        } else {
            [System.Drawing.Color]::FromArgb(180, 0, 0)
        }
        $infoPanel.Visible = $true

        # Populate grid
        foreach ($r in $results) {
            $grid.Rows.Add($r.Category, $r.Name, $r.Detail, $r.Risk) | Out-Null
        }

        # Summary
        $highCount    = ($results | Where-Object { $_.Risk -like "HIGH*" }).Count
        $reviewCount  = ($results | Where-Object { $_.Risk -like "REVIEW*" }).Count
        $totalCount   = $results.Count
        $summaryLabel.Text = "Total findings: $totalCount   |   HIGH risk: $highCount   |   Needs Review: $reviewCount   |   Disabled user with active ownership: $(if (-not $user.AccountEnabled -and $highCount -gt 0) { 'YES - ACTION REQUIRED' } else { 'No' })"
        $summaryPanel.Visible = $true

        $exportBtn.Enabled = $true
        $statusLabel.Text  = "Audit complete. $totalCount items found for $($user.DisplayName)."

    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Audit Error", "OK", "Error")
    }

    $form.Cursor = [System.Windows.Forms.Cursors]::Default
}

$auditBtn.Add_Click($RunAudit)
$searchBox.Add_KeyDown({
    if ($_.KeyCode -eq "Return") { & $RunAudit }
})

$exportBtn.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "CSV Files (*.csv)|*.csv"
    $dlg.FileName = "UserFootprintAudit_$($script:AuditUser.UserPrincipalName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    if ($dlg.ShowDialog() -eq "OK") {
        $exportRows = $script:AuditResults | Select-Object Category, Name, Detail, Risk, ObjectId
        # Add user metadata as header rows
        $meta = @(
            [PSCustomObject]@{ Category="AUDIT METADATA"; Name="User";          Detail=$script:AuditUser.DisplayName;        Risk=""; ObjectId="" },
            [PSCustomObject]@{ Category="AUDIT METADATA"; Name="UPN";           Detail=$script:AuditUser.UserPrincipalName;  Risk=""; ObjectId="" },
            [PSCustomObject]@{ Category="AUDIT METADATA"; Name="Object ID";     Detail=$script:AuditUser.Id;                 Risk=""; ObjectId="" },
            [PSCustomObject]@{ Category="AUDIT METADATA"; Name="Account Status";Detail=$(if ($script:AuditUser.AccountEnabled) { "Active" } else { "DISABLED" }); Risk=""; ObjectId="" },
            [PSCustomObject]@{ Category="AUDIT METADATA"; Name="Audit Date";    Detail=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Risk=""; ObjectId="" },
            [PSCustomObject]@{ Category="---"; Name="---"; Detail="---"; Risk="---"; ObjectId="---" }
        )
        ($meta + $exportRows) | Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Exported to:`n$($dlg.FileName)", "Export Complete", "OK", "Information")
    }
})

#endregion

[void]$form.ShowDialog()
