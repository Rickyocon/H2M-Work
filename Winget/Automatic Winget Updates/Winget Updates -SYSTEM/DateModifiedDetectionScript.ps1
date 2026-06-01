$DetectionFile = "C:\Support\Winget_Update_Detection.txt"

# Check if the detection file exists
if (-Not (Test-Path $DetectionFile)) {
    exit 1
}

# Get the LastWriteTime (modified date) of the detection file
$LastModified = (Get-Item $DetectionFile).LastWriteTime
$Now = Get-Date

# Calculate the difference in days
$DaysOld = ($Now - $LastModified).TotalDays

# If it's older than 91 days, exit 1 to trigger install
if ($DaysOld -ge 91) {
    exit 1
} else {
    exit 0
}
