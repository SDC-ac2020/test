Get-Content C:\scripts\3079a.txt  | ForEach-Object{
$ser_number = (Get-WMIObject Win32_Bios -ComputerName $_ ).SerialNumber
if(!$ser_number){
$ser_number ="The server is unavailable"
}
New-Object -TypeName PSObject -Property @{
      ComputerName = $_
      SerialNumber = $ser_number
}} | Select ComputerName,SerialNumber |
Export-Csv C:\scripts\3079a-SerialNumbers.csv -NoTypeInformation -Encoding UTF8
