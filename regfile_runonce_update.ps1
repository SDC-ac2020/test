$csv = Import-Csv -Path C:\scripts\3079a_test.csv 

foreach ($computer in $csv) {

  $regFile = @"

Windows Registry Editor Version 5.00 

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce]

"Install DMI_Edit"="C:\\\\DMI\\\\Edit DMI x64.bat"

"@

  Invoke-Command -ComputerName $computer.Name -ScriptBlock {
    param($regFile) 
    $regFile | Out-File $env:temp\a.reg
    reg.exe import $env:temp\a.reg
  } -ArgumentList $regFile

}