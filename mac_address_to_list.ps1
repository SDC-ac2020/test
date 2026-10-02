$computers = Import-Csv -Path "D:\scripts\3079a.csv"
$results = @()

foreach ($computer in $computers) {
   
        $networkAdapter = Get-CimInstance -ComputerName $computer.Name -ClassName Win32_NetworkAdapter -Filter 'NetConnectionStatus=2' | Select-Object -Property Name, Manufacturer, MacAddress
        $results += [PSCustomObject]@{
            ComputerName = $computer.Name
            MacAddress = $networkAdapter.MacAddress
        }
     
}

$results | Export-Csv -Path "D:\scripts\results.csv" -NoTypeInformation
