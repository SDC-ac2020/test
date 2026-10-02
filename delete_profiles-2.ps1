Function Delete-Profile{
#Deletes a profile properly off remote machine.  WARNING: DOES NOT BACK UP DATA!  Use at your own peril. Delprofile
#Added User Display Name as the selection corresponding it to their Logon Name, and deletion of files if no CIM instance was found. -1/5/2021
$cn =  Read-Host -Prompt "Enter Computer Name"

$ping = Test-Connection -ComputerName $cn -Count 1 -Quiet 

    If($ping -eq $false){ Write-Host "Computer seems to be offline, please check name spelling." -ForegroundColor DarkYellow; Write-Host ""; &Delete-Profile } else {

$menu = (get-childitem "\\$cn\c$\users"  | sort LastWriteTime -Descending).Name

$userinfo1 = foreach ($user in $menu) {
Start-Sleep -Milliseconds 2
  $userinfo = (net user $user /domain | Select-String "Full Name" -ErrorAction SilentlyContinue) -replace "Full Name                   ", "" 2>&1 | Out-String -Stream
  if ($userinfo.Length -lt 4) {    
    "$user - NO DISPLAY NAME in ADUC"  # output
  }
  else {
    if ($LASTEXITCODE -eq 2) {
      "$user   -   ACCOUNT NOT in ADUC"    # output
    }
    else {
    if ($LASTEXITCODE -eq 0){
      $userinfo  # output
        }
      }
    }
}


        Write-Warning "Ensure user profiles are no longer active and/or, have profiles be backed-up!"

            Write-Host "RESULTS:" -BackgroundColor Black -ForegroundColor White 

for ($i=0; $i -lt $userinfo1.Count; $i++) {

  Write-Host "$($i): $($userinfo1[$i])"

} #END LIST OF POSSIBLE NAMES 

             Write-Host ""

            Write-Host "For multiple users, seperate using a SPACE(1 2 3)" 

        $selection = Read-Host "ENTER THE NUMBER of the user(s) or Q to quit"

        $selection = $selection -split " "


foreach($index in $selection) {
    $Profile = $menu[$index]
    Write-Host "Deleting user: $($userinfo1[$index]) `
                LogonName:$Profile "
  


   $del = Get-CimInstance -ComputerName $cn -Class Win32_UserProfile | Where-Object { $_.LocalPath.split('\')[-1] -eq $Profile }

   If($del -eq $null){Write-Warning "No CIM instance found on system, profile has been deleted but files persist."    
    Write-Host "Attempting to delete files, please wait. . ." 
     
     Remove-Item -Path "\\$cn\c$\users\$Profile" -Recurse -Force       
    Write-Host 'Remove-item, has finished.'
     Write-Host ""
     
     Start-Sleep -Seconds 2
    Write-Host "Checking if profile is still there. . ."

$TestPath = Test-Path -Path "\\$cn\c$\users\$Profile"    
   If($TestPath -eq $false){ Write-Host "User persistent files have been deleted. `
Continuing. . . ." -ForegroundColor Green}
   
   } else{

   Get-CimInstance -ComputerName $cn -Class Win32_UserProfile | Where-Object { $_.LocalPath.split('\')[-1] -eq $Profile } | Remove-CimInstance 

    Write-Host "user profile has been deleted" -ForegroundColor Red

     Write-Host ""
                
            }

        }
    }

}
