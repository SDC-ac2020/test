﻿
<# 
.SYNOPSIS
    Initiates an Office Click-to-Run update check and logs the status of the operation.

.DESCRIPTION
    This script checks if a Click-to-Run Office installation exists on the machine and initiates a manual update check.
    It logs key information for troubleshooting, including:
        - Office version
        - Office Update Channel
        - Click-to-Run detection
        - Update check initiation status
    The script writes all output to the console and to a log file located at:
        C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Intune_Office365_Patching_.log

.PARAMETER None
    
     displaylevel=false  or true
     forceappshutdown=false or true
     updatepromptuser=false or true
     updatetoversion = 16.0.11111.1111

.NOTES
    - Running this script does not guarantee updates will be installed; it only triggers the update check.
    - If no updates are available or the client is already up-to-date, the Click-to-Run executables are not modified.
    - Useful for Intune or administrative troubleshooting when Office update logs or registry timestamps are missing.

    Version:         1.1
    Author:          Chander Mani Pandey
    Creation Date:   14 Dec 2025

   Find Author on 
    Youtube:-        https://www.youtube.com/@chandermanipandey8763
    Twitter:-        https://twitter.com/Mani_CMPandey
    LinkedIn:-       https://www.linkedin.com/in/chandermanipandey
#>

$error.Clear()

$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' 

# Initialize Logging
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Intune_Office365_Patching_.log"
$LogFolder = Split-Path $LogPath

# Check if folder exists, if not create it
if (-not (Test-Path $LogFolder)) {
    Try {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
        #Write-Host "Created log folder: $LogFolder"
    } Catch {
        Write-Host "Failed to create log folder: $LogFolder. Error: $_"
        Exit 1
    }
}

Function Write-Log {
    Param([string]$Message)
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message" | Out-File -FilePath $LogPath -Append
}

Write-Log "====================== Running Intune_Office365_CheckForUpdate_Script $(Get-Date -Format 'yyyy/MM/dd') ==================="

# HostName
$DeviceName = hostName
Write-Log "Device Name is :- $DeviceName"
# Office Mgmt COM True or False  Current Office Version

$registryPath  = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
$valueName     = "OfficeMgmtCOM"
$versionName   = "VersionToReport"

# Default values
$officeVersion = "Unknown"

# Try reading Office Version
try {
    $config = Get-ItemProperty -Path $registryPath -ErrorAction Stop
    if ($config.$versionName) {
        $officeVersion = $config.$versionName
    }
}
catch {
    $officeVersion = "Not Found"
}

# Check OfficeMgmtCOM
try {
    $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop

    if ($value.$valueName -eq $true -or $value.$valueName -eq "True") {
        
        Write-Log "Office Version: $officeVersion"
        Write-Log "OfficeMgmtCOM is TRUE"
        #exit 1
    }
    else {
        
        
        Write-Log "Office Version: $officeVersion"
        Write-Log "OfficeMgmtCOM is FALSE"
        #exit 0
    }
}
catch {
        
    Write-Log "Office Version: $officeVersion"
    Write-Log "OfficeMgmtCOM not found"
    #exit 0
}


# Registry path for Office C2R
$regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

# Mapping for GUID URLs to Channel Names
$guidMap = @{
    "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" = "Current Channel"
    "64256afe-f5d9-4f86-8936-8840a6a4f5be" = "Current Channel (Preview)"
    "55336b82-a18d-4dd6-b5f6-9e5095c314a6" = "Monthly Enterprise Channel"
    "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" = "Semi-Annual Enterprise Channel"
    "b8f9b850-328d-4355-9145-c59439a0c4cf" = "Semi-Annual Enterprise Channel (Preview)"
}

# Mapping for short channel names
$channelMap = @{
    "Current"     = "Current Channel"
    "Targeted"    = "Current Channel (Preview)"
    "Production"  = "Monthly Enterprise Channel"
    "Broad"       = "Semi-Annual Enterprise Channel"
    "Validation"  = "Semi-Annual Enterprise Channel (Preview)"
}

if (Test-Path $regPath) {
    $config = Get-ItemProperty -Path $regPath

    $rawChannel = $config.UpdateChannel

    # Extract GUID if URL format
    if ($rawChannel -match "([0-9a-fA-F-]{36})") {
        $guid = $Matches[1]
        $friendly = $guidMap[$guid]
    }
    else {
        $friendly = $channelMap[$rawChannel]
    }

    Write-Log "Office Update Channel Information"
    Write-Log "Channel Name :- $friendly"
    Write-Log "CDN Base URL :- $($config.CDNBaseUrl)"
}
else {
    Write-Log "Office Click-to-Run not found." 
}

# ClickToRun Service Status
$svc = Get-Service -Name ClickToRunSvc -ErrorAction SilentlyContinue
if ($svc) {
    Write-Log "ClickToRun Service Status :- $($svc.Status)"
} else {
    Write-Log "ClickToRun Service not found!"
}
# WinHTTP Proxy
$proxy = netsh winhttp show proxy
Write-Log "WinHTTP Proxy Settings :- $proxy"
$free = (Get-PSDrive C).Free / 1GB
Write-Log "Free Disk Space on C: Drive :- $([math]::Round($free,2)) GB"
$licPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
try {
    $lic = Get-ItemProperty $licPath
    Write-Log "Shared Computer Licensing Enabled :- $($lic.SharedComputerLicensing)"
}
catch {
    Write-Log "Could not read licensing information."
}



# Office installation paths (64-bit and 32-bit)
$officePaths = @(
    "C:\Program Files\Microsoft Office\root\Office16",    # 64-bit
    "C:\Program Files (x86)\Microsoft Office\root\Office16"  # 32-bit
)

# List of Office executables to check
$officeExeFiles = @("WINWORD.EXE","EXCEL.EXE","POWERPNT.EXE","OUTLOOK.EXE","ONENOTE.EXE","MSACCESS.EXE","VISIO.EXE","LYNC.EXE","PUBLISHER.EXE")

$latestUpdateOverall = $null
$allResults = @()

foreach ($path in $officePaths) {
    if (Test-Path $path) {
        foreach ($exe in $officeExeFiles) {
            $fullPath = Join-Path $path $exe
            if (Test-Path $fullPath) {
                $lastModified = (Get-Item $fullPath).LastWriteTime
                $allResults += [PSCustomObject]@{
                    Executable = $exe
                    Path = $fullPath
                    LastModified = $lastModified
                }
                if ($latestUpdateOverall -eq $null -or $lastModified -gt $latestUpdateOverall) {
                    $latestUpdateOverall = $lastModified
                }
                Write-Log "Found: $exe  LastModified: $lastModified  Path: $fullPath"
            }
        }
    } else {
        Write-Log "Office folder not found: $path"
    }
}

if ($allResults.Count -gt 0) 
{
        Write-Log "Approximate Last Office Update Applied on this machine: $latestUpdateOverall"
} else {
    Write-Log "No Office executables found in standard installation paths."
}

# Check for Office Click-To-Run Products 
$OC2R = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Microsoft Office Professional Plus 2019*" -or $_.DisplayName -like "*Microsoft Office Professional Plus 2021*" -or $_.DisplayName -like "*Microsoft Office 365*" -or $_.DisplayName -like "*Microsoft 365*"} 

# Update Click-To-Run Office Products
if ($OC2R -ne $null) { 
    if (Test-Path "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe") { 
        Write-Log "Click-To-Run Office detected."
        Write-Log "Initiating Click-To-Run Office check for update."
        Write-Host "Click-To-Run Office detected. Initiating check for update." 
        & "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user displaylevel=false forceappshutdown=false updatepromptuser=false
        
        # Test and Update true/false as per your requirement
        #updatetoversion = 16.0.11111.1111
       
        Write-Log "Office Check for update successfully initiated."
    } 
    else { 
        Write-Log  "No Click-To-Run Office detected."
        Write-Host "No Click-To-Run Office detected." 
    } 
} 

Write-Log "============================================================================="