$computers = Get-Content "D:\scripts\htf14.csv"

#New-PSDrive -Name "X" -PSProvider "FileSystem" -Root "\\sdc-sccm12\package sources"
#cd x:

foreach($computer in $computers)
{Set-ExecutionPolicy -executionpolicy Bypass;
  c:\windows\system32\pstools\PsExec.exe \\$computer -accepteula  cmd.exe /c winrm quickconfig -q
}
