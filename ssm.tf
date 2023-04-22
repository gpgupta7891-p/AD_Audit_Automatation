resource "aws_ssm_document" "user_access_report" {
  name          = "user-access-report"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Sets up task scheduler to generate user access report every month",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "user_access_report",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "New-Item -ItemType directory -Path C://Scripts",
          "aws s3 cp s3://${aws_s3_bucket.scripts_bucket.id}/user_access_report.ps1 C://Scripts//user_access_report.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "$Repeat = (New-TimeSpan -Days 7)",
          "$Duration = (New-TimeSpan -Days (365*20))",
          "$Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At 8am",
          "$Action = New-ScheduledTaskAction -Execute \"PowerShell.exe\" -Argument \"C:\\Scripts\\user_access_report.ps1\"",
          "Register-ScheduledTask -TaskName \"user_access_report\" -Trigger $Trigger -User 'SYSTEM' -Action $Action",
          "Write-Output \"$(Get-Date -format T) - Successfully scheduled user-access-report\""
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "user_access_report" {
  name = aws_ssm_document.user_access_report.name

  parameters = {}

  targets {
    key    = "tag:Name"
    values = ["AD_Management"]
  }
}
