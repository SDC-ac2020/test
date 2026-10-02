Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

###############################################################################
# SCCM Deployment Log Parser GUI (Windows Forms) - Built for Vince
###############################################################################

# -------------------------------
# Create the Form
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "SCCM Deployment Log Parser"
$form.Size = New-Object System.Drawing.Size(1100,700)
$form.StartPosition = "CenterScreen"

# -------------------------------
# Labels and Inputs
# -------------------------------
# Computer Name
$lblComp = New-Object System.Windows.Forms.Label
$lblComp.Text = "Computer Name:"
$lblComp.Location = "20,20"
$form.Controls.Add($lblComp)

$txtComp = New-Object System.Windows.Forms.TextBox
$txtComp.Location = "150,17"
$txtComp.Size = "200,25"
$txtComp.Text = $env:COMPUTERNAME
$form.Controls.Add($txtComp)

# App Filter
$lblFilter = New-Object System.Windows.Forms.Label
$lblFilter.Text = "App Filter Keyword:"
$lblFilter.Location = "20,60"
$form.Controls.Add($lblFilter)

$txtFilter = New-Object System.Windows.Forms.TextBox
$txtFilter.Location = "150,57"
$txtFilter.Size = "200,25"
$form.Controls.Add($txtFilter)

# Last Hours
$lblHours = New-Object System.Windows.Forms.Label
$lblHours.Text = "Last X Hours:"
$lblHours.Location = "20,100"
$form.Controls.Add($lblHours)

$txtHours = New-Object System.Windows.Forms.TextBox
$txtHours.Location = "150,97"
$txtHours.Size = "200,25"
$txtHours.Text = "168"
$form.Controls.Add($txtHours)

# -------------------------------
# Buttons
# -------------------------------
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Parse Logs"
$btnRun.Location = "380,17"
$btnRun.Size = "140,40"
$form.Controls.Add($btnRun)

$btnCSV = New-Object System.Windows.Forms.Button
$btnCSV.Text = "Export CSV"
$btnCSV.Location = "380,70"
$btnCSV.Size = "140,40"
$form.Controls.Add($btnCSV)

$btnJSON = New-Object System.Windows.Forms.Button
$btnJSON.Text = "Export JSON"
$btnJSON.Location = "540,70"
$btnJSON.Size = "140,40"
$form.Controls.Add($btnJSON)

# -------------------------------
# DataGridView
# -------------------------------
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = "20,150"
$grid.Size = "1040,460"
$grid.AutoSizeColumnsMode = "Fill"
$grid.ReadOnly = $true
$form.Controls.Add($grid)

# -------------------------------
# Status Bar
# -------------------------------
$status = New-Object System.Windows.Forms.Label
$status.Dock = "Bottom"
$status.Height = 25
$status.Text = "Ready."
$status.BackColor = "LightGray"
$form.Controls.Add($status)


###############################################################################
# SCCM LOG PARSER FUNCTIONS  (stateful version)
###############################################################################

function Get-Timestamp {
    param($Line)
    if ($Line -match 'Date="([^"]+)" Time="([^"]+)"') {
        try {
            return [datetime]::ParseExact("$($matches[1]) $($matches[2])","MM-dd-yyyy HH:mm:ss.fff",$null)
        } catch { return $null }
    }
}

function Parse-SCCMLogs {
    param(
        [string]$ComputerName,
        [string]$AppFilter,
        [int]$LastHours
    )

    $LogRoot = "\\$ComputerName\C$\Windows\CCM\Logs"
    $LogFiles = @("AppEnforce.log","AppDiscovery.log","AppIntentEval.log")
    $Cutoff = (Get-Date).AddHours(-$LastHours)

    $Results = @()

    foreach ($log in $LogFiles) {

        $FullPath = Join-Path $LogRoot $log
        if (!(Test-Path $FullPath)) { continue }

        $Content = Get-Content $FullPath -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Content -eq $null -or $Content.Count -eq 0) {
            $Content = Get-Content $FullPath -Encoding Unicode -ErrorAction SilentlyContinue
        }

        # Stateful tracking
        $CurrentAppName = $null

        foreach ($Line in $Content) {

            $Timestamp = Get-Timestamp $Line
            if ($Timestamp -and $Timestamp -lt $Cutoff) { continue }

            # Extract AppName (two patterns)
            $AppLineName = $null
            if ($Line -match 'App DT "([^"]+)"') {
                $AppLineName = $matches[1]
            } elseif ($Line -match 'Detected app deployment type ([^\(]+)\(') {
                $AppLineName = $matches[1]
            }

            # Detection success
            if ($Line -match 'Discovered application' -or
                $Line -match 'Detected app deployment type' -or
                $Line -match 'Current State = Installed') {

                if (!$AppFilter -or $AppLineName -match $AppFilter) {
                    $Results += [pscustomobject]@{
                        Computer=$ComputerName; AppName=$AppLineName; Status="Detected"; 
                        ExitCode=""; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                    }
                }
                continue
            }

            # Detection failure
            if ($Line -match 'Application not discovered' -or
                $Line -match 'Did not detect app deployment type' -or
                $Line -match 'Current State = NotInstalled') {

                if (!$AppFilter -or $AppLineName -match $AppFilter) {
                    $Results += [pscustomobject]@{
                        Computer=$ComputerName; AppName=$AppLineName; Status="Not Detected"; 
                        ExitCode=""; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                    }
                }
                continue
            }

            # Install start
            if ($Line -match 'Starting Install enforcement for App DT "') {
                $CurrentAppName = $AppLineName
                $Results += [pscustomobject]@{
                    Computer=$ComputerName; AppName=$CurrentAppName; Status="Install Started"; 
                    ExitCode=""; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                }
                continue
            }

            # Running
            if ($Line -match 'Executing Command line:') {
                $Results += [pscustomobject]@{
                    Computer=$ComputerName; AppName=$CurrentAppName; Status="Executing"; 
                    ExitCode=""; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                }
                continue
            }

            # Success
            if ($Line -match 'Matched exit code 0' -or
                $Line -match 'Found a match in the success exit codes' -or
                $Line -match 'Status is switching to Success' -or
                $Line -match 'App enforcement completed .* for App DT') {

                $Results += [pscustomobject]@{
                    Computer=$CurrentAppName; AppName=$CurrentAppName; Status="Success"; 
                    ExitCode="0"; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                }
                continue
            }

            # Failure
            if ($Line -match 'Returning:? 0x([0-9A-Fa-f]+)') {
                $Exit = $matches[1]
                $Results += [pscustomobject]@{
                    Computer=$ComputerName; AppName=$CurrentAppName; Status="Failure"; 
                    ExitCode=$Exit; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                }
                continue
            }

            if ($Line -match 'Status is switching to Failure') {
                $Results += [pscustomobject]@{
                    Computer=$ComputerName; AppName=$CurrentAppName; Status="Failure"; 
                    ExitCode=""; Timestamp=$Timestamp; LogSource=$log; RawLine=$Line.Trim()
                }
                continue
            }

        }
    }

    return $Results
}

###############################################################################
# GUI BUTTON ACTIONS
###############################################################################

$btnRun.Add_Click({
    $status.Text = "Parsing..."
    $status.BackColor = "LightYellow"
    $form.Refresh()

    $results = Parse-SCCMLogs -ComputerName $txtComp.Text -AppFilter $txtFilter.Text -LastHours ([int]$txtHours.Text)
    $grid.DataSource = $results

    $status.Text = "Done."
    $status.BackColor = "LightGreen"
})

$btnCSV.Add_Click({
    if ($grid.DataSource -eq $null) { return }
    $grid.DataSource | Export-Csv -Path "D:\Scripts\SCCM-GUI-Export.csv" -NoTypeInformation
    $status.Text = "CSV Exported."
})

$btnJSON.Add_Click({
    if ($grid.DataSource -eq $null) { return }
    ($grid.DataSource | ConvertTo-Json -Depth 5) | Out-File "D:\Scripts\SCCM-GUI-Export.json"
    $status.Text = "JSON Exported."
})

###############################################################################
# SHOW GUI
###############################################################################

$form.ShowDialog()
