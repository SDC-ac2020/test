 #SDCAzureSA@testmailsouthdevonac.onmicrosoft.com
# Si9!Uz5$7%Px0@3#4$!Tp6@2#8%Qj1@Om1%c0#Nk2
# Install-Module -Name AzureAD
# Install-Module -Name ExchangeOnlineManagement -RequiredVersion 2.0.5
# Connect-ExchangeOnline
# example test connection - Get-EXOMailbox -identity vinceadams 

set-executionpolicy unrestricted -force
Install-Module MSOnline 
Connect-MsolService
 
 Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | 
 Get-MailboxPermission |Select-Object Identity,User,AccessRights | Where-Object {($_.user -like '*@*')}|Export-Csv C:\Temp\sharedfolders.csv  -NoTypeInformation