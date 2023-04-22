# AD_Audit_Automatation
AD Automation using PowerShell

I have created a few powershell scripts for Active Directory Users Audit. 
The first script generates the users last logoin and access report. 
Second script sends a reminder email to the users ho has not logged in for more than 60 days. 
The third script checks for users who has not logged in for 90 days and then disable those users. It also send them an email stating their account has disabled. 
The forth one delete any users who are in disabled OU and hasn't logged in for 180 days or more. It also checks for users which are in disabled state.
All the above scripts generate reports and save them in C drive. 
Fifth script move these reports to a s3 bucket.

![alt Task_Schedular_Screenshot](https://github.com/gpgupta7891-p/AD_Audit_Automatation/blob/main/task_schedular_screenshot.jpg?raw=true)