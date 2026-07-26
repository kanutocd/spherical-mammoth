data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "this" {
  name        = "${var.name}-operator"
  description = "Discover and reach the Golden Mammoth instance through EICE"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DiscoverGoldenMammoth"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstanceConnectEndpoints", "ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Sid      = "OpenEiceTunnel"
        Effect   = "Allow"
        Action   = "ec2-instance-connect:OpenTunnel"
        Resource = var.eice_arn
        Condition = {
          NumericEquals = {
            "ec2-instance-connect:remotePort" = [for port in var.allowed_tunnel_ports : tostring(port)]
          }
          NumericLessThanEquals = {
            "ec2-instance-connect:MaxTunnelDuration" = "3600"
          }
        }
      },
      {
        Sid      = "PushEphemeralSshKey"
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/aws:autoscaling:groupName" = var.autoscaling_group_name
            "ec2:osuser"                                = "ec2-user"
          }
        }
      },
      {
        Sid      = "UploadDeploymentManifest"
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = var.deployment_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.deployment_prefix,
              "${var.deployment_prefix}/*",
            ]
          }
        }
      },
      {
        Sid      = "UploadDeploymentArtifacts"
        Effect   = "Allow"
        Action   = ["s3:AbortMultipartUpload", "s3:PutObject"]
        Resource = "${var.deployment_bucket_arn}/${var.deployment_prefix}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operator" {
  for_each = var.operator_principal_arns

  role       = element(reverse(split("/", each.value)), 0)
  policy_arn = aws_iam_policy.this.arn
}
