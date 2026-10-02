#Requires -Version 5.1

<#
.SYNOPSIS
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.DESCRIPTION
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.EXAMPLE
    No Parameters Needed
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.EXAMPLE
    -Restart
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2. Does Restart the computer.
.OUTPUTS
    String[]
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Could possibly run on Windows 7 and Server 2008 R2, but PowerShell 5.1 would be required.
    Release Notes:
    Initial Release
By using this script, you indicate your acceptance of the following legal terms as well as our Terms of Use at https://www.ninjaone.com/terms-of-use.
    Ownership Rights: NinjaOne owns and will continue to own all right, title, and interest in and to the script (including the copyright). NinjaOne is giving you a limited license to use the script in accordance with these legal terms. 
    Use Limitation: You may only use the script for your legitimate personal or internal business purposes, and you may not share the script with another party. 
    Republication Prohibition: Under no circumstances are you permitted to re-publish the script in any script library or website belonging to or under the control of any other software provider. 
    Warranty Disclaimer: The script is provided “as is” and “as available”, without warranty of any kind. NinjaOne makes no promise or guarantee that the script will be free from defects or that it will meet your specific needs or expectations. 
    Assumption of Risk: Your use of the script is at your own risk. You acknowledge that there are certain inherent risks in using the script, and you understand and assume each of those risks. 
    Waiver and Release: You will not hold NinjaOne responsible for any adverse or unintended consequences resulting from your use of the script, and you waive any legal or equitable rights or remedies you may have against NinjaOne relating to your use of the script. 
    EULA: If you are a NinjaOne customer, your use of the script is subject to the End User License Agreement applicable to you (EULA).
#>

[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    
    @(
        [PSCustomObject]@{
            Protocol = 'SSL 2.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'SSL 3.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.1'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.2'
            Value    = 1
            Default  = 0
        }
    ) | ForEach-Object {
        $RegServerBase = "HKLM:SYSTEMCurrentControlSetControlSecurityProvidersSCHANNELProtocols$($_.Protocol)Server"
        $RegClientBase = "HKLM:SYSTEMCurrentControlSetControlSecurityProvidersSCHANNELProtocols$($_.Protocol)Client"
        
        New-Item $RegServerBase -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegServerBase -Name 'Enabled' -Value $($_.Value) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegServerBase -Name 'DisabledByDefault' -Value $($_.Default) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        
        New-Item $RegClientBase -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegClientBase -Name 'Enabled' -Value $($_.Value) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegClientBase -Name 'DisabledByDefault' -Value $($_.Default) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null

        $State = if (
            $(Get-ItemPropertyValue -Path $RegServerBase -Name 'Enabled') -eq 0 -and
            $(Get-ItemPropertyValue -Path $RegServerBase -Name 'DisabledByDefault') -eq 1
        ) { 'disabled' } else { 'enabled' }

        Write-Host "$($_.Protocol) has been $State."
    }

    Write-Host "Please reboot for settings to take effect."
}
end {}