#1 Create log directory and log file
#2 Check for PSWindowsUpdate RegKey and create if it does not exist
#3 Check for PSWindowsUpdate module
#4 Import PSWindowsUpdate module
#5 If reboot is required and log result to registry (Reboot RequiredDetection Method) and stop PS script
#6 Else If reboot is not required log result to registry (No Reboot RequiredDetection Method), then do the following.
    #7 If Check for updates, if updates are available, download and install and log results to log file
        #8 Check for any failed updates and log results to registry (Failed Updates Detection Method), and stop PS script
    #9 Else If no updates are available, log result to registry (No Updates Available Detection Method) and stop PS script
 
$LogDir = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile = "$LogDir\WindowsUpdate-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
 
$RegPath = "HKLM:\SOFTWARE\Policies\SDC\PSWindowsUpdate"
 
# Ensure registry path exists
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
 
# Ensure module
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "PSWindowsUpdate module not found"
    Stop-Transcript
    return
}
 
Import-Module PSWindowsUpdate
 
# Check reboot requirement
$RebootRequired = Get-WURebootStatus -Silent
#Write-Host "Checked if reboot is required"
 
if ($RebootRequired) {
    Write-Host "Reboot is required"
 
    New-ItemProperty `
        -Path $RegPath `
        -Name "RebootIsRequired" `
        -Value "Yes" `
        -PropertyType String `
        -Force
}
else {
    #Write-Host "Reboot is not required"
 
    #Set to "No"
    New-ItemProperty `
        -Path $RegPath `
        -Name "RebootIsRequired" `
        -Value "No" `
        -PropertyType String `
        -Force
 
    # Check for updates and write to log file
    $Updates = Get-WindowsUpdate `
        -MicrosoftUpdate `
        -IgnoreUserInput `
        -Verbose 4>> $LogFile
 
    if ($Updates.Count -gt 0) {
 
        #Write-Host "There are updates required"
 
        New-ItemProperty `
            -Path $RegPath `
            -Name "NoUpdatesAvailable" `
            -Value "False" `
            -PropertyType String `
            -Force
 
        # Install updates
        $InstallResults = Get-WindowsUpdate `
            -MicrosoftUpdate `
            -Install `
            -AcceptAll `
            -IgnoreReboot `
            -Verbose 4>> $LogFile
 
        New-ItemProperty `
            -Path $RegPath `
            -Name "UpdatesInstalled" `
            -Value "True" `
            -PropertyType String `
            -Force
 
        # Check failed updates
        $FailedUpdates = $InstallResults | Where-Object { $_.Result -ne "Installed" }
 
        if ($FailedUpdates) {
 
            #Write-Host "There are failed updates"
            $FailedTitles = ($FailedUpdates | Select-Object -ExpandProperty Title) -join "; "
 
            New-ItemProperty `
                -Path $RegPath `
                -Name "FailedUpdatesList" `
                -Value $FailedTitles `
                -PropertyType String `
                -Force
        }
    }
    else {
        #Write-Host "There are no updates required"
 
        New-ItemProperty `
            -Path $RegPath `
            -Name "NoUpdatesAvailable" `
            -Value "True" `
            -PropertyType String `
            -Force
    }
}