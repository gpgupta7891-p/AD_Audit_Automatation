vpc_cidr = "10.0.0.0/16"
public_subnet1 = "10.0.1.0/24"
region   = "eu-west-2"
file_names = [
    "Delete_ADUsers_disabled_for_more_than_180days.ps1",
    "Move_Audit_Reports_to_S3.ps1",
    "user_access_report.ps1",
    "Disable_Users_not_loggedin_for_more_than_90days.ps1",
    "RemindUsers_not_loggedin_for_more_than_60days.ps1"
]