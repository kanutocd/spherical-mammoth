output "instance_connect_endpoint_id" { value = module.networking.eice_id }
output "autoscaling_group_name" { value = module.compute.autoscaling_group_name }
output "data_volume_id" { value = module.storage.data_volume_id }
output "deployment_bucket" { value = module.storage.bucket_name }
output "operator_policy_arn" { value = module.operator_access.policy_arn }
output "private_tunnel_examples" {
  value = {
    kubernetes_api = "aws ec2-instance-connect open-tunnel --instance-connect-endpoint-id ${module.networking.eice_id} --instance-id INSTANCE_ID --remote-port 6443 --local-port 6443"
    http_preview   = "aws ec2-instance-connect open-tunnel --instance-connect-endpoint-id ${module.networking.eice_id} --instance-id INSTANCE_ID --remote-port 80 --local-port 8080"
    https_preview  = "aws ec2-instance-connect open-tunnel --instance-connect-endpoint-id ${module.networking.eice_id} --instance-id INSTANCE_ID --remote-port 443 --local-port 8443"
  }
}
