resource "aws_ssm_document" "move_iis_logs_to_s3" {
  name          = "${local.prefix}-move-iis-logs-to-s3"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Sets up task scheduler to move iis logs to s3 every 7 days",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "move_iis_logs_to_s3",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "$paramAdGroupNameAdm = (Get-SSMParameterValue -Name s3_bucket_for_iis_logs -WithDecryption $True).Parameters[0].Value",
          "aws s3 cp s3://$paramAdGroupNameAdm/move_iis_logs_to_s3.ps1 C://Scripts//move_iis_logs_to_s3.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "$Repeat = (New-TimeSpan -Days 7)",
          "$Duration = (New-TimeSpan -Days (365*20))",
          "$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At 12am",
          "$Action = New-ScheduledTaskAction -Execute \"PowerShell.exe\" -Argument \"C:\\Scripts\\move_iis_logs_to_s3.ps1\"",
          "Register-ScheduledTask -TaskName \"move_iis_logs_to_s3\" -Trigger $Trigger -User 'SYSTEM' -Action $Action",
          "Write-Output \"$(Get-Date -format T) - Successfully scheduled move_iis_logs_to_s3\""
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "move_iis_logs_to_s3" {
  name = aws_ssm_document.move_iis_logs_to_s3.name

  parameters = {}

  targets {
    key    = "tag:OS"
    values = ["Windows"]
  }

  targets {
    key    = "tag:role"
    values = ["web_server"]
  }

}

resource "aws_ssm_parameter" "s3_bucket_for_iislogs" {
  name        = "s3_bucket_for_iis_logs"
  description = "S3 Bucket name which store IIS logs from Relativity Web servers"
  type        = "String"
  value       = aws_s3_bucket.iis_web_server_logs.bucket
}
