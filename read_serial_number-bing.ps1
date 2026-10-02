$computers = Import-Csv -Path "C:\scripts\3079a_test.csv"
$results = foreach ($computer in $computers) {
    Get-WmiObject -Class win32_bios -ComputerName $computer.Name | Select-Object -Property Serialnumber
}
$results | Export-Csv -Path "C:\scripts\results-bing.csv" -NoTypeInformation
