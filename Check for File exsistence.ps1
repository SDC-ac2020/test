Get-Content d:\scripts\2102.csv | `
   Select-Object @{Name='ComputerName';Expression={$_}},@{Name='FolderExist';Expression={ Test-Path "\\$_\c$\users\Public\surpass\SecureClient_CANDG"}}

