$computers = Get-Content D:\scripts\computers.csv

foreach ($computer in $computers) {
    if (Test-Connection -Cn $computer -Quiet) {
        (Get-CimInstance -ClassName "Win32_EncryptableVolume" -Namespace "Root\CIMV2\Security\MicrosoftVolumeEncryption" -ComputerName $computer).ProtectionStatus
    } else {
        Write-Host "$computer is not online"
    }
}


#Get-BitLockerVolume | Select-Object ComputerName, ProtectionStatus, CapacityGB | Export-Csv "d:\scripts\bitlocker.csv" -NoTypeInformation -Encoding UTF8
