#Move the privelaged reports to S3
$files = @()
$files = (get-childitem -Path "C:\Scripts\Reports"  | where-object {$_.LastWriteTime -lt (get-date).AddDays(-1)}).name
foreach($file in $files)
{
    aws s3 --region eu-west-2 mv C:\Scripts\Reports\$file "s3://ps-scripts-bucket/Reports/"
}