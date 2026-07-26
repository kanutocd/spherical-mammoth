aws_region    = "ap-southeast-1"
instance_type = "t3.micro"
ssh_cidr      = "203.0.113.10/32"

preload_images = [
  "postgres:17",
  "oryd/kratos:v1.3.1",
  "axllent/mailpit:latest",
  "ghcr.io/kanutocd/mammoth:v1.5.3",
]
