
<#
.SYNOPSIS
Create (or update) a MECM/SCCM device collection with Direct Membership from a CSV export.

.DESCRIPTION
- Parses a CSV that contains a title line followed by headers:
  Name, DNS Name, Last seen, Operating System
- Extracts device names from the 'Name' column.
- Connects to site code SD1, creates/uses collection "TightVNC update".
- Adds matching devices as Direct Membership rules.
- Logs results to a timestamped CSV.

.PARAMETER CsvPath
Path to the export CSV (default: .\export-tvm-vulnerability-exposed-assets-jan-27.csv)

.PARAMETER SiteCode
MECM site code. Default: SD1

.PARAMETER CollectionName
Target collection. Default: "TightVNC update"

.PARAMETER LimitingCollection
Limiting collection. Default: "All Systems"

.PARAMETER WhatIf
Dry run—no membership changes are made.

.EXAMPLE
.\Create-DirectCollectionFromExport.ps1 -CsvPath .\export-tvm-vulnerability-exposed-assets-jan-27.csv -WhatIf

.EXAMPLE
.\Create-DirectCollectionFromExport.ps1 -CsvPath .\export-tvm-vulnerability-exposed-assets-jan-27.csv
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$CsvPath = ".\",
    [string]$SiteCode = "SD1",
    [string]$CollectionName = "TighVNC Update",
    [string]$LimitingCollection = "All Systems"
)

function Get-DeviceNamesFromExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "CSV not found: $Path"
    }

    # --- FIXED: Only use -Raw; no -Delimiter. Then split lines in-memory. ---
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    # Normalize newlines and split
    $lineArray = ($text -replace "`r`n", "`n").Split("`n")

    # Find the header row that starts with Name,DNS Name
    $headerLine = $lineArray | ForEach-Object { $_.Trim() } | Where-Object { $_ -like 'Name,DNS Name*' } | Select-Object -First 1
    if (-not $headerLine) {
        throw "Could not find header row that starts with 'Name,DNS Name' in $Path"
    }
    $headerIdx = ($lineArray | ForEach-Object { $_.Trim() }).IndexOf($headerLine)

    # Reconstruct CSV content from header to end and parse
    $csvText = ($lineArray[$headerIdx..($lineArray.Count-1)]) -join "`n"
    try {
        $data = $csvText | ConvertFrom-Csv -ErrorAction Stop
    } catch {
        throw "Failed to parse CSV from header row. $($_.Exception.Message)"
    }

    if (-not ($data | Get-Member -Name Name -MemberType NoteProperty -ErrorAction SilentlyContinue)) {
        throw "CSV does not contain a 'Name' column."
    }

    $names =
        $data |
        Select-Object -ExpandProperty Name |
        ForEach-Object { ($_ | Out-String).Trim() } |
        Where-Object { $_ -and $_.Length -gt 0 } |
        Sort-Object -Unique

    return ,$names
}

function Ensure-CMModuleAndSiteDrive {
    param([string]$SiteCode)

    # Load ConfigMgr module (assumes admin console installed)
    $cmPs1 = Join-Path $env:SMS_ADMIN_UI_PATH "..\ConfigurationManager.psd1"
    if (-not (Test-Path $cmPs1)) {
        throw "Could not find ConfigurationManager.psd1 via SMS_ADMIN_UI_PATH. Is the MECM console installed?"
    }
    Import-Module $cmPs1 -ErrorAction Stop

    # Switch to site drive (e.g., SD1:)
    $siteDrive = "$SiteCode`:"
    if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root (Get-PSDrive -PSProvider CMSite).Root | Out-Null
    }
    Set-Location $siteDrive
}

function Ensure-Collection {
    param(
        [string]$Name,
        [string]$LimitingCollection
    )
    $col = Get-CMDeviceCollection -Name $Name -ErrorAction SilentlyContinue
    if (-not $col) {
        Write-Verbose "Creating collection '$Name' (limit: '$LimitingCollection')"
        $col = New-CMDeviceCollection -Name $Name -LimitingCollectionName $LimitingCollection -ErrorAction Stop
    }
    return $col
}

# --- Main flow ---
$logPath = "d:\scripts\Create-DirectCollectionFromExport_log_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date)
$log = New-Object System.Collections.Generic.List[object]

try {
    Write-Host "Reading devices from: $CsvPath" -ForegroundColor Cyan
    $deviceNames = Get-DeviceNamesFromExport -Path $CsvPath
    if (-not $deviceNames -or $deviceNames.Count -eq 0) {
        throw "No device names found in CSV."
    }
    Write-Host "Found $($deviceNames.Count) device name(s) in CSV." -ForegroundColor Green

    Write-Host "Connecting to site: $SiteCode" -ForegroundColor Cyan
    Ensure-CMModuleAndSiteDrive -SiteCode $SiteCode

    Write-Host "Ensuring collection: $CollectionName" -ForegroundColor Cyan
    $collection = Ensure-Collection -Name $CollectionName -LimitingCollection $LimitingCollection

    # Cache existing direct membership to avoid duplicates
    $existingRules = Get-CMDeviceCollectionDirectMembershipRule -CollectionId $collection.CollectionId -ErrorAction SilentlyContinue
    $existingResIds = @{}
    if ($existingRules) {
        foreach ($r in $existingRules) { $existingResIds[$r.ResourceID] = $true }
    }

    $i = 0
    foreach ($n in $deviceNames) {
        $i++
        Write-Progress -Activity "Adding direct members" -Status "$i / $($deviceNames.Count): $n" -PercentComplete ($i*100.0/$deviceNames.Count)

        $dev = Get-CMDevice -Name $n -Fast -ErrorAction SilentlyContinue
        if (-not $dev) {
            $log.Add([pscustomobject]@{
                Name      = $n
                Result    = 'Skipped'
                Detail    = 'Device not found in MECM'
                Timestamp = (Get-Date)
            })
            continue
        }

        if ($existingResIds.ContainsKey($dev.ResourceId)) {
            $log.Add([pscustomobject]@{
                Name      = $n
                Result    = 'AlreadyMember'
                Detail    = 'Direct membership rule already exists'
                Timestamp = (Get-Date)
            })
            continue
        }

        $action = "Add direct membership for $n (ResID $($dev.ResourceId)) to '$($collection.Name)'"
        if ($PSCmdlet.ShouldProcess($collection.Name, $action)) {
            try {
                Add-CMDeviceCollectionDirectMembershipRule -CollectionId $collection.CollectionId -ResourceId $dev.ResourceId -ErrorAction Stop
                $log.Add([pscustomobject]@{
                    Name      = $n
                    Result    = 'Added'
                    Detail    = "ResourceID $($dev.ResourceId)"
                    Timestamp = (Get-Date)
                })
            }
            catch {
                $log.Add([pscustomobject]@{
                    Name      = $n
                    Result    = 'Failed'
                    Detail    = $_.Exception.Message
                    Timestamp = (Get-Date)
                })
            }
        }
        else {
            $log.Add([pscustomobject]@{
                Name      = $n
                Result    = 'WhatIf'
                Detail    = 'Simulated add'
                Timestamp = (Get-Date)
            })
        }
    }

    # Optional: refresh membership
    if ($PSCmdlet.ShouldProcess($collection.Name, "Update collection membership")) {
        try {
            Invoke-CMCollectionUpdate -CollectionId $collection.CollectionId -ErrorAction Stop
        } catch {
            Write-Warning "Failed to trigger membership update: $($_.Exception.Message)"
        }
    }

    # Write log
    $log | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
    Write-Host "Log written: $logPath" -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    if ($log.Count -gt 0) {
        $log | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
        Write-Host "Partial log written: $logPath" -ForegroundColor Yellow
    }
}
finally {
    try { Pop-Location -ErrorAction SilentlyContinue } catch {}
}
