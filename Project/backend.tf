terraform {
  backend "s3" {
    bucket         = "devops-final-dev-tf-state-71abd78d" 
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-final-dev-tf-locks"       
    encrypt        = true
  }
}