# Import the list of computer names from the CSV file
$Computers = Import-Csv -Path "d:\scripts\Computers.csv"

# Create an empty array to store the results
$Results = @()

foreach ($Computer in $Computers) {
    $Target = $Computer.ComputerName
    $Updates = Get-HotFix -ComputerName $Target | Where-Object { $_.Description -notlike "*Installed*" }
    if ($Updates) {
        # Add the results to the array
        $Results += [PSCustomObject]@{
            ComputerName = $Target
            PendingUpdates = $Updates.Description -join ', '  # Combine pending updates into a single string
        }
    } else {
        Write-Host "No outstanding updates found for $Target."
    }
}

# Export the results to a CSV file
$Results | Export-Csv -Path "d:\scripts\PendingUpdatesReport.csv" -NoTypeInformation

Write-Host "Results exported to PendingUpdatesReport.csv"

