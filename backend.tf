#create the S3 bucket for your state files 
resource "aws_s3_bucket" "andlanc-terraform-state-files" {
  bucket = "andlanc-terraform-state-files"
  tags = {
    Name  = "andlanc-state-files"
  }
}

#enable bucket versioning 
resource "aws_s3_bucket_versioning" "andlanc-terraform-state-files-versioning" {
  bucket = aws_s3_bucket.andlanc-terraform-state-files.id
  versioning_configuration {
    status = "Enabled"
  }
}

#remote state file config
# terraform {
#   backend "s3" {
#     bucket = "andlanc-terraform-state-files"
#     key    = "anlanc_terraform.tfstate"
#     region = "us-east-1"
#   }
# }