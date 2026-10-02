# Import the list of computer names from the CSV file
$Computers = Import-Csv -Path "d:\scripts\Computers.csv"

# Create an empty array to store the results
$Results = @()

foreach ($Computer in $Computers) {
    $Target = $Computer.ComputerName
    $WUHistory = Get-WUHistory -ComputerName $Target -MaxDate "14-02-2024" | Where-Object { $_.Result -like "*Failed*" }
    
    # Convert the Updates property to a semicolon-separated string
    $UpdatesString = ($WUHistory | ForEach-Object { "$($_.Date); $($_.KB); $($_.Title)" })

    # Add the results to the array
    $Results += [PSCustomObject]@{
        ComputerName = $Target
        Updates = $UpdatesString
    }
}

# Export the results to a CSV file with semicolon delimiter
$Results | Export-Csv -Path "d:\scripts\UpdateResults.csv" -NoTypeInformation -Delimiter ";"

Write-Host "Results exported to UpdateResults.csv"
