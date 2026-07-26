locals {
  issuer_hostpath = replace(var.oidc_issuer_url, "https://", "")
  subject         = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
}

resource "aws_iam_role" "this" {
  name = "${var.name}-mammoth"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.issuer_hostpath}:aud" = "sts.amazonaws.com"
          "${local.issuer_hostpath}:sub" = local.subject
        }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "this" {
  name = "mammoth-runtime"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRuntimeSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
        Resource = var.secret_arns
      },
      {
        Sid    = "UseEncryptionKeys"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
        ]
        Resource = var.kms_key_arns
      },
      {
        Sid      = "ListObjectBucket"
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = var.bucket_arn
      },
      {
        Sid      = "UseObjectBucket"
        Effect   = "Allow"
        Action   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = "${var.bucket_arn}/*"
      },
    ]
  })
}
