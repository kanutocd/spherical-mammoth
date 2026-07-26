# Persistent storage

The encrypted EBS data volume is independent of the launch template and guarded
with `prevent_destroy`. It survives instance replacement. The private S3 bucket
stores compressed deployment images and database backups using SSE-S3 to avoid
a KMS request-cost and permissions layer.
