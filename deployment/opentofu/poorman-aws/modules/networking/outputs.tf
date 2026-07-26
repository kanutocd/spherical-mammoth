output "vpc_id" { value = aws_vpc.this.id }
output "private_subnet_id" { value = aws_subnet.private.id }
output "instance_security_group_id" { value = aws_security_group.instance.id }
output "eice_id" { value = aws_ec2_instance_connect_endpoint.this.id }
output "eice_arn" { value = aws_ec2_instance_connect_endpoint.this.arn }
output "s3_endpoint_id" { value = aws_vpc_endpoint.s3.id }
