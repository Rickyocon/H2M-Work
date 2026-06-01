$logDir = "C:\Support\WebEx"
$logFile = "$logDir\WebExRemoval.log"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path $logFile -Append

Write-Output "===== Starting Webex Removal ====="

############################################
# Kill running Webex processes
############################################

Write-Output "Stopping Webex related processes..."

Get-Process webex*,atmgr*,ptoneclk*,ciscocollabhost,CiscoWebExStart,WebexHost -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep -Seconds 3

############################################
# Remove logged-in user registry entries via HKU
############################################

Write-Output "Cleaning up logged-in user registry entries..."

$loadedHives = Get-ChildItem "Registry::HKU" | Where-Object { 
    $_.Name -notlike "*_Classes" -and 
    $_.Name -ne ".DEFAULT" -and 
    $_.Name -notlike "*S-1-5-18*" -and 
    $_.Name -notlike "*S-1-5-19*" -and 
    $_.Name -notlike "*S-1-5-20*" 
}

foreach ($hive in $loadedHives) {

    $uninstallPath = "Registry::$($hive.Name)\Software\Microsoft\Windows\CurrentVersion\Uninstall"

    if (Test-Path $uninstallPath) {

        Get-ChildItem $uninstallPath | ForEach-Object {

            $app = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue

            if ($app.DisplayName -like "*Webex*" -or $app.DisplayName -like "*Cisco Spark*") {

                Write-Output "Removing registry key from loaded hive: $($app.DisplayName)"
                Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

############################################
# Remove MSI installations
############################################

Write-Output "Searching for Webex MSI installs..."

$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                         HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $_.DisplayName -like "*Webex*" -or $_.DisplayName -like "*Cisco Spark*" }

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
# Fallback - force remove leftover registry
# entries from Programs and Features
############################################

Write-Output "Cleaning up leftover Programs and Features entries..."

$stubborn = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                             HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $_.DisplayName -like "*Webex*" -or $_.DisplayName -like "*Cisco Spark*" }

foreach ($app in $stubborn) {

    if ($app.InstallLocation -and (Test-Path $app.InstallLocation)) {
        Write-Output "Force removing install folder: $($app.InstallLocation)"
        Remove-Item $app.InstallLocation -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Removing Programs and Features registry key: $($app.DisplayName)"
    Remove-Item $app.PSPath -Recurse -Force -ErrorAction SilentlyContinue
}

############################################
# Remove per-user installs and shortcuts
############################################

Write-Output "Checking user profiles for Webex installs..."

$users = Get-ChildItem C:\Users -Directory

foreach ($user in $users) {

    $paths = @(
        "$($user.FullName)\AppData\Local\Programs\Cisco Webex",
        "$($user.FullName)\AppData\Local\Programs\Cisco Spark",
        "$($user.FullName)\AppData\Local\WebEx",
        "$($user.FullName)\AppData\Local\CiscoSpark",
        "$($user.FullName)\AppData\Local\CiscoSparkLauncher",
        "$($user.FullName)\AppData\Local\CiscoWebexLauncher",
        "$($user.FullName)\AppData\Roaming\Webex",
        "$($user.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Webex",
        "$($user.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Webex.lnk",
        "$($user.FullName)\Desktop\Webex.lnk",
        "$($user.FullName)\OneDrive - H2M\Desktop\Webex.lnk"
        "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Webex\Webex.lnk"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Output "Removing: $path"
            try {
                Remove-Item $path -Recurse -Force -ErrorAction Stop
                Write-Output "Removed $path"
            }
            catch {
                Write-Output "Failed removing $path : $_"
            }
        }
    }
}

############################################
# Remove per-user registry uninstall entries
############################################

Write-Output "Cleaning up per-user registry entries..."

foreach ($user in $users) {

    $ntuser = "$($user.FullName)\NTUSER.DAT"

    if (Test-Path $ntuser) {

        $regPath = "HKU\$($user.Name)_Temp"

        try {
            reg load $regPath $ntuser 2>$null

            $uninstallPath = "Registry::$regPath\Software\Microsoft\Windows\CurrentVersion\Uninstall"

            if (Test-Path $uninstallPath) {

                Get-ChildItem $uninstallPath | ForEach-Object {

                    $app = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue

                    if ($app.DisplayName -like "*Webex*" -or $app.DisplayName -like "*Cisco Spark*") {

                        Write-Output "Removing registry key: $($app.DisplayName)"
                        Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        catch {
            Write-Output "Could not load hive for $($user.Name): $_"
        }
        finally {
            reg unload $regPath 2>$null
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
    "C:\Program Files (x86)\Webex",
    "C:\Program Files\Cisco Spark",
    "C:\Program Files (x86)\Cisco Spark"
)

foreach ($folder in $folders) {

    if (Test-Path $folder) {

        Write-Output "Deleting $folder"

        try {
            Remove-Item $folder -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Output "Could not remove $folder : $_"
        }
    }
}

############################################
# Remove Webex services
############################################

Write-Output "Checking for Webex services..."

$services = Get-Service | Where-Object {$_.Name -like "*webex*" -or $_.Name -like "*spark*"}

foreach ($service in $services) {

    Write-Output "Stopping service $($service.Name)"

    Stop-Service $service.Name -Force -ErrorAction SilentlyContinue
}

############################################
# Cleanup scheduled tasks
############################################

Write-Output "Removing Webex scheduled tasks..."

Get-ScheduledTask | Where-Object {$_.TaskName -like "*webex*" -or $_.TaskName -like "*spark*"} | Unregister-ScheduledTask -Confirm:$false

############################################
# Completion
############################################

Write-Output "===== Webex removal completed ====="

Stop-Transcript
exit 0