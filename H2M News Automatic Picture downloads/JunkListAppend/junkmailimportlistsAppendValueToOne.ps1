Copy-Item -Path "\\app-server\APPS\_Intune Applications\1 Source\PowerShell\SafeSenders\JunkAppend\junkmailimportlistsAppendValueToOneDetection.txt" -Destination "C:\Support\SafeSenders\junkmailimportlistsAppendValueToOneDetection.txt" -Force

# 1. Map the HKEY_USERS hive so PowerShell can see it
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue

# 2. Get the SID of the currently logged-on user
$user = Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty UserName
$sid = (New-Object System.Security.Principal.NTAccount($user)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# 3. Define the path using the User's SID
$Path = "HKU:\$sid\Software\Policies\Microsoft\Office\16.0\outlook\options\mail"

# 4. Create the key and value with System-level permissions
if (-not (Test-Path $Path)) { New-Item -Path $Path -Force }
Set-ItemProperty -Path $Path -Name "junkmailimportlists" -Value 1 -Type DWord

