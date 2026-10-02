###############################################################################
# SUPER‑RELIABLE SCCM APP DEPLOYMENT PARSER (STATEFUL, TAILORED FOR VINCE)
###############################################################################

param (
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$AppFilter = "",
    [int]$LastHours = 672,
    [string]$OutputCsv = "D:\Scripts\SCCM-AppDeploymentResults.csv",
    [string]$OutputJson = "D:\Scripts\SCCM-AppDeploymentResults.json"
)

Write-Host "`n=== SCCM Deployment Log Parser (STATEFUL VERSION) ===`n" -ForegroundColor Cyan

$LogRoot = "\\$ComputerName\C$\Windows\CCM\Logs"
$LogFiles = @("AppEnforce.log","AppDiscovery.log","AppIntentEval.log")
$Cutoff   = (Get-Date).AddHours(-$LastHours)
$Results  = @()

# ----------------------------
# Timestamp parser (CMTrace)
# ----------------------------
function Get-Timestamp {
    param($Line)
    if ($Line -match 'Date="([^"]+)" Time="([^"]+)"') {
        try {
            return [datetime]::ParseExact("$($matches[1]) $($matches[2])","MM-dd-yyyy HH:mm:ss.fff",$null)
        } catch {
            return $null
        }
    }
    return $null
}

# ----------------------------
# Result collector
# ----------------------------
function Add-Result {
    param ($AppName, $Status, $ExitCode, $Timestamp, $LogSource, $RawLine)

    if ($AppFilter -and $AppName -notmatch $AppFilter) { return }

    $Results += [pscustomobject]@{
        Computer  = $ComputerName
        AppName   = $AppName
        Status    = $Status
        ExitCode  = $ExitCode
        Timestamp = $Timestamp
        LogSource = $LogSource
        RawLine   = $RawLine.Trim()
    }
}

Write-Host "Reading logs..." -ForegroundColor Yellow

foreach ($log in $LogFiles) {

    $FullPath = Join-Path $LogRoot $log
    if (!(Test-Path $FullPath)) { continue }

    Write-Host " → $log" -ForegroundColor Gray

    # Handle UTF8 / UTF16
    $Content = Get-Content $FullPath -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($Content -eq $null -or $Content.Count -eq 0) {
        $Content = Get-Content $FullPath -Encoding Unicode -ErrorAction SilentlyContinue
    }

    # ---------------------------------------
    # STATE MACHINE — tracks active installs
    # ---------------------------------------
    $CurrentAppName = $null
    $CurrentStartTimestamp = $null

    foreach ($Line in $Content) {

        $Timestamp = Get-Timestamp -Line $Line
        if ($Timestamp -and $Timestamp -lt $Cutoff) { continue }

        # -----------------------------------
        # Extract App Name (two formats)
        # -----------------------------------
        if ($Line -match 'App DT "([^"]+)"') {
            $AppLineName = $matches[1]
        } elseif ($Line -match 'Detected app deployment type ([^\(]+)\(') {
            $AppLineName = $matches[1]
        } else {
            $AppLineName = $null
        }

        # -----------------------------------
        # DETECTION SUCCESS
        # -----------------------------------
        if ($Line -match 'Discovered application' -or
            $Line -match 'Detected app deployment type' -or
            $Line -match 'Current State = Installed') {

            Add-Result $AppLineName "Detected" "" $Timestamp $log $Line
            continue
        }

        # -----------------------------------
        # DETECTION FAILURE
        # -----------------------------------
        if ($Line -match 'Application not discovered' -or
            $Line -match 'Did not detect app deployment type' -or
            $Line -match 'Current State = NotInstalled') {

            Add-Result $AppLineName "Not Detected" "" $Timestamp $log $Line
            continue
        }

        # -----------------------------------
        # INSTALL START EVENT
        # -----------------------------------
        if ($Line -match 'Starting Install enforcement for App DT "') {

            $CurrentAppName = $AppLineName
            $CurrentStartTimestamp = $Timestamp

            Add-Result $CurrentAppName "Install Started" "" $Timestamp $log $Line
            continue
        }

        # -----------------------------------
        # INSTALL RUNNING (Command line execution)
        # -----------------------------------
        if ($Line -match 'Executing Command line:') {
            Add-Result $CurrentAppName "Executing" "" $Timestamp $log $Line
            continue
        }

        if ($Line -match 'Waiting for process') {
            Add-Result $CurrentAppName "Waiting" "" $Timestamp $log $Line
            continue
        }

        # -----------------------------------
        # INSTALL SUCCESS
        # -----------------------------------
        if ($Line -match 'Matched exit code 0' -or
            $Line -match 'Found a match in the success exit codes' -or
            $Line -match 'Status is switching to Success') {

            Add-Result $CurrentAppName "Success" 0 $Timestamp $log $Line
            continue
        }

        if ($Line -match 'App enforcement completed .* for App DT') {
            Add-Result $CurrentAppName "Success" 0 $Timestamp $log $Line
            continue
        }

        # -----------------------------------
        # INSTALL FAILURE (Exit codes)
        # -----------------------------------
        if ($Line -match 'Returning:? 0x([0-9A-Fa-f]+)') {

            $Exit = $matches[1]
            Add-Result $CurrentAppName "Failure" $Exit $Timestamp $log $Line

            # Reset state after failure
            $CurrentAppName = $null
            continue
        }

        if ($Line -match 'Status is switching to Failure') {
            Add-Result $CurrentAppName "Failure" "" $Timestamp $log $Line
            continue
        }

    }
}

# -----------------------------------
# EXPORT RESULTS
# -----------------------------------
if ($Results.Count -eq 0) {
    Write-Host "`nNo matching deployment events found." -ForegroundColor Yellow
    exit
}

Write-Host "`nExporting results..." -ForegroundColor Cyan

$Results | Sort-Object Timestamp | Export-Csv $OutputCsv -NoTypeInformation
$Results | ConvertTo-Json -Depth 5 | Out-File $OutputJson

Write-Host '`n✓ Complete' -ForegroundColor Green
Write-Host 'CSV saved to: $OutputCsv'
Write-Host 'JSON saved to: $OutputJson'

