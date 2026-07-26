variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "availability_zone" {
  description = "Single AZ containing both the instance and its persistent EBS volume."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the sealed VPC."
  type        = string
  default     = "10.60.0.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the single private subnet."
  type        = string
  default     = "10.60.0.0/26"
}

variable "ami_id" {
  description = "Pre-baked Golden Mammoth AMI containing Docker, Compose, and runtime dependencies."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Select one covered by the account's current free-tier or credits."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size_gib" {
  description = "Disposable root volume size."
  type        = number
  default     = 8
}

variable "data_volume_size_gib" {
  description = "Persistent PostgreSQL and Mammoth data volume size."
  type        = number
  default     = 22
}

variable "data_volume_snapshot_id" {
  description = "Optional snapshot used to seed the persistent data volume."
  type        = string
  default     = null
}

variable "data_device_name" {
  description = "EC2 attachment name. Nitro instances expose this as an NVMe device."
  type        = string
  default     = "/dev/sdf"
}

variable "data_mount_path" {
  description = "Mount point for persistent application data."
  type        = string
  default     = "/srv/mammoth"
}

variable "deployment_prefix" {
  description = "S3 prefix from which deployment artifacts are read."
  type        = string
  default     = "deployments"
}

variable "backup_prefix" {
  description = "S3 prefix to which database backups may be written."
  type        = string
  default     = "backups"
}

variable "operator_principal_arns" {
  description = "IAM principals allowed to open an EICE tunnel and push an ephemeral SSH key."
  type        = set(string)
  default     = []
}

variable "asg_health_check_grace_period" {
  description = "Seconds before ASG EC2 health checks begin."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional AWS resource tags."
  type        = map(string)
  default     = {}
}
