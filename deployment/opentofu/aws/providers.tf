provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({
      Project   = "spherical-mammoth"
      ManagedBy = "opentofu"
    }, var.tags)
  }
}
