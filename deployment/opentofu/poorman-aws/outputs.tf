output "architecture" {
  value = "private EC2 ASG + persistent EBS + EICE + S3 gateway endpoint"
}

output "instance_connect_endpoint_id" {
  value = module.networking.eice_id
}

output "autoscaling_group_name" {
  value = module.compute.autoscaling_group_name
}

output "data_volume_id" {
  value = module.storage.data_volume_id
}

output "deployment_bucket" {
  value = module.storage.bucket_name
}

output "operator_policy_arn" {
  value = module.operator_access.policy_arn
}

output "discover_instance_command" {
  value = "aws ec2 describe-instances --region ${var.aws_region} --filters Name=tag:aws:autoscaling:groupName,Values=${module.compute.autoscaling_group_name} Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].InstanceId' --output text"
}

output "open_tunnel_command" {
  value = "aws ec2-instance-connect open-tunnel --region ${var.aws_region} --instance-connect-endpoint-id ${module.networking.eice_id} --instance-id INSTANCE_ID"
}
