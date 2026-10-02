# Path to output CSV file
$outputFile = "c:\scripts\output3.csv"

# Array to store results
$results = @() 

# Get list of computer names somehow
$computerNames = Get-Content -Path c:\scripts\computers.txt 

foreach ($computer in $computerNames) {

  # Get serial number
  $serial = Get-WmiObject -Class Win32_Bios -ComputerName $computer | Select-Object -ExpandProperty SerialNumber

  # Get asset tag
  $assetTag = Get-WmiObject -Namespace root\CIMV2 -Class Win32_SystemEnclosure -ComputerName $computer | Select-Object -ExpandProperty SMBIOSAssetTag

  # Add to array 
  $results += [PSCustomObject]@{
    ComputerName = $computer
    SerialNumber = $serial
    AssetTag = $assetTag
  }
}


# Export array to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation