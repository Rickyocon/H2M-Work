$logDir = "C:\Support\WebEx"
$logFile = "$logDir\WebExRemoval.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path $logFile -Append

Write-Output "===== Starting Webex Removal ====="

############################################
# Kill running Webex processes
############################################

Write-Output "Stopping Webex related processes..."

Get-Process webex*,atmgr*,ptoneclk*,ciscocollabhost -ErrorAction SilentlyContinue | Stop-Process -Force

############################################
# Remove MSI installations
############################################

Write-Output "Searching for Webex MSI installs..."

$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                         HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $_.DisplayName -like "*Webex*" }

foreach ($app in $apps) {

    Write-Output "Found install: $($app.DisplayName)"

    $guid = $app.PSChildName

    if ($guid -match "^\{.*\}$") {

        Write-Output "Attempting MSI uninstall: $guid"

        $process = Start-Process msiexec.exe `
            -ArgumentList "/x $guid /qn /norestart" `
            -Wait `
            -PassThru

        Write-Output "Exit code: $($process.ExitCode)"
    }
}

############################################
# Remove per-user installs
############################################

Write-Output "Checking user profiles for Webex installs..."

$users = Get-ChildItem C:\Users -Directory

foreach ($user in $users) {

    $path = "$($user.FullName)\AppData\Local\Programs\Cisco Webex"

    if (Test-Path $path) {

        Write-Output "Removing Webex from user: $($user.Name)"

        try {
            Remove-Item $path -Recurse -Force -ErrorAction Stop
            Write-Output "Removed $path"
        }
        catch {
            Write-Output "Failed removing $path"
        }
    }
}

############################################
# Remove leftover folders
############################################

Write-Output "Removing leftover Webex folders..."

$folders = @(
"C:\Program Files\Cisco Webex",
"C:\Program Files (x86)\Cisco Webex",
"C:\Program Files\Webex",
"C:\Program Files (x86)\Webex"
)

foreach ($folder in $folders) {

    if (Test-Path $folder) {

        Write-Output "Deleting $folder"

        try {
            Remove-Item $folder -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Output "Could not remove $folder"
        }
    }
}

############################################
# Remove Webex services
############################################

Write-Output "Checking for Webex services..."

$services = Get-Service | Where-Object {$_.Name -like "*webex*"}

foreach ($service in $services) {

    Write-Output "Stopping service $($service.Name)"

    Stop-Service $service.Name -Force -ErrorAction SilentlyContinue
}

############################################
# Cleanup scheduled tasks
############################################

Write-Output "Removing Webex scheduled tasks..."

Get-ScheduledTask | Where-Object {$_.TaskName -like "*webex*"} | Unregister-ScheduledTask -Confirm:$false

############################################
# Completion
############################################

Write-Output "===== Webex removal completed ====="

Stop-Transcript
exit 0