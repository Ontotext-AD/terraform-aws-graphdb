terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.15"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
