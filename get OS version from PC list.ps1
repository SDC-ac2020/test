Get-Content "d:\scripts\Win10_pre_oct_2025.csv"  | ForEach-Object{
$os_name=$null
$os_version=$null
$errorMsg=''
Try
{
$os_name = (Get-WmiObject Win32_OperatingSystem -ComputerName $_ ).Caption
}
catch
{
$errorMsg=$_.Exception.Message
}
if(!$os_name){
$os_name = "The machine is unavailable $errorMsg"
$os_version = "The machine is unavailable"
}
else{
$os_version = (Get-WmiObject Win32_OperatingSystem -ComputerName $_ ).Version 
}
New-Object -TypeName PSObject -Property @{
ComputerName = $_
OSName = $os_name
OSVersion = $os_version 
}} | Select ComputerName,OSName,OSVersion |
Export-Csv "d:\scripts\OS_Details.csv" -NoTypeInformation -Encoding UTF8
