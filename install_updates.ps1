# Read the CSV file and store it in a variable
$computers = Import-Csv -Path "D:\scripts\htf14.csv"

# Loop through each computer name
foreach ($computer in $computers) {
    # Run the function on the remote computer
    Invoke-Command -ComputerName $computer.ComputerName -ScriptBlock {
        # The function to install software updates
       ([wmiclass]'ROOT\ccm\ClientSDK:CCM_SoftwareUpdatesManager').InstallUpdates([System.Management.ManagementObject[]] (get-wmiobject -query 'SELECT * FROM CCM_SoftwareUpdate' -namespace 'ROOT\ccm\ClientSDK'))
    } # Add a closing } for the ScriptBlock parameter
} # Add a closing } for the foreach loop


