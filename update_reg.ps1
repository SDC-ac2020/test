$regFile = @"
 Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce]
"Install DMI_Edit"="C:\\DMI\\Edit DMI x64.bat"
"@

Invoke-Command -ComputerName computer -ScriptBlock {param($regFile) $regFile | out-file $env:temp\a.reg; 
    reg.exe import $env:temp\a.reg } -ArgumentList $regFile