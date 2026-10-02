$computers = Get-Content d:\scripts\3102.csv

#New-PSDrive -Name "X" -PSProvider "FileSystem" -Root "\\sdc-sccm12\package sources"
#cd x:

foreach($computer in $computers){
  c:\windows\system32\pstools\PsExec.exe \\$computer -accepteula  cmd.exe /c pnputil /disable-device "HDAUDIO\SUBFUNC_01&VEN_8086&DEV_281A&NID_0001&SUBSYS_00000000&REV_1000\5&20AAE1D8&0&0002&0000000C"
}
