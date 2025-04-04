terraform {
  required_version = ">= 1.9.4"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.87.0"
      configuration_aliases = [aws.bucket_replication_destination_region]
    }
  }
}
