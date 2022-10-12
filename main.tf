provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket = "stf-state-bucket"
    key    = "workflow"
    region = "eu-west-2"
  }
}
