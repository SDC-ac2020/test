Get-Content D:\scripts\notepad.pp.csv |
    Select-Object @{
        Name = 'ComputerName'
        Expression = { $_ }
    }, @{
        Name = 'RegistryKeyExists'
        Expression = {
            try {
                $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
                    [Microsoft.Win32.RegistryHive]::LocalMachine,
                    $_
                )
                $null -ne $Reg.OpenSubKey(
                    'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7349B4F3-02E1-4234-A67A-FA85B33B67AF}'
                )
            }
            catch {
                $false
            }
        }
    } | Export-Csv D:\scripts\NotepadPP_Check.csv -NoTypeInformation