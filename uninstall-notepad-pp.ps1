$computers = Get-Content "D:\scripts\notepad.pp.csv"

foreach ($computer in $computers) {

    if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Host "$computer is offline" -ForegroundColor Yellow
        continue
    }

    Write-Host "$computer is online. Starting Notepad++ uninstall..." -ForegroundColor Green

    Invoke-Command -ComputerName $computer -ScriptBlock {

        $paths = @(
            "C:\Program Files\Notepad++\uninstall.exe",
            "C:\Program Files (x86)\Notepad++\uninstall.exe"
        )

        foreach ($path in $paths) {
            if (Test-Path $path) {
                Start-Process -FilePath $path -ArgumentList "/S" -Wait
                Write-Output "Notepad++ uninstalled from $env:COMPUTERNAME"
                return
            }
        }

        Write-Output "Notepad++ not found on $env:COMPUTERNAME"
    }
}
