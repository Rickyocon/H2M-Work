Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\WingetPathFix.log" -Force

$wingetdir = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" | Sort-Object -Property Path | Select-Object -Last 1

if ($wingetdir) {
    $currentSystemPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    
    if ($currentSystemPath -notlike "*$($wingetdir.Path)*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentSystemPath;$($wingetdir.Path)", [EnvironmentVariableTarget]::Machine)
    }

    Write-Output "Winget folder added to SYSTEM PATH: $($wingetdir.Path)"
} else {
    Write-Output "Winget folder not found in WindowsApps."
}

Stop-Transcript
