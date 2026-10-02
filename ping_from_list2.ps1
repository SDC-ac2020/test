$ServerNames = Get-Content "d:\scripts\htf13.txt
foreach ($name in $ServerNames) {
    if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue) {
        Write-Host "$name,up"
    } else {
        Write-Host "$name,down"
    }
}
