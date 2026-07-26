output "data_volume_id" { value = aws_ebs_volume.data.id }
output "data_volume_arn" { value = aws_ebs_volume.data.arn }
output "bucket_name" { value = aws_s3_bucket.artifacts.id }
output "bucket_arn" { value = aws_s3_bucket.artifacts.arn }
