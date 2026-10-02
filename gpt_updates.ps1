# Define the input and output file paths
$inputCSV = "D:\scripts\computers.csv"
$outputCSV = "d:\temp\3079a_updates.csv"

# Read computer names from CSV
$computers = Import-Csv $inputCSV | Select-Object -ExpandProperty ComputerName

# Initialize an empty array to store update history
$updateHistory = @()

# Loop through each computer
foreach ($computer in $computers) {
    # Get Windows Update history for the computer excluding security updates
    $history = Get-WUHistory -Computer $computer -MaxDate "14-02-2024" | Where-Object { $_.Title -notlike "*Security*" }
    
    # Append the update history for this computer to the array
    $updateHistory += $history
}

# Export the combined update history to a new CSV file
$updateHistory | Export-Csv -Path $outputCSV -NoTypeInformation
