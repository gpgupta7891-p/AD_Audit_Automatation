
data "aws_ami" "windows" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["801119661308"] # Canonical
}

resource "aws_instance" "ad_mgmt" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t2.medium"
  key_name                    = "web_keypair"
  vpc_security_group_ids      = [aws_security_group.web_sg_public.id]
  subnet_id                   = aws_subnet.public01.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_iam_profile.name
  user_data                   = <<EOF
<powershell>
New-Item -ItemType directory -Path "C:\Installers"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://awscli.amazonaws.com/AWSCLIV2.msi","C:\Installers\awscliv2.msi")
Start-Process msiexec.exe -Wait -ArgumentList '/i C:\Installers\awscliv2.msi /qn /l*v C:\Installers\aws-cli-install.log'
</powershell>
EOF

  tags = {
    Name = "AD_Management"
  }
}