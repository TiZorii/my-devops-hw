terraform {
  backend "s3" {
    bucket         = "tetiana-zorii-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}