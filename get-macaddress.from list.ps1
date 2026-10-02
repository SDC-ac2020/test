$computers = Import-Csv -Path "D:\scripts\3079a_test.csv"

foreach ($computer in $computers) {
if (test-Connection -Cn $computer -quiet) {
Get-CimInstance -ComputerName $computer.Name -ClassName Win32_NetworkAdapter -Filter 'NetConnectionStatus=2' | Select-Object -Property Name, Manufacturer, MacAddress
}
else {
        "$computer is not online"
    }
    }

