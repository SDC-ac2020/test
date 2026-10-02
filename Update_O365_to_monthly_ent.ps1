$computers = @("pd-systems-awv2", "pd-systems-nbv2", "pd-systems-sbv2")

Invoke-Command -ComputerName $computers -ScriptBlock {

    $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

    if (-not (Test-Path $regPath)) {
        $regPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    }

    $cdn = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).CDNBaseUrl
    $channelId = if ($cdn) { ($cdn -split "/")[-1] }

    $monthlyEnterpriseGUID = "55336b82-a18d-4dd6-b5f6-9e5095c314a6"

    if ($channelId -ne $monthlyEnterpriseGUID) {

        $officeC2R = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

        if (Test-Path $officeC2R) {

            Start-Process $officeC2R -ArgumentList "/changesetting Channel=MonthlyEnterprise" -Wait
            Start-Process $officeC2R -ArgumentList "/update user" -Wait

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Status       = "Updated to Monthly Enterprise"
            }
        }
        else {
            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Status       = "OfficeC2RClient not found"
            }
        }
    }
    else {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Status       = "Already compliant"
        }
    }

}
