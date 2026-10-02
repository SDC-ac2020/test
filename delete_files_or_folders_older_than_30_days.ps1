function Delete-RemoteFile {
    PROCESS {
        $remotePath = "\\$_\c$\Windows\ccmcache"
        if (Test-Path $remotePath) {
            $cutoffDate = (Get-Date).AddDays(-30)
            
            Get-ChildItem -Path $remotePath -Recurse | Where-Object {
                $_.LastWriteTime -lt $cutoffDate
            } | ForEach-Object {
                if ($_.PSIsContainer) {
                    Write-Host "Deleting folder: $($_.FullName)"
                    Remove-Item $_.FullName -Recurse -Force
                } else {
                    Write-Host "Deleting file: $($_.FullName)"
                    Remove-Item $_.FullName -Force
                }
            }
            
            Write-Host "Deletion of items older than 30 days in $remotePath completed."
        } else {
            Write-Host "$remotePath does not exist"
        }
    }
}

Get-Content d:\scripts\a02-del.csv | Delete-RemoteFile