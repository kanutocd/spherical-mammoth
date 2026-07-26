resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_snapshot_id == null ? var.data_volume_size_gib : null
  snapshot_id       = var.data_volume_snapshot_id
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name        = "${var.name}-data"
    Persistence = "retain"
    Role        = "golden-mammoth-data"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "${var.name}-"
  force_destroy = var.force_destroy_bucket
  tags          = merge(var.tags, { Name = "${var.name}-artifacts" })
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "trim-old-artifacts"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 14
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
