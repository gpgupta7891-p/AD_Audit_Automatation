$global:Object =$null
function Get-ADUsersLastLogon()
{
  $dcs = Get-ADDomainController -Filter {Name -like "*"}
  $TargetOUs = @(
    "OU=Internal,OU=Users,OU=MyObjects,DC=contoso,DC=com"
    "OU=External,OU=Users,OU=MyObjects,DC=contoso,DC=com"
)
$users = $null
foreach($TargetOU in $TargetOUs)
{
  $users += Get-ADUser -Filter 'enabled -eq $false' -SearchBase $TargetOU -Properties * | Where-object {($_.lastlogondate -lt (get-date).AddDays(-195)) -and ($_.WhenCreated -lt (get-date).AddDays(-195))}
}
  $time = 0

  foreach($user in $users)
  {
    foreach($dc in $dcs)
    { 
      $hostname = $dc.HostName
      $currentUser = Get-ADUser $user.SamAccountName | Get-ADObject -Server $hostname -Properties lastLogon, LastLogonTimestamp

      if($currentUser.LastLogon -gt $time) 
      {
        $time = $currentUser.LastLogon
      }
	  if($currentUser.LastLogonTimestamp -gt $time) 
      {
        $time = $currentUser.LastLogonTimestamp
      }
    }

    Remove-ADUser $user -Confirm:$false

    $dt = [DateTime]::FromFileTime($time)
    $row = $user.Name+","+$user.SamAccountName+","+$user.Description+","+$user.Enabled+","+$user.Created+$user.mail+","+$dt+","+$user.MemberOf
	$global:Object = New-Object PSObject

	Add-Member -InputObject $Object -NotePropertyName "Name" -NotePropertyValue $user.Name
	Add-Member -InputObject $Object -NotePropertyName "SamAccountName" -NotePropertyValue $user.SamAccountName
    Add-Member -InputObject $Object -NotePropertyName "Description" -NotePropertyValue $user.Description
    Add-Member -InputObject $Object -NotePropertyName "Enabled" -NotePropertyValue $user.Enabled
    Add-Member -InputObject $Object -NotePropertyName "Created" -NotePropertyValue $user.Created
    Add-Member -InputObject $Object -NotePropertyName "mail" -NotePropertyValue $user.mail
	Add-Member -InputObject $Object -NotePropertyName "LastLogon" -NotePropertyValue $dt.ToString("dd/MMM/yyyy")
    Add-Member -InputObject $Object -NotePropertyName "MemberOf" -NotePropertyValue (($user.memberof | Out-String).Trim() -replace ',.*dc=com',';' -replace 'CN=',' ')

	Write-Output $global:Object

    $time = 0
  }
}

$CSVFile = "ADUsers_Deleted_Report-$((Get-Date).ToString('MM-dd-yyyy')).csv"
Get-ADUsersLastLogon | Export-CSV -Path "C:\Scripts\UserLastLogonReport\$CSVFile" -NoTypeInformation

if($global:Object -ne $null)
{ 
$smtppassword = Get-Content 'C:\Scripts\svc_prd_tasksch\securestringsmtppwd.txt' | ConvertTo-SecureString
[PSCredential] $mycreds = New-Object System.Management.Automation.PSCredential ("AZZZZZZZZZZZZZZZ", $smtppassword)

$messagebody = @"
Dear Team,

Please find attached the list of AWS AD Users who are now deleted since they are disabled for more then 180 days or more. 
Regards,
AWS Cloud Team
"@

# Send Email - change the values if needed.
Send-MailMessage -Credential $mycreds `
-useSSL `
-smtpServer 'email-smtp.eu-west-2.amazonaws.com' `
-port 587 `
-from 'no-reply@contoso.com' `
-to 'gpgupta7891@gmail.com' `
-subject 'Citrix Users Audit - Deleted from AD' `
-body $messagebody `
-Attachments C:\Scripts\UserLastLogonReport\$CSVFile
}
else
{
Write-Host "No users to be reported"
}
