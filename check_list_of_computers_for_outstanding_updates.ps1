# Import the list of computer names from the CSV file
$Computers = Import-Csv -Path "d:\scripts\Computers.csv"

foreach ($Computer in $Computers) {
    $Target = $Computer.ComputerName
    $Updates = Get-HotFix -ComputerName $Target | Where-Object { $_.Description -notlike "*Installed*" }
    if ($Updates) {
        Write-Host "Outstanding updates for $Target"
        $Updates | Format-Table -Property HotFixID, Description, InstalledOn
    } else {
        Write-Host "No outstanding updates found for $Target."
    }
}
