# Install PowerShell 7 silently
$githubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
$release = Invoke-RestMethod -Uri $githubApiUrl
$asset = $release.assets | Where-Object { $_.name -like "*win-x64.msi" }
$downloadUrl = $asset.browser_download_url
$filename = "$env:TEMP\$($asset.name)"

Invoke-WebRequest -Uri $downloadUrl -OutFile $filename
Start-Process msiexec.exe -ArgumentList "/i `"$filename`" /qn /norestart" -Wait
