terraform {
  required_version = ">= 1.7.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.6.0"
    }
  }
}
