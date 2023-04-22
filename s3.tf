resource "aws_s3_bucket" "scripts_bucket" {
  bucket = "ps-scripts-bucket"
}

/*resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.scripts_bucket.id
}*/


resource "aws_s3_object" "scripts" {
  for_each = { for path in var.file_names : path => path }
  bucket   = aws_s3_bucket.scripts_bucket.id
  key      = each.value
  source   = "/Users/govindgupta/Repo/AD_Audit_Automatation/ps_scripts/${each.value}"
  etag     = filemd5("/Users/govindgupta/Repo/AD_Audit_Automatation/ps_scripts/${each.value}")
}