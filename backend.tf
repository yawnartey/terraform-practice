#remote state file config
terraform {
  backend "s3" {
    bucket = "andlanc-terraform-state-files"
    key    = "anlanc_terraform.tfstate"
    region = "us-east-1"
  }
}