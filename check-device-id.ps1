$deviceId = 'HDAUDIO\SUBFUNC_01&VEN_8086&DEV_281A&NID_0001&SUBSYS_00000000&REV_1000\5&20AAE1D8&0&0002&0000000C'
$device   = Get-PnpDevice -InstanceId $deviceId -ErrorAction SilentlyContinue
if ($device) {
    switch ($device.Status) {
        'OK'    { Write-Host "Disabling device"; Disable-PnpDevice -InstanceId $deviceId -Confirm:$false; break }
        default { Write-Host "Enabling device";  Enable-PnpDevice -InstanceId $deviceId -Confirm:$false }
    }
}
else {
    Write-Warning "Device with ID '$deviceId' not found"
}