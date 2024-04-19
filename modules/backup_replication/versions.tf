terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.15"
      configuration_aliases = [aws.bucket_replication_destination_region]
    }
  }
}
