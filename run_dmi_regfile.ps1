    $computers = Get-Content C:\scripts\3079a_test.csv

    $HostedRegFile = "C:\Scripts\DMI\dmi_edit.reg"

    foreach ($computer in $computers)

    {

    $newfile = "\\$Computer\c`$\DMI\dmi_edit.reg"

    New-Item -ErrorAction SilentlyContinue -ItemType directory -Path \\$computer\C$\DMI

    Copy-Item $HostedRegFile -Destination $newfile

    Invoke-Command -ComputerName $computer -ScriptBlock {

    Start-Process -filepath "C:\windows\regedit.exe" -argumentlist "/s C:\DMI\Dmi_edit.reg"

    }

    }