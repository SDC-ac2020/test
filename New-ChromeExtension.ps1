
<#

.SYNOPSIS
Add Chrome Extensions to PC via Powershell

.PARAMETER Extension
String value of an extension ID taken from the Chrome Web Store URL for the extension

.EXAMPLE
This will install chrome extension to the HKCU hive
New-ChromeExtension -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'

This will uninstall chrome extension from all Hives
New-ChromeExtension -Remove 'ohkeehjepccedbdpohnbapepongppfcj'

#>

[cmdletBinding()]
Param(
	[String[]]$Extension,
	[ValidateSet('Machine', 'User')]
	[String]$Hive,
	[String]$Remove
) 
$regLocation = 'Software\Policies\Google\Chrome\ExtensionInstallForcelist'
$HKLMRegLocation = "HKLM:\$regLocation"
$HKCURegLocation = "HKCU:\$regLocation"

if ($PSBoundParameters.ContainsKey('Remove'))
{	
	#remove from HKLM
	$extensionInstallForceListEntriesHKLM = Get-ItemProperty -Path $HKLMRegLocation
	foreach ($property in $extensionInstallForceListEntriesHKLM.PSObject.Properties)
	{
		if ($property.value -Like "$Remove*") {
			Write-Host "Removing the extension with id $Remove and registry id:  $property.name"
			Remove-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' -Name $property.name
		}
	}
	
	#remove from HKCU
#	$extensionInstallForceListEntriesHKCU = Get-ItemProperty -Path $HKCURegLocation
#	foreach ($property in $extensionInstallForceListEntriesHKCU.PSObject.Properties)
#	{
#		if ($property.value -Like "$Remove*") {
#			Write-Host "Removing the extension with id $Remove and registry id:  $property.name"
#			Remove-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' -Name $property.name
#		}
#	}
}
else
{
	#Target HKLM or HKCU depending on whether you want to affect EVERY user, or just a single user.
	#If using HKCU, you'll need to run this script in that user context.
	Switch ($Hive) {
		'Machine' {
			If (!(Test-Path "HKLM:\$regLocation")) {
				Write-Verbose -Message "No Registry Path, setting count to: 0"
				[int]$Count = 0
				Write-Verbose -Message "Count is now $Count" 
				New-Item -Path "HKLM:\$regLocation" -Force
			}
	
			Else {
				Write-Verbose -Message "Keys found, counting them..."
				#[int]$Count = (Get-Item "HKLM:\$regLocation").Count
				$indexes = @(0)
				$extensionPropEntries = Get-ItemProperty -Path $HKLMRegLocation
				foreach ($property in $extensionPropEntries.PSObject.Properties)
				{	
					Try
					{
						$num = [int]$property.name
						$indexes += $num
					}
					Catch
					{
						#ignore
					}
				}
				[int]$Count = ($indexes | sort | Select-Object -Last 1)
				Write-Verbose -Message "Count is now $Count"
			}
		}
		
		'User' {
			If (!(Test-Path "HKCU:\$regLocation")) {
				
				Write-Verbose -Message "No Registry Path, setting count to: 0"
				[int]$Count = 0
				Write-Verbose -Message "Count is now $Count" 
				New-Item -Path "HKCU:\$regLocation" -Force
	
			}
	
			Else {
				
				Write-Verbose -Message "Keys found, counting them..."
				#[int]$Count = (Get-Item "HKCU:\$regLocation").Count
				$indexes = @(0)
				$extensionPropEntries = Get-ItemProperty -Path $HKCURegLocation
				foreach ($property in $extensionPropEntries.PSObject.Properties)
				{	
					Try
					{
						$num = [int]$property.name
						$indexes += $num
					}
					Catch
					{
						#ignore
					}
				}
				[int]$Count = ($indexes | sort | Select-Object -Last 1)
				Write-Verbose -Message "Count is now $Count"
			
			}
		}
	}

	$regKey = $Count + 1
	
	Write-Verbose -Message "Creating reg key with value $regKey"
	
	$regData = "$Extension;https://clients2.google.com/service/update2/crx"

	Switch ($Hive) {
		
		'Machine' { New-ItemProperty -Path "HKLM:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
		'User' { New-ItemProperty -Path "HKCU:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
	
	}
}

# SIG # Begin signature block
# MIIjNwYJKoZIhvcNAQcCoIIjKDCCIyQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU68lA3WGHbaU3BdGXNyCjl+z/
# Ob2ggh6SMIIFjzCCBHegAwIBAgIRAIeEnfl+02PNHfSa/tM3v7QwDQYJKoZIhvcN
# AQELBQAwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3Rl
# cjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQx
# IzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBMB4XDTE4MDkyODAw
# MDAwMFoXDTE5MDkyODIzNTk1OVowgdcxCzAJBgNVBAYTAklOMQ8wDQYDVQQRDAY1
# NjAxMDIxEjAQBgNVBAgMCUthcm5hdGFrYTESMBAGA1UEBwwJQmFuZ2Fsb3JlMS0w
# KwYDVQQJDCQ0NDMsIDE3dGggQ3Jvc3MsIEhTUiBMYXlvdXQgU2VjdG9yIDQxLzAt
# BgNVBAoMJlFVSUNLTyBURUNITk9TT0ZUIExBQlMgUFJJVkFURSBMSU1JVEVEMS8w
# LQYDVQQDDCZRVUlDS08gVEVDSE5PU09GVCBMQUJTIFBSSVZBVEUgTElNSVRFRDCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL3toVrfpcQ3hwgZT2Tio29S
# 2+vpWOt43qf09n8v8RtWKFSfIXWPWDq6llRyFaIaet888LYqURC+sf5H+sYQ1kIL
# Hfy+k20BMvZjVpO68v5LVn1xa7AuCvSAeXJFq/iGDxisQCqjVYn47ezsQbsr4tTr
# mKpHawh3XBd8Y7cp9otuJT8JULmejM2wQo3KEODvJmFYu12rwdkFbU4XdI49R8w4
# ugIxkk/vcvUqT0km0Oe2F+VfraKRbuvw9jSzRtc3mD+wxmXfaht0u5itvQFV0pKx
# V2GblPnGoNAJDxsskI1ZjfHe14R9SlyrdwIfh2MvxGKkVSmiKp/8BE2sex8buIEC
# AwEAAaOCAa0wggGpMB8GA1UdIwQYMBaAFCmRYP+KTfrr+aZquM/55ku9Sc4SMB0G
# A1UdDgQWBBR8HNlXEqKVphluWfV3kK0ByFO1WzAOBgNVHQ8BAf8EBAMCB4AwDAYD
# VR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhCAQEEBAMC
# BBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcCARYdaHR0
# cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQ29kZVNpZ25pbmdDQS5jcmww
# dAYIKwYBBQUHAQEEaDBmMD4GCCsGAQUFBzAChjJodHRwOi8vY3J0LmNvbW9kb2Nh
# LmNvbS9DT01PRE9SU0FDb2RlU2lnbmluZ0NBLmNydDAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMB4GA1UdEQQXMBWBE3N1cHBvcnRAd2hhdGZp
# eC5jb20wDQYJKoZIhvcNAQELBQADggEBAJW70rd0HjtvWdx0J8uI1C9+QYl0voR5
# cYK2otODX1nhXws0bJvEHoSaoGD/mw4NIAoCucAoU6eBjAqIErpKWxToCw6WAE6i
# w7r1BCbuoE31RtTbgZ7QZ3DlleOfOKqxfiZKWSqDREkA6jIYC6z9+codsDeWhNYa
# dw6xuXz/+ugCuzWvRJgmpAq9ObIyvKljKDD1/bQk55hrCpwrfc2Z5nj014Bk0ray
# TXMth982Z1k3wgsHel6ytFROJ0nkj3079xTU3IU1WWiF1ozFTIn2PKWspkWMhbPb
# kcXip/M0j4qpcUbff8ukjaBfchtQ52z8fv+rMde2EVsCexzsFlzSbFEwggXYMIID
# wKADAgECAhBMqvnK22Nv4B/3TthbA4adMA0GCSqGSIb3DQEBDAUAMIGFMQswCQYD
# VQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdT
# YWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDErMCkGA1UEAxMiQ09N
# T0RPIFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xMDAxMTkwMDAwMDBa
# Fw0zODAxMTgyMzU5NTlaMIGFMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8g
# Q0EgTGltaXRlZDErMCkGA1UEAxMiQ09NT0RPIFJTQSBDZXJ0aWZpY2F0aW9uIEF1
# dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJHoVJLSClax
# rA0k3cXPRGd0mSs3o30jcABxvFPfxPoqEo9LfxBWvZ9wcrdhf8lLDxenPeOwBGHu
# /xGXx/SGPgr6Plz5k+Y0etkUa+ecs4Wggnp2r3GQ1+z9DfqcbPrfsIL0FH75vsSm
# L09/mX+1/GdDcr0MANaJ62ss0+2PmBwUq37l42782KjkkiTaQ2tiuFX96sG8bLaL
# 8w6NmuSbbGmZ+HhIMEXVreENPEVg/DKWUSe8Z8PKLrZr6kbHxyCgsR9l3kgIuqRO
# qfKDRjeE6+jMgUhDZ05yKptcvUwbKIpcInu0q5jZ7uBRg8MJRk5tPpn6lRfafDNX
# QTyNUe0LtlyvLGMa31fIP7zpXcSbr0WZ4qNaJLS6qVY9z2+q/0lYvvCo//S4rek3
# +7q49As6+ehDQh6J2ITLE/HZu+GJYLiMKFasFB2cCudx688O3T2plqFIvTz3r7UN
# IkzAEYHsVjv206LiW7eyBCJSlYCTaeiOTGXxkQMtcHQC6otnFSlpUgK7199QalVG
# v6CjKGF/cNDDoqosIapHziicBkV2v4IYJ7TVrrTLUOZr9EyGcTDppt8WhuDY/0Dd
# +9BCiH+jMzouXB5BEYFjzhhxayvspoq3MVw6akfgw3lZ1iAar/JqmKpyvFdK0kud
# uxD8sExB5e0dPV4onZzMv7NR2qdH5YRTAgMBAAGjQjBAMB0GA1UdDgQWBBS7r34C
# Pfqm8TyEjq3uOJjs2TIy1DAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB
# /zANBgkqhkiG9w0BAQwFAAOCAgEACvHVRoS3rlG7bLJNQRQAk0ycy+XAVM+gJY4C
# +f2wog31IJg8Ey2sVqKw1n4Rkukuup4umnKxvRlEbGE1opq0FhJpWozh1z6kGugv
# A/SuYR0QGyqki3rF/gWm4cDWyP6ero8ruj2Z+NhzCVhGbqac9Ncn05XaN4NyHNNz
# 4KJHmQM4XdVJeQApHMfsmyAcByRpV3iyOfw6hKC1nHyNvy6TYie3OdoXGK69PAlo
# /4SbPNXWCwPjV54U99HrT8i9hyO3tklDeYVcuuuSC6HG6GioTBaxGpkK6FMskruh
# CRh1DGWoe8sjtxrCKIXDG//QK2LvpHsJkZhnjBQBzWgGamMhdQOAiIpugcaF8qmk
# Lef0pSQQR4PKzfSNeVixBpvnGirZnQHXlH3tA0rK8NvoqQE+9VaZyR6OST275Qm5
# 4E9Jkj0WgkDMzFnG5jrtEi5pPGyVsf2qHXt/hr4eDjJG+/sTj3V/TItLRmP+ADRA
# cMHDuaHdpnDiBLNBvOmAkepknHrhIgOpnG5vDmVPbIeHXvNuoPl1pZtA6FOyJ51K
# ucB3IY3/h/LevIzvF9+3SQvR8m4wCxoOTnbtEfz16Vayfb/HbQqTjKXQwLYdvjpO
# lKLXbmwLwop8+iDzxOTlzQ2oy5GSsXyF7LUUaWYOgufNzsgtplF/IcE1U4UGSl2f
# rbsbX3QwggXgMIIDyKADAgECAhAufIfMDpNKUv6U/Ry3zTSvMA0GCSqGSIb3DQEB
# DAUAMIGFMQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFDT01PRE8gQ0EgTGltaXRlZDEr
# MCkGA1UEAxMiQ09NT0RPIFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0x
# MzA1MDkwMDAwMDBaFw0yODA1MDgyMzU5NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYD
# VQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGjAYBgNV
# BAoTEUNPTU9ETyBDQSBMaW1pdGVkMSMwIQYDVQQDExpDT01PRE8gUlNBIENvZGUg
# U2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKaYkGN3
# kTR/itHd6WcxEevMHv0xHbO5Ylc/k7xb458eJDIRJ2u8UZGnz56eJbNfgagYDx0e
# IDAO+2F7hgmz4/2iaJ0cLJ2/cuPkdaDlNSOOyYruGgxkx9hCoXu1UgNLOrCOI0tL
# Y+AilDd71XmQChQYUSzm/sES8Bw/YWEKjKLc9sMwqs0oGHVIwXlaCM27jFWM99R2
# kDozRlBzmFz0hUprD4DdXta9/akvwCX1+XjXjV8QwkRVPJA8MUbLcK4HqQrjr8EB
# b5AaI+JfONvGCF1Hs4NB8C4ANxS5Eqp5klLNhw972GIppH4wvRu1jHK0SPLj6CH5
# XkxieYsCBp9/1QsCAwEAAaOCAVEwggFNMB8GA1UdIwQYMBaAFLuvfgI9+qbxPISO
# re44mOzZMjLUMB0GA1UdDgQWBBQpkWD/ik366/mmarjP+eZLvUnOEjAOBgNVHQ8B
# Af8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcD
# AzARBgNVHSAECjAIMAYGBFUdIAAwTAYDVR0fBEUwQzBBoD+gPYY7aHR0cDovL2Ny
# bC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5j
# cmwwcQYIKwYBBQUHAQEEZTBjMDsGCCsGAQUFBzAChi9odHRwOi8vY3J0LmNvbW9k
# b2NhLmNvbS9DT01PRE9SU0FBZGRUcnVzdENBLmNydDAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQACPwI5w+74
# yjuJ3gxtTbHxTpJPr8I4LATMxWMRqwljr6ui1wI/zG8Zwz3WGgiU/yXYqYinKxAa
# 4JuxByIaURw61OHpCb/mJHSvHnsWMW4j71RRLVIC4nUIBUzxt1HhUQDGh/Zs7hBE
# dldq8d9YayGqSdR8N069/7Z1VEAYNldnEc1PAuT+89r8dRfb7Lf3ZQkjSR9DV4Pq
# fiB3YchN8rtlTaj3hUUHr3ppJ2WQKUCL33s6UTmMqB9wea1tQiCizwxsA4xMzXMH
# lOdajjoEuqKhfB/LYzoVp9QVG6dSRzKp9L9kR9GqH1NOMjBzwm+3eIKdXP9Gu2si
# HYgL+BuqNKb8jPXdf2WMjDFXMdA27Eehz8uLqO8cGFjFBnfKS5tRr0wISnqP4qNS
# 4o6OzCbkstjlOMKo7caBnDVrqVhhSgqXtEtCtlWdvpnncG1Z+G0qDH8ZYF8Mmohs
# MKxSCZAWG/8rndvQIMqJ6ih+Mo4Z33tIMx7XZfiuyfiDFJN2fWTQjs6+NX3/cjFN
# n569HmwvqI8MBlD7jCezdsn05tfDNOKMhyGGYf6/VXThIXcDCmhsu+TJqebPWSXr
# fOxFDnlmaOgizbjvmIVNlhE8CYrQf7woKBP7aspUjZJczcJlmAaezkhb1LU3k0ZB
# fAfdz/pD77pnYf99SeC7MH1cgOPmFjlLpzCCBmowggVSoAMCAQICEAMBmgI6/1ix
# a9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMB4XDTE0MTAyMjAwMDAwMFoXDTI0
# MTAyMjAwMDAwMFowRzELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSUw
# IwYDVQQDExxEaWdpQ2VydCBUaW1lc3RhbXAgUmVzcG9uZGVyMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd/Hyz4II14OD2xirmSXU7zG7gU6mfH2RZ
# 5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m7t3LhelfpfnUh3SIRDsZyeX1kZ/GFDms
# JOqoSyyRicxeKPRktlC39RKzc5YKZ6O+YZ+u8/0SeHUOplsU/UUjjoZEVX0YhgWM
# VYd5SEb3yg6Np95OX+Koti1ZAmGIYXIYaLm4fO7m5zQvMXeBMB+7NgGN7yfj95rw
# TDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJBi5GEMiN6ARg27xzdPpO2P6qQPGyznBG
# g+naQKFZOtkVCVeZVjCT88lhzNAIzGvsYkKRrALA76TwiRGPdwIDAQABo4IDNTCC
# AzEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYI
# KwYBBQUHAwgwggG/BgNVHSAEggG2MIIBsjCCAaEGCWCGSAGG/WwHATCCAZIwKAYI
# KwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwggFkBggrBgEF
# BQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBl
# AHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBj
# AGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0
# ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAg
# AFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABp
# AG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBu
# AGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBm
# AGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMB8GA1UdIwQYMBaAFBUAEisTmLKZ
# B+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRhWk0ktkkynUoqeRqDS/QeicHKfTB9BgNV
# HR8EdjB0MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURDQS0xLmNybDA4oDagNIYyaHR0cDovL2NybDQuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwdwYIKwYBBQUHAQEEazBpMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEu
# Y3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCdJX4bM02yJoFcm4bOIyAPgIfliP//sdRq
# LDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD73gYBjDf6m7GdJH7+IKRXrVu3mrBgJupp
# VyFdNC8fcbCDlBkFazWQEKB7l8f2P+fiEUGmvWLZ8Cc9OB0obzpSCfDscGLTYkuw
# 4HOmksDTjjHYL+NtFxMG7uQDthSr849Dp3GdId0UyhVdkkHa+Q+B0Zl0DSbEDn8b
# tfWg8cZ3BigV6diT5VUW8LsKqxzbXEgnZsijiwoc5ZXarsQuWaBh3drzbaJh6YoL
# bewSGL33VVRAA5Ira8JRwgpIr7DUbuD0FAo6G+OPPcqvao173NhEMIIGzTCCBbWg
# AwIBAgIQBv35A5YDreoACus/J7u6GzANBgkqhkiG9w0BAQUFADBlMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcN
# MDYxMTEwMDAwMDAwWhcNMjExMTEwMDAwMDAwWjBiMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEw
# HwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQDogi2Z+crCQpWlgHNAcNKeVlRcqcTSQQaPyTP8TUWR
# XIGf7Syc+BZZ3561JBXCmLm0d0ncicQK2q/LXmvtrbBxMevPOkAMRk2T7It6NggD
# qww0/hhJgv7HxzFIgHweog+SDlDJxofrNj/YMMP/pvf7os1vcyP+rFYFkPAyIRaJ
# xnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuVSMTuHrPyvAwrmdDGXRJCgeGDboJzPyZL
# FJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM8q+Y+/bOQF1c9qjxL6/siSLyaxhlscFz
# rdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/MhRglf0HBKIJAgMBAAGjggN6MIIDdjAO
# BgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQwMgYIKwYBBQUHAwEGCCsGAQUFBwMCBggr
# BgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUFBwMIMIIB0gYDVR0gBIIByTCCAcUwggG0
# BgpghkgBhv1sAAEEMIIBpDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2Vy
# dC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6C
# AVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBp
# AGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABh
# AG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBD
# AFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5
# ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABs
# AGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABv
# AHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBj
# AGUALjALBglghkgBhv1sAxUwEgYDVR0TAQH/BAgwBgEB/wIBADB5BggrBgEFBQcB
# AQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggr
# BgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDAdBgNVHQ4EFgQUFQASKxOYspkH7R7for5XDStnAs0wHwYDVR0jBBgwFoAU
# Reuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEFBQADggEBAEZQPsm3KCSn
# OB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1H3Q48rJcYaKclcNQ5IK5I9G6OoZyrTh4
# rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlVqefj56tizfuLLZDCwNK1lL1eT7EF0g49
# GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz5Cqrz5x2S+1fwksW5EtwTACJHvzFebxM
# Elf+X+EevAJdqP77BzhPDcZdkbkPZ0XN1oPt55INjbFpjE/7WeAjD9KqrgB87pxC
# Ds+R1ye3Fu4Pw718CqDuLAhVhSK46xgaTfwqIa1JMYNHlXdx3LEbS0scEJx3FMGd
# Ty9alQgpECYxggQPMIIECwIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRowGAYDVQQKExFD
# T01PRE8gQ0EgTGltaXRlZDEjMCEGA1UEAxMaQ09NT0RPIFJTQSBDb2RlIFNpZ25p
# bmcgQ0ECEQCHhJ35ftNjzR30mv7TN7+0MAkGBSsOAwIaBQCgQDAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAjBgkqhkiG9w0BCQQxFgQUIQ0juSYzbYW8wpy3/YEo
# 4spMRRkwDQYJKoZIhvcNAQEBBQAEggEAHxA6nWz68pbhurntEgzQPbzbo9uPTEZG
# DWi6kPXFYspgknmw+fdpQGTZIfxfsn6C9Q+XCXf2QM4q2840p/j8ZS3NNrFtfiTV
# jqeSaRj7YxQO4yNazdAdnxSQFwk52GfcxJ3+yPoPYMNz1KFD9OeStxSQ2jcpijwJ
# VDUPOw+pwDDr3pbZtgllNre+20z06IkOV3ZVeZ0BNy1SEMZwy/VDOhnm2KdP6y+Y
# nJFjWKSU7UkKc/hDjV/4uWsQ4Q8H5+y4bz5f4g6nstdMztr0+OHwvbiJqHRVmic3
# K+65IgjYlxPBMAtST1fA5mkgI2obyNLaes91ZTxlgPc+zSUGQFlCVaGCAg8wggIL
# BgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGaAjr/WLFr1tXq5hfwZjAJ
# BgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0B
# CQUxDxcNMTkwNTI4MTMzOTQxWjAjBgkqhkiG9w0BCQQxFgQUakk7I2kN7NTQ6a3j
# qKzx8Qp9xaMwDQYJKoZIhvcNAQEBBQAEggEAMtiFaJll/JvfiPquREt+KHmvA2E9
# TXhxglO+LALOSvN6e81/NQ2CaKSZvLKI5/w42PQRmr2NsbKls/1YNR5FdEN5Ac4v
# aOkm6wLCZu7esOpsMvhKtViCNKWZYr8le4AqEdw2fEUgXVQZh5hhp7UixmsYWikY
# UMM/1/HUWizqcAS28A3R5+arazNhjTqQCZXa3+cbwZLmGeNOFNTBT73SuubPYjrJ
# ZyngWQ6U9mBH+B0tufJ7l4beOcqpXum8F8OQj7vJBXk4oavavxjhGoQcP+ydZ6CE
# COPrZ/MM0IpuaC14dzIfCTJrvlf2UjYc0TLRsvqOKN5ZMrKanB7JpUJMkg==
# SIG # End signature block