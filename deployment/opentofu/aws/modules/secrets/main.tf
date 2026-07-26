resource "aws_kms_key" "this" {
  description             = "Encrypt ${var.name} application secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}-secrets"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = "${var.name}/${each.key}"
  description             = each.value
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}
