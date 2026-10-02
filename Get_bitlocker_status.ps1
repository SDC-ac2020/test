$computers = Get-Content D:\scripts\computers.csv

foreach ($computer in $computers) {
    if (Test-Connection -Cn $computer -Quiet) {
        Get-BitLockerVolume -MountPoint "C:" | Format-List ProtectionStatus, CapacityGB
    } else {
        Write-Host "$computer is not online"
    }
}

Get-BitLockerVolume | Select-Object ComputerName, ProtectionStatus, CapacityGB | Export-Csv "d:\scripts\bitlocker.csv" -NoTypeInformation -Encoding UTF8
