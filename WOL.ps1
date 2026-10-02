# ARP Command: If you know the IP address, run arp -a <IPAddress> in Command Prompt to see the physical address.
# Getmac Tool: Use getmac /s [RemoteComputerName] to get the MAC address directly from another machine on the network.
# Nbtstat Command: Run nbtstat -A [RemoteIPAddress] to retrieve the MAC address.
# WinRM needs to be running which can be done by running "winrm quickconfig -q"

$RemoteComputer = Read-Host -Prompt "Input the name of the device to send the Wake-on-LAN command"
$Mac = Read-Host -Prompt "Input the target MAC address"
Write-Verbose -Message "Converting MAC address $($Mac) to a byte array" -Verbose
$MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray * 16)
Write-Verbose -Message "Sending Wake-on-LAN command to $($RemoteComputer)." -Verbose
Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
$UdpClient.Send($using:MagicPacket,$using:MagicPacket.Length)
$UdpClient.Close()
}

