function delete-remotefile {
PROCESS {
$file = "\\$_\c$\\Users\Public\Surpass\"
if (test-path $file)
{
echo "$file exists"
Remove-Item $file -Recurse -force
echo "$file deleted"
}
}
}
Get-Content d:\scripts\2104.csv | delete-remotefile