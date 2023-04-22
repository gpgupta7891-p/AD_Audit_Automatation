terraform {
  required_version = ">= 1.4.0"
  backend "s3" {
    bucket  = "terraform-state-gpgupta7891-p"
    key     = "AD_Audit_Automatation/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}