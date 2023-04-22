resource "aws_ssm_document" "user_access_report" {
  name          = "user-access-report"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Set up a task in task scheduler to generate user access report every month",
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
          "$Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At 7am",
          "$Action = New-ScheduledTaskAction -Execute \"PowerShell.exe\" -Argument \"C:\\Scripts\\user_access_report.ps1\"",
          "Register-ScheduledTask -TaskName \"User_Access_Report\" -Trigger $Trigger -User 'SYSTEM' -Action $Action -RunLevel Highest",
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

resource "aws_ssm_document" "reminder_script" {
  name          = "reminder-script"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Set up a task in task scheduler to to send reminder emails to users if they have not logged on for more than more than 60 days",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "reminder_script",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "aws s3 cp s3://${aws_s3_bucket.scripts_bucket.id}/RemindUsers_not_loggedin_for_more_than_60days.ps1 C://Scripts//RemindUsers_not_loggedin_for_more_than_60days.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "schtasks /create /tn RemindUsers_not_loggedin_for_more_than_60days /tr \"PowerShell.exe C:\\Scripts\\RemindUsers_not_loggedin_for_more_than_60days.ps1\" /sc monthly /d 1 /st 08:00 /ru SYSTEM /NP /RL HIGHEST" 
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "reminder_script" {
  name = aws_ssm_document.reminder_script.name

  parameters = {}

  targets {
    key    = "tag:Name"
    values = ["AD_Management"]
  }
}

resource "aws_ssm_document" "users_disable_script" {
  name          = "users-disable-script"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Set up a task in task scheduler to disable users if they have not logged on for more than more than 90 days",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "users_disable_script",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "aws s3 cp s3://${aws_s3_bucket.scripts_bucket.id}/Disable_Users_not_loggedin_for_more_than_90days.ps1 C://Scripts//Disable_Users_not_loggedin_for_more_than_90days.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "schtasks /create /tn Disable_Users_not_loggedin_for_more_than_90days /tr \"PowerShell.exe C:\\Scripts\\Disable_Users_not_loggedin_for_more_than_90days.ps1\" /sc monthly /d 2 /st 08:00 /ru SYSTEM /NP /RL HIGHEST" 
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "users_disable_script" {
  name = aws_ssm_document.users_disable_script.name

  parameters = {}

  targets {
    key    = "tag:Name"
    values = ["AD_Management"]
  }
}

resource "aws_ssm_document" "users_delete_script" {
  name          = "users-delete-script"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Set up a task in task scheduler to delete users if they have not logged on for more than more than 180 days",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "users_delete_script",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "aws s3 cp s3://${aws_s3_bucket.scripts_bucket.id}/Delete_ADUsers_disabled_for_more_than_180days.ps1 C://Scripts//Delete_ADUsers_disabled_for_more_than_180days.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "schtasks /create /tn Delete_ADUsers_disabled_for_more_than_180days /tr \"PowerShell.exe C:\\Scripts\\Delete_ADUsers_disabled_for_more_than_180days.ps1\" /sc monthly /d 3 /st 08:00 /ru SYSTEM /NP /RL HIGHEST" 
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "users_delete_script" {
  name = aws_ssm_document.users_delete_script.name

  parameters = {}

  targets {
    key    = "tag:Name"
    values = ["AD_Management"]
  }
}

resource "aws_ssm_document" "move_reports_to_s3" {
  name          = "move-reports-to-s3"
  document_type = "Command"

  content = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Set up a task in task scheduler to move the reports older than a day to s3 bucket",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "move_reports_to_s3",
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "inputs": {
        "runCommand": [
          "aws s3 cp s3://${aws_s3_bucket.scripts_bucket.id}/Move_Audit_Reports_to_S3.ps1 C://Scripts//Move_Audit_Reports_to_S3.ps1",
          "Write-Output \"$(Get-Date -format T) - Setting up start web manager in task scheduler\"",
          "schtasks /create /tn Move_Audit_Reports_to_S3 /tr \"PowerShell.exe C:\\Scripts\\Move_Audit_Reports_to_S3.ps1\" /sc monthly /d 4 /st 08:00 /ru SYSTEM /NP /RL HIGHEST" 
        ]
      }
    }
  ]
}
DOC
}

resource "aws_ssm_association" "move_reports_to_s3" {
  name = aws_ssm_document.move_reports_to_s3.name

  parameters = {}

  targets {
    key    = "tag:Name"
    values = ["AD_Management"]
  }
}
