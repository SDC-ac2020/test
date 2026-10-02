$GroupList = (Get-ADUser -Identity 'vinceadams' -Properties MemberOf).MemberOf
foreach ($Group in $GroupList) {
(Get-ADGroup $Group).name
}