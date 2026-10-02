# Import the list of computer names from the CSV file
$Computers = Import-Csv -Path "d:\scripts\3079a.txt"

# Iterate through each computer and update the Windows Update module
foreach ($Computer in $Computers) {
    $Target = $Computer.ComputerName
    Update-WUModule -ComputerName $Target -Local
}
