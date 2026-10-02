# Define the path to the CSV file
$csvPath = "d:\scripts\2102.csv"

# Import computer names from the CSV file
$computers = Import-Csv -Path $csvPath

# Define the path variable
$path = "C:\users\Public\Surpass\"

# Loop through each computer name and run the Get-ChildItem command
foreach ($computer in $computers) {
    $computerName = $computer.ComputerName
    Write-Host "Searching on $computerName..."
    
    # Use Invoke-Command to run the command on the remote computer
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        param ($path)
        Get-ChildItem -Path $path -Recurse -Filter "*candg*"
    } -ArgumentList $path -ErrorAction SilentlyContinue | 
    Select-Object @{Name='ComputerName';Expression={$computerName}}, Name, FullName
}
