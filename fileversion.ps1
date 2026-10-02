# Read file paths
$filePaths = Get-Content -Path 'D:\scripts\files.txt'

# Read computer names
$computers = Get-Content -Path 'D:\scripts\computers.txt'

foreach ($computer in $computers) {

    foreach ($filePath in $filePaths) {

        # Convert drive letter to admin share (C$)
        $remotePath = $filePath -replace ':', '$'
        $fullPath = "\\$computer\$remotePath"

        if (Test-Path $fullPath) {
            $file = Get-Item $fullPath
            Write-Host "$computer | $($file.Name) | Version: $($file.VersionInfo.FileVersion)"
        }
        else {
            Write-Host "$computer | $filePath | Not found"
        }
    }
}
