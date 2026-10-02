# Input and output files
$InputCsv  = "C:\scripts\2104-teams.csv"
$OutputCsv = "C:\scripts\TeamsVersions.csv"

$Results = @()

# Import computer list
$Computers = Import-Csv $InputCsv

foreach ($Item in $Computers) {

    $Computer = $Item.ComputerName

    Write-Host "Processing $Computer..." -ForegroundColor Cyan

    try {
        $Result = & "C:\Scripts\Get-TeamsVersion.ps1" -Computer $Computer

        if ($Result) {
            $Results += $Result
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Computer         = $Computer
            Profile          = "ERROR"
            ProfilePath      = ""
            Arch             = ""
            Type             = ""
            Version          = ""
            Environment      = ""
            Ring             = ""
            InstallDate      = ""
            Error            = $_.Exception.Message
        }
    }
}

# Export results
$Results | Export-Csv $OutputCsv -NoTypeInformation

Write-Host "Results exported to $OutputCsv" -ForegroundColor Green
