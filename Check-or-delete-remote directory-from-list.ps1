
function Remove-RemoteFolder {
    param (
        [string]$ComputerName
    )

    $Path = "\\$ComputerName\c$\Users\Public\Surpass\SecureClient_CANDG"

    $Result = [PSCustomObject]@{
        ComputerName = $ComputerName
        Path         = $Path
        Exists       = $false
        Action       = "Not attempted"
        Error        = ""
    }

    try {
        if (Test-Path $Path) {
            $Result.Exists = $true
            #  Uncomment the line below if you wish delete the files 
            #  and change the $Result.Action to "Deleted" 
            #  Remove-Item $Path -Recurse -Force
            $Result.Action = "Exists (not deleted)"
        }
        else {
            $Result.Action = "Folder not found"
        }
    }
    catch {
        $Result.Action = "Failed"
        $Result.Error  = $_.Exception.Message
    }

    return $Result
}

# Import list of remote PCs
$Computers = Get-Content "D:\scripts\2102.csv"

# Run and collect results
$Results = foreach ($Computer in $Computers) {
    Remove-RemoteFolder -ComputerName $Computer
}

# Export to CSV
$Results | Export-Csv "D:\scripts\RemoteFolderResults.csv" -NoTypeInformation
