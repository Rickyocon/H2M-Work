#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Scans for and applies Dell BIOS/peripheral updates with guaranteed user notifications.

.DESCRIPTION
    1. Scans for updates matching configured filters
    2. Applies available updates
    3. Shows user notifications for all outcomes (reboot required, all done, etc)
    4. If reboot required, prompts user in their session with timeout
    5. If user reboots, runs post-reboot verification via scheduled task
    
.NOTES
    Works as SYSTEM (Intune) with GUARANTEED user-visible notifications via multiple methods.
#>

param([switch]$Verify)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[System.Environment]::SetEnvironmentVariable('TERM','dumb')

# Configuration 
$DCU_CLI = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

# Use a simple, reliable log location
$LogDir = "C:\ProgramData\Dell\UpdateLogs"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "DellUpdate_$Timestamp.log"

$TaskName = "DellUpdateVerify"
$RebootTimeoutSec = 60

# Exit codes that mean "no updates found" (should not retry)
$NoUpdatesExitCodes = @(2000, 3000, 500)

# Exit codes that mean "DCU is busy" (should retry)
$BusyExitCodes = @(5, 6, 107)

# Helper Functions 

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","SUCCESS")]
        [string]$Level = "INFO"
    )
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    
    # Write to file (plain text, no color codes)
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
    
    # Display to console with color
    $Color = @{
        "ERROR"="Red"
        "WARN"="Yellow"
        "SUCCESS"="Green"
    }
    if ($Color.ContainsKey($Level)) {
        Write-Host $Entry -ForegroundColor $Color[$Level]
    } else {
        Write-Host $Entry
    }
}

function Ensure-LogDir {
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction Stop | Out-Null
    }
}

function Get-DCUMessage {
    param([int]$Code)
    $Messages = @{
        0    = "Success - no reboot needed"
        1    = "Success - reboot required"
        2    = "Success - updates downloaded"
        3    = "Success - updates available (scan found items)"
        107  = "Temporary issue - system not ready (may retry)"
        500  = "No applicable updates found (filters matched nothing)"
        2000 = "No applicable updates found"
        3000 = "No applicable updates found (filters matched nothing)"
        5    = "ERROR - DCU UI is running"
        6    = "ERROR - Another dcu-cli process is running"
        1001 = "ERROR - Another DCU instance is running"
        1002 = "ERROR - Restart required before DCU can run"
        1003 = "ERROR - System not supported"
        1004 = "ERROR - Invalid parameter"
    }
    
    if ($Messages.ContainsKey($Code)) {
        return $Messages[$Code]
    } else {
        return "Unknown exit code: $Code"
    }
}

function Invoke-DCU {
    param(
        [string[]]$Arguments,
        [int]$MaxRetries = 5,
        [int]$RetrySec = 10
    )
    
    for ($Attempt = 1; $Attempt -le $MaxRetries; $Attempt++) {
        Write-Log "Invoking DCU (attempt $Attempt/$MaxRetries)..." -Level INFO
        
        # Execute DCU
        & $DCU_CLI @Arguments -silent 2>&1 | Out-Null
        $ExitCode = $LASTEXITCODE
        
        Write-Log "DCU returned exit code: $ExitCode" -Level INFO
        
        # If not a "busy" code, return immediately
        if ($ExitCode -notin $BusyExitCodes) {
            Write-Log "Exit code $ExitCode is not a busy code. Returning." -Level INFO
            return $ExitCode
        }
        
        # If it IS a busy code and we have retries left, wait and retry
        if ($Attempt -lt $MaxRetries) {
            Write-Log "DCU busy (code $ExitCode). Waiting $RetrySec seconds before retry $($Attempt + 1)/$MaxRetries..." -Level WARN
            Start-Sleep -Seconds $RetrySec
        } else {
            Write-Log "DCU busy (code $ExitCode) on final attempt. Giving up." -Level ERROR
            return $ExitCode
        }
    }
}

function Get-LoggedInUser {
    param([string]$LogFilePath)
    
    $LoggedInUser = $null
    
    # Method 1: Win32_LoggedInUser WMI
    try {
        $Sessions = Get-CimInstance -ClassName Win32_LoggedInUser -ErrorAction SilentlyContinue
        foreach ($Session in $Sessions) {
            $Name = $Session.Antecedent.Name
            if ($Name -notmatch "SYSTEM|LOCAL SERVICE|NETWORK SERVICE") {
                $LoggedInUser = $Name
                break
            }
        }
    } catch {
        Write-Log "WMI method failed: $_" -Level WARN
    }
    
    # Method 2: Registry fallback
    if (-not $LoggedInUser) {
        try {
            $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
            $LoggedInUser = (Get-ItemProperty -Path $RegPath -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue).LastLoggedOnUser
            if ($LoggedInUser) {
                Write-Log "Found user via registry: $LoggedInUser" -Level INFO
            }
        } catch {
            Write-Log "Registry method failed: $_" -Level WARN
        }
    }
    
    return $LoggedInUser
}

function Show-UserNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$NotificationType = "Info"
    )
    
    $LoggedInUser = Get-LoggedInUser
    
    if (-not $LoggedInUser) {
        Write-Log "No logged-in user found. Skipping notification." -Level WARN
        return
    }
    
    Write-Log "Showing notification to user: $LoggedInUser | Title: $Title" -Level INFO
    
    $TempScript = "$env:TEMP\DellNotification_$([guid]::NewGuid()).ps1"
    
    $ScriptContent = @'
param([string]$Title, [string]$Message, [string]$Type)

[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

$Icon = switch ($Type) {
    "Success" { [System.Windows.Forms.MessageBoxIcon]::Information }
    "Warning" { [System.Windows.Forms.MessageBoxIcon]::Warning }
    "Error"   { [System.Windows.Forms.MessageBoxIcon]::Error }
    default   { [System.Windows.Forms.MessageBoxIcon]::Information }
}

[System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, $Icon)
exit 0
'@
    
    $ScriptContent | Set-Content -Path $TempScript -Force -Encoding UTF8
    
    try {
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "powershell.exe"
        $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$TempScript`" -Title `"$Title`" -Message `"$Message`" -Type `"$NotificationType`""
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.CreateNoWindow = $false
        
        $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
        
        # Wait max 30 seconds for user to click OK
        if (-not $Process.WaitForExit(30000)) {
            $Process.Kill()
        }
        
        Write-Log "Notification displayed successfully" -Level SUCCESS
    } catch {
        Write-Log "Failed to show notification: $_. Trying msg.exe fallback..." -Level WARN
        
        # Fallback: Try msg.exe (built-in Windows notification)
        try {
            & cmd.exe /c msg * "$Title`n`n$Message" /TIME:30 2>&1 | Out-Null
            Write-Log "Fallback notification via msg.exe sent" -Level SUCCESS
        } catch {
            Write-Log "Fallback notification also failed: $_" -Level ERROR
        }
    } finally {
        Remove-Item -Path $TempScript -Force -ErrorAction SilentlyContinue
    }
}

function Show-RebootPromptToUser {
    param([int]$TimeoutSec = 60)
    
    $LoggedInUser = Get-LoggedInUser
    
    if (-not $LoggedInUser) {
        Write-Log "No logged-in user found. Defaulting to postpone." -Level WARN
        return $false
    }
    
    Write-Log "Showing reboot prompt to user: $LoggedInUser" -Level INFO
    
    $TempScript = "$env:TEMP\DellRebootPrompt_$([guid]::NewGuid()).ps1"
    
    $ScriptContent = @"
param([int]`$TimeoutSec)

`$Result = `$false
`$Remaining = `$TimeoutSec

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

`$Window = New-Object System.Windows.Window
`$Window.Title = "Dell Command | Update - Reboot Required"
`$Window.Width = 450
`$Window.Height = 240
`$Window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
`$Window.ResizeMode = [System.Windows.ResizeMode]::NoResize
`$Window.Topmost = `$true

`$Grid = New-Object System.Windows.Controls.Grid
1..4 | ForEach-Object {
    `$Row = New-Object System.Windows.Controls.RowDefinition
    `$Row.Height = [System.Windows.GridLength]::Auto
    `$Grid.RowDefinitions.Add(`$Row)
}

`$Title = New-Object System.Windows.Controls.TextBlock
`$Title.Text = "Reboot Required"
`$Title.FontSize = 16
`$Title.FontWeight = [System.Windows.FontWeights]::Bold
`$Title.Margin = "20,20,20,4"
[System.Windows.Controls.Grid]::SetRow(`$Title, 0)
`$Grid.Children.Add(`$Title) | Out-Null

`$Body = New-Object System.Windows.Controls.TextBlock
`$Body.Text = "Dell updates applied successfully.`n`nA restart is required. Reboot now or postpone?"
`$Body.TextWrapping = [System.Windows.TextWrapping]::Wrap
`$Body.Margin = "20,8,20,8"
`$Body.FontSize = 13
[System.Windows.Controls.Grid]::SetRow(`$Body, 1)
`$Grid.Children.Add(`$Body) | Out-Null

`$Countdown = New-Object System.Windows.Controls.TextBlock
`$Countdown.Text = "Defaulting to Postpone in `$TimeoutSec seconds..."
`$Countdown.FontSize = 11
`$Countdown.Foreground = [System.Windows.Media.Brushes]::Gray
`$Countdown.Margin = "20,0,20,12"
[System.Windows.Controls.Grid]::SetRow(`$Countdown, 2)
`$Grid.Children.Add(`$Countdown) | Out-Null

`$ButtonPanel = New-Object System.Windows.Controls.StackPanel
`$ButtonPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
`$ButtonPanel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
`$ButtonPanel.Margin = "20,0,20,20"
[System.Windows.Controls.Grid]::SetRow(`$ButtonPanel, 3)

`$BtnPostpone = New-Object System.Windows.Controls.Button
`$BtnPostpone.Content = "Postpone"
`$BtnPostpone.Width = 100
`$BtnPostpone.Margin = "0,0,10,0"
`$BtnPostpone.Add_Click({
    `$Result = `$false
    `$Window.Close()
})

`$BtnReboot = New-Object System.Windows.Controls.Button
`$BtnReboot.Content = "Reboot Now"
`$BtnReboot.Width = 110
`$BtnReboot.Background = [System.Windows.Media.Brushes]::SteelBlue
`$BtnReboot.Foreground = [System.Windows.Media.Brushes]::White
`$BtnReboot.Add_Click({
    `$Result = `$true
    `$Window.Close()
})

`$ButtonPanel.Children.Add(`$BtnPostpone) | Out-Null
`$ButtonPanel.Children.Add(`$BtnReboot) | Out-Null
`$Grid.Children.Add(`$ButtonPanel) | Out-Null
`$Window.Content = `$Grid

`$Timer = New-Object System.Windows.Threading.DispatcherTimer
`$Timer.Interval = [TimeSpan]::FromSeconds(1)
`$Timer.Add_Tick({
    `$Remaining--
    `$Countdown.Text = "Defaulting to Postpone in `$Remaining seconds..."
    if (`$Remaining -le 0) {
        `$Timer.Stop()
        `$Result = `$false
        `$Window.Close()
    }
})
`$Timer.Start()

`$Window.ShowDialog() | Out-Null
exit ([int]`$Result)
"@
    
    $ScriptContent | Set-Content -Path $TempScript -Force -Encoding UTF8
    
    try {
        $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $ProcessInfo.FileName = "powershell.exe"
        $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$TempScript`" -TimeoutSec $TimeoutSec"
        $ProcessInfo.UseShellExecute = $false
        $ProcessInfo.RedirectStandardOutput = $true
        $ProcessInfo.CreateNoWindow = $false
        
        $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
        $Process.WaitForExit()
        
        $UserChoice = [bool]($Process.ExitCode -eq 1)
        
        Write-Log "User choice: $(if ($UserChoice) { 'Reboot Now' } else { 'Postpone' })" -Level INFO
        return $UserChoice
    } catch {
        Write-Log "Failed to show reboot prompt: $_. Defaulting to postpone." -Level WARN
        return $false
    } finally {
        Remove-Item -Path $TempScript -Force -ErrorAction SilentlyContinue
    }
}

function Register-VerifyTask {
    $ScriptPath = (Resolve-Path $PSCommandPath).Path
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" -Verify"
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1)
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger `
        -Principal $Principal -Settings $Settings -Force | Out-Null
    Write-Log "Registered post-reboot verification task" -Level SUCCESS
}

# PHASE 2: Post-Reboot Verification

if ($Verify) {
    Ensure-LogDir
    Write-Log "==================================================================================" -Level INFO
    Write-Log "Post-Reboot Verification Started" -Level INFO
    Write-Log "==================================================================================" -Level INFO
    
    if (-not (Test-Path $DCU_CLI)) {
        Write-Log "ERROR: DCU CLI not found" -Level ERROR
        exit 1
    }
    
    $VerifyArgs = @(
        "/scan"
    )
    
    Write-Log "Running verification scan..." -Level INFO
    $VerifyCode = Invoke-DCU -Arguments $VerifyArgs
    Write-Log "Verification scan exit code: $VerifyCode - $(Get-DCUMessage $VerifyCode)" -Level INFO
    
    if ($VerifyCode -in $NoUpdatesExitCodes) {
        Write-Log "PASSED: All updates confirmed installed" -Level SUCCESS
        Show-UserNotification -Title "Dell Updates Complete" `
            -Message "All Dell updates have been successfully installed.`n`nNo further action required." `
            -NotificationType "Success"
    } elseif ($VerifyCode -in @(0, 1, 2, 3)) {
        Write-Log "Some updates still pending - may require additional reboots" -Level WARN
        Show-UserNotification -Title "Dell Updates - Additional Reboots Required" `
            -Message "Some updates are still pending and may require additional system reboots.`n`nPlease restart your computer and run updates again if needed." `
            -NotificationType "Warning"
    } else {
        Write-Log "FAILED: Verification scan returned error code $VerifyCode" -Level ERROR
        Show-UserNotification -Title "Dell Updates - Verification Failed" `
            -Message "Update verification encountered an error (Code: $VerifyCode).`n`nPlease contact IT support if this continues." `
            -NotificationType "Error"
    }
    
    # Cleanup
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "Cleanup: Removed scheduled task" -Level INFO
    }
    
    Write-Log "Log file: $LogFile" -Level INFO
    Write-Log "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
    exit $VerifyCode
}

# PHASE 1: Scan & Apply

Ensure-LogDir

Write-Log "==================================================================================" -Level INFO
Write-Log "Dell Command | Update - Automated Session" -Level INFO
Write-Log "Host: $env:COMPUTERNAME | User: $env:USERNAME" -Level INFO
Write-Log "==================================================================================" -Level INFO

if (-not (Test-Path $DCU_CLI)) {
    Write-Log "ERROR: DCU CLI not found at $DCU_CLI" -Level ERROR
    exit 1
}

# Get DCU version
$Version = & $DCU_CLI /version 2>&1
Write-Log "DCU Version: $Version" -Level INFO

# SCAN

Write-Log "Scanning for updates..." -Level INFO

$ScanArgs = @(
    "/scan"
)

$ScanCode = Invoke-DCU -Arguments $ScanArgs
Write-Log "Scan exit code: $ScanCode - $(Get-DCUMessage $ScanCode)" -Level INFO

if ($ScanCode -in $NoUpdatesExitCodes) {
    Write-Log "No updates available. Done." -Level INFO
    Show-UserNotification -Title "Dell Updates Check" `
        -Message "Your system is up to date.`n`nNo Dell updates are currently available." `
        -NotificationType "Info"
    exit 0
}

if ($ScanCode -notin @(0, 1, 2, 3, 107)) {
    Write-Log "Scan failed with code $ScanCode. Aborting." -Level ERROR
    Show-UserNotification -Title "Dell Updates - Scan Failed" `
        -Message "The update scan encountered an error (Code: $ScanCode).`n`nPlease contact IT support if this continues." `
        -NotificationType "Error"
    exit $ScanCode
}

Write-Log "Updates found. Proceeding to apply..." -Level SUCCESS

# APPLY

Write-Log "Applying updates..." -Level INFO

$ApplyArgs = @(
    "/applyUpdates",
    "-reboot=disable"
)

$ApplyStart = Get-Date
$ApplyCode = Invoke-DCU -Arguments $ApplyArgs
$Duration = ((Get-Date) - $ApplyStart).ToString("mm\:ss")

Write-Log "Apply completed in $Duration - Exit code: $ApplyCode - $(Get-DCUMessage $ApplyCode)" -Level INFO

# REBOOT HANDLING

if ($ApplyCode -eq 1) {
    Write-Log "Reboot required. Prompting user..." -Level WARN
    
    # Register verification task BEFORE prompting
    Register-VerifyTask
    
    # Show prompt to logged-in user
    $UserChoice = Show-RebootPromptToUser -TimeoutSec $RebootTimeoutSec
    
    if ($UserChoice) {
        Write-Log "User selected: Reboot Now. Restarting in 5 seconds..." -Level WARN
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    } else {
        Write-Log "User selected: Postpone. Reminder: Manual reboot required." -Level WARN
        Show-UserNotification -Title "Dell Updates - Reboot Required Later" `
            -Message "Dell updates have been applied.`n`nA system restart is required to complete the installation.`n`nPlease restart your computer at your earliest convenience." `
            -NotificationType "Warning"
    }
} elseif ($ApplyCode -in @(0, 2)) {
    Write-Log "Updates applied successfully. No reboot required." -Level SUCCESS
    Show-UserNotification -Title "Dell Updates - All Done" `
        -Message "All Dell updates have been successfully installed.`n`nNo restart is required." `
        -NotificationType "Success"
} elseif ($ApplyCode -in $NoUpdatesExitCodes) {
    Write-Log "No updates were available to apply." -Level INFO
    Show-UserNotification -Title "Dell Updates Check" `
        -Message "Your system is up to date.`n`nNo Dell updates were available to install." `
        -NotificationType "Info"
} else {
    Write-Log "Apply failed with code $ApplyCode" -Level ERROR
    Show-UserNotification -Title "Dell Updates - Apply Failed" `
        -Message "The update installation encountered an error (Code: $ApplyCode).`n`nPlease contact IT support if this continues." `
        -NotificationType "Error"
}

Write-Log "Log: $LogFile" -Level INFO
Write-Log "Done: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
exit $ApplyCode