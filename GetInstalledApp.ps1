function Get-InstalledApplication {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [string]$Name,
        [Switch]$Exact,
        [Switch]$WildCard,
        [Switch]$RegEx,
        [string]$ProductCode,
        [Switch]$IncludeUpdatesAndHotfixes
    )
    $appReg = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $appRegWow = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $apps = Get-ItemProperty $appReg, $appRegWow | Where-Object {$_.DisplayName -ne $null}

    if ($ProductCode) {
        $apps = $apps | Where-Object {$_.PSChildName -eq $ProductCode}
    }
    if ($Name) {
        if ($Exact) {
            $apps = $apps | Where-Object {$_.DisplayName -eq $Name}
        }
        elseif ($WildCard) {
            $apps = $apps | Where-Object {$_.DisplayName -like $Name}
        }
        elseif ($RegEx) {
            $apps = $apps | Where-Object {$_.DisplayName -match $Name}
        }
        else {
            $apps = $apps | Where-Object {$_.DisplayName -like "*$Name*"}
        }
    }
    if (-not $IncludeUpdatesAndHotfixes) {
        $apps = $apps | Where-Object {$_.DisplayName -notlike 'KB*'}
    }

    $appInfo = foreach ($app in $apps) {
        $appArch = if ($app.PSPath.Contains('WOW6432Node')) {'32-bit'} else {'64-bit'}
        $appInstallDate = try {
            if ($app.InstallDate) {[datetime]::ParseExact($app.InstallDate, 'yyyyMMdd', $null)} else {$null}
        } catch {
            $null
        }
        [PSCustomObject]@{
            Publisher = $app.Publisher
            DisplayName = $app.DisplayName
            DisplayVersion = $app.DisplayVersion
            ProductCode = $app.PSChildName
            UninstallString = $app.UninstallString
            InstallSource = $app.InstallSource
            InstallLocation = $app.InstallLocation
            InstallDate = $appInstallDate
            Architecture = $appArch
        }
    }
    return $appInfo
}

