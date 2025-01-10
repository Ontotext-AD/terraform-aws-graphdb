terraform {
  required_version = ">= 1.9.4"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.49"
      configuration_aliases = [aws.useast1]
    }
  }
}
