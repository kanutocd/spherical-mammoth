variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR for the platform VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway to reduce non-production cost."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Optional EKS Kubernetes version. Null lets EKS choose its current default."
  type        = string
  default     = null
}

variable "cluster_public_access" {
  description = "Expose the EKS API endpoint publicly in addition to privately."
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the default EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "EKS node capacity type."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum default node group size."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired default node group size."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum default node group size."
  type        = number
  default     = 4
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs granted EKS cluster-admin through access entries."
  type        = set(string)
  default     = []
}

variable "postgres_version" {
  description = "RDS PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "postgres_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "postgres_multi_az" {
  description = "Create a Multi-AZ RDS instance."
  type        = bool
  default     = false
}

variable "postgres_deletion_protection" {
  description = "Protect the RDS instance from deletion."
  type        = bool
  default     = false
}

variable "postgres_skip_final_snapshot" {
  description = "Skip a final RDS snapshot on destroy."
  type        = bool
  default     = true
}

variable "postgres_backup_retention_days" {
  description = "RDS automated backup retention."
  type        = number
  default     = 7
}

variable "mammoth_namespace" {
  description = "Kubernetes namespace used by Mammoth."
  type        = string
  default     = "mammoth"
}

variable "mammoth_service_account" {
  description = "Kubernetes service account used by Mammoth."
  type        = string
  default     = "mammoth"
}

variable "tags" {
  description = "Additional tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
