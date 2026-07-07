terraform {
  backend "s3" {
    bucket         = "sauda-state-885160773323"
    key            = "sauda/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sauda-terraform-state-lock"
    encrypt        = true
  }
}
