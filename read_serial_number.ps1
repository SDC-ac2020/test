$computers = Import-Csv -Path C:\scripts\3079a_test.csv 

$results = foreach ($computer in $computers) {

Get-WmiObject -Class Win32_Bios -ComputerName $computer | Format-Table -Property SerialNumber
  
  


}

#$results | Export-Csv -Path C:\scripts\results.csv -NoTypeInformation
