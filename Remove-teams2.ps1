$TimeoutSeconds = 60

foreach ($Computer in $Computers) {

    $ComputerName = $Computer.ComputerName

    Add-Content $LogFile "[$(Get-Date)] Starting $ComputerName"

    if (-not (Test-Connection $ComputerName -Count 1 -Quiet)) {

        Add-Content $LogFile "[$(Get-Date)] OFFLINE $ComputerName"

        $Results += [PSCustomObject]@{
            ComputerName = $ComputerName
            Status       = "Offline"
            Message      = "Ping failed"
            Timestamp    = Get-Date
        }

        $Results | Export-Csv $ReportFile -NoTypeInformation
        continue
    }

    try {

        $Job = Invoke-Command `
            -ComputerName $ComputerName `
            -AsJob `
            -ScriptBlock {

                Function Remove-App([String]$AppName){

                    $PackageFullName =
                        (Get-AppxPackage -AllUsers $AppName -ErrorAction SilentlyContinue).PackageFullName

                    if ($PackageFullName) {

                        Remove-AppxPackage `
                            -Package $PackageFullName `
                            -AllUsers `
                            -ErrorAction SilentlyContinue
                    }

                    $ProvisionedPackage =
                        Get-AppxProvisionedPackage -Online |
                        Where-Object { $_.DisplayName -eq $AppName }

                    if ($ProvisionedPackage) {

                        Remove-AppxProvisionedPackage `
                            -Online `
                            -PackageName $ProvisionedPackage.PackageName `
                            -ErrorAction SilentlyContinue
                    }
                }

                $Start = Get-Date

                Remove-App "MSTeams"
                Remove-App "MicrosoftTeams"

                $End = Get-Date

                [PSCustomObject]@{
                    Duration = ($End - $Start).TotalSeconds
                    Result   = "Success"
                }
            }

        $Completed = Wait-Job $Job -Timeout $TimeoutSeconds

        if ($Completed) {

            $Output = Receive-Job $Job

            Add-Content $LogFile "[$(Get-Date)] SUCCESS $ComputerName"

            $Results += [PSCustomObject]@{
                ComputerName = $ComputerName
                Status       = "Success"
                DurationSecs = $Output.Duration
                Message      = "Teams removed"
                Timestamp    = Get-Date
            }
        }
        else {

            Add-Content $LogFile "[$(Get-Date)] TIMEOUT $ComputerName"
            Add-Content $LogFile "[$(Get-Date)] Job exceeded $TimeoutSeconds seconds"

            Stop-Job $Job -Force
            Remove-Job $Job -Force

            $Results += [PSCustomObject]@{
                ComputerName = $ComputerName
                Status       = "Timed Out"
                DurationSecs = $TimeoutSeconds
                Message      = "Remote command exceeded timeout"
                Timestamp    = Get-Date
            }

            continue
        }

        Remove-Job $Job -Force

    }
    catch {

        Add-Content $LogFile "[$(Get-Date)] FAILED $ComputerName"
        Add-Content $LogFile "[$(Get-Date)] ERROR: $($_.Exception.Message)"

        $Results += [PSCustomObject]@{
            ComputerName = $ComputerName
            Status       = "Failed"
            Message      = $_.Exception.Message
            Timestamp    = Get-Date
        }
    }

    $Results | Export-Csv $ReportFile -NoTypeInformation
    $Results | Group-Object Status | Select-Object Name,Count
}
