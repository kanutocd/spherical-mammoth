provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge({
      Project      = "spherical-mammoth"
      Environment  = var.environment
      ManagedBy    = "opentofu"
      CostModel    = "poorman"
      Orchestrator = "k3s"
    }, var.tags)
  }
}
