terraform {
  backend "s3" {
    bucket         = "chatopsbot-terraform-state-safwinho"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "chatopsbot-terraform-locks"   
    encrypt        = true
  }
}