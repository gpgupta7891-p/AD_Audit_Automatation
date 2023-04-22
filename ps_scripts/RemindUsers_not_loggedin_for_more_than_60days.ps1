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
  $users += Get-ADUser -Filter 'enabled -eq $true' -SearchBase $TargetOU -searchscope 1 -Properties * | Where-object {($_.lastlogondate -lt (get-date).AddDays(-75)) -and ($_.WhenCreated -lt (get-date).AddDays(-75))}
}
  $time = 0
  #Fetch SMTP creadentials
  $smtppassword = Get-Content 'C:\Scripts\svc_prd_tasksch\securestringsmtppwd.txt' | ConvertTo-SecureString
  [PSCredential] $mycreds = New-Object System.Management.Automation.PSCredential ("AZZZZZZZZZZZZZZZ"", $smtppassword)

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
    
    $userid = $user.SamAccountName
    
    $messagebody = @"
Dear User,

Your Citrix account for user uk\$userid will be disabled after one month because you have not logged in for at least 2 months or more. If you still need this account to be active, please authenticate using this account within the next 2 weeks. Please send an email to gpgupta7891@gmail.com in case of any questions.
Regards,
AWS Cloud Team
"@
    $useremail = $user.mail
    
    Send-MailMessage -Credential $mycreds `
    -useSSL `
    -smtpServer 'email-smtp.eu-west-2.amazonaws.com' `
    -port 587 `
    -from 'no-reply@contoso.com' `
    -to $useremail `
    -bcc 'gpgupta7891@gmail.com' `
    -subject 'Reminder - Citrix Account - Will be disabled in 30 days' `
    -body $messagebody
    
    
    $dt = [DateTime]::FromFileTime($time)
    $row = $user.Name+","+$user.SamAccountName+","+$user.Description+","+$user.Enabled+","+$user.Created+$user.mail+","+$dt
	  $global:Object = New-Object PSObject
	  Add-Member -InputObject $Object -NotePropertyName "Name" -NotePropertyValue $user.Name
	  Add-Member -InputObject $Object -NotePropertyName "SamAccountName" -NotePropertyValue $user.SamAccountName
    Add-Member -InputObject $Object -NotePropertyName "Description" -NotePropertyValue $user.Description
    Add-Member -InputObject $Object -NotePropertyName "Enabled" -NotePropertyValue $user.Enabled
    Add-Member -InputObject $Object -NotePropertyName "Created" -NotePropertyValue $user.Created
    Add-Member -InputObject $Object -NotePropertyName "mail" -NotePropertyValue $user.mail
	  Add-Member -InputObject $Object -NotePropertyName "LastLogon" -NotePropertyValue $dt.ToString("dd/MMM/yyyy")
	
	  Write-Output $global:Object
    Clear-Variable useremail
    Clear-Variable userid
    $time = 0
  }
}

$CSVFile = "Users_Inactive_Users_Report-$((Get-Date).ToString('MM-dd-yyyy')).csv"
Get-ADUsersLastLogon | Export-CSV -Path "C:\Scripts\UserLastLogonReport\$CSVFile" -NoTypeInformation

if($global:Object -ne $null)
{ 
$smtppassword = Get-Content 'C:\Scripts\svc_prd_tasksch\securestringsmtppwd.txt' | ConvertTo-SecureString
[PSCredential] $mycreds = New-Object System.Management.Automation.PSCredential ("AZZZZZZZZZZZZZZZ", $smtppassword)

$messagebody = @"
Dear Team,

Please find attached the list of Users who have not logged in for 60 days or more. We will disable these users in 30 days. They have already been notified by seperate emails.

Regards,
AWS Cloud Team
"@

# Send Email - change the values if needed.
Send-MailMessage -Credential $mycreds `
-useSSL `
-smtpServer 'email-smtp.eu-west-2.amazonaws.com' `
-port 587 `
-from 'no-reply@contoso.com `
-to ‘gpgupta7891@gmail.com’ `
-subject 'Citrix Users Audit - 30 days reminder' `
-body $messagebody `
-Attachments C:\Scripts\UserLastLogonReport\$CSVFile
}
else
{
Write-Host "No users to be reported"
}
