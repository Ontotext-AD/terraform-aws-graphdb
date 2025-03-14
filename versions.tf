terraform {
  required_version = ">= 1.9.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.6.0"
    }
  }
}
