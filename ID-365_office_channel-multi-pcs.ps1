$computers = @("pd-support-aav2","pd-systems-awv2","pd-systems-mmv2")

Invoke-Command -ComputerName $computers -ScriptBlock {

    $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

    if (-not (Test-Path $regPath)) {
        $regPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    }

    $ReportedVersion = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).VersionToReport
    $CDNBaseUrl = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).CDNBaseUrl

    $ChannelId = if ($CDNBaseUrl) { ($CDNBaseUrl -split "/")[-1] }

    switch ($ChannelId) {
        "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" { $Channel = 'Current (Monthly)' }
        "64256afe-f5d9-4f86-8936-8840a6a4f5be" { $Channel = 'Current Preview (Insider)' }
        "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" { $Channel = 'Semi-Annual Enterprise' }
        "b8f9b850-328d-4355-9145-c59439a0c4cf" { $Channel = 'Semi-Annual Enterprise Preview' }
        "55336b82-a18d-4dd6-b5f6-9e5095c314a6" { $Channel = 'Monthly Enterprise' }
        "5440fd1f-7ecb-4221-8110-145efaa6372f" { $Channel = 'Beta' }
        default { $Channel = "Unknown" }
    }

    [PSCustomObject]@{
        ComputerName   = $env:COMPUTERNAME
        OfficeVersion  = $ReportedVersion
        Channel        = $Channel
    }

}
