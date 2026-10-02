$profilepath = Read-Host -Prompt 'Please enter profile path'
remove-item "$profilepath.v6\*" -force -recurse
copy-item "\\sdc-newmedia\resources$\Default User win10\*" "$profilepath.v6" -force
$date = Get-Date
$v = get-itemproperty -literalpath "$profilepath.v6\ntuser.dat"
$v.LastWriteTime = $date