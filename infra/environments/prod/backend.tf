terraform {
  backend "s3" {
    bucket         = "<YOUR_STATE_BUCKET_NAME>"
    key            = "sauda/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sauda-terraform-state-lock"
    encrypt        = true
  }
}
