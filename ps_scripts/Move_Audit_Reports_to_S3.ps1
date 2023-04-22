#Move the privelaged reports to S3
$files1 = @()
$files1 = (get-childitem -Path "C:\Scripts\PrivelagedAccessReport"  | where-object {$_.LastWriteTime -lt (get-date).AddDays(-1)}).name
foreach($file1 in $files1)
{
    aws s3 --region eu-west-2 mv C:\Scripts\PrivelagedAccessReport\$file1 "s3://ad-audit-reports/PrivelagedAccessReport/"
}

#Move the user reports to S3
$files2 = @()
$files2 = (get-childitem -Path "C:\Scripts\UserAccessReport"  | where-object {$_.LastWriteTime -lt (get-date).AddDays(-1)}).name
foreach($file2 in $files2)
{
    aws s3 --region eu-west-2 mv C:\Scripts\UserAccessReport\$file2 "s3://ad-audit-reports/UserAccessReport/"
}

#Move the last logon reports to S3
$files3 = @()
$files3 = (get-childitem -Path "C:\Scripts\UserLastLogonReport"  | where-object {$_.LastWriteTime -lt (get-date).AddDays(-1)}).name
foreach($file3 in $files3)
{
    aws s3 --region eu-west-2 mv C:\Scripts\UserLastLogonReport\$file3 "s3://ad-audit-reports/UserLastLogonReport/"
}
