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
  $users += Get-ADUser -Filter 'enabled -eq $true' -SearchBase $TargetOU -searchscope 1 -Properties *
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

    $adgroups = ($user.memberof | Out-String).Trim() -replace ',.*dc=com',';' -replace 'CN=',' '
    
    #Admin Access
    if (($adgroups.Contains('Domain Admins')) -or ($adgroups.Contains('Enterprise Admins'))) 
    {
        $AdminAccess = "Yes"
    } 
    else 
    {
        $AdminAccess = "No"
    }
    

    $dt = [DateTime]::FromFileTime($time)
	  $Object = New-Object PSObject
	  Add-Member -InputObject $Object -NotePropertyName "Name" -NotePropertyValue $user.Name
	  Add-Member -InputObject $Object -NotePropertyName "SamAccountName" -NotePropertyValue $user.SamAccountName
    Add-Member -InputObject $Object -NotePropertyName "Description" -NotePropertyValue $user.Description
    Add-Member -InputObject $Object -NotePropertyName "Enabled" -NotePropertyValue $user.Enabled
    Add-Member -InputObject $Object -NotePropertyName "Created" -NotePropertyValue $user.Created
    Add-Member -InputObject $Object -NotePropertyName "mail" -NotePropertyValue $user.mail
    Add-Member -InputObject $Object -NotePropertyName "AdminAccess" -NotePropertyValue $AdminAccess
	  Add-Member -InputObject $Object -NotePropertyName "LastLogon" -NotePropertyValue $dt.ToString("dd/MMM/yyyy")
    Add-Member -InputObject $Object -NotePropertyName "MemberOf" -NotePropertyValue (($user.memberof | Out-String).Trim() -replace ',.*dc=com',';' -replace 'CN=',' ')
	
	  Write-Output $Object
    $time = 0
  }
}
 
$CSVFile = "Users_Access_and_Last_Logon_Report-$((Get-Date).ToString('MM-dd-yyyy')).csv"

Get-ADUsersLastLogon | Export-CSV -Path "C:\Scripts\Reports\$CSVFile" -NoTypeInformation

$smtppassword = Get-Content 'C:\Scripts\svc_prd_tasksch\securestringsmtppwd.txt' | ConvertTo-SecureString
[PSCredential] $mycreds = New-Object System.Management.Automation.PSCredential ("AZZZZZZZZZZZZZZZ", $smtppassword)

$messagebody = @"
Dear Team,

Please find the attached the users access and last logon Report from AWS AD. Could you please review the report and respond to this email as a confirmation that it has been reviewed. Please also let us know if there are any changes you wish to make on the user accounts.

Regards,
AWS Cloud Team
"@

# Send Email - change the values if needed.
Send-MailMessage -Credential $mycreds `
-useSSL `
-smtpServer 'email-smtp.eu-west-1.amazonaws.com' `
-port 587 `
-from 'no-reply@contoso.com' `
-to 'gpgupta7891@gmail.com' `
-subject 'User Access and Last Logon Report' `
-body $messagebody `
-Attachments C:\Scripts\Reports\$CSVFile
