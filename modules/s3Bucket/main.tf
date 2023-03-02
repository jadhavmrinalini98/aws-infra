resource "random_uuid" "uuid" {
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "${random_uuid.uuid.result}-${var.environment}"
  force_destroy = true

  tags = {
    Name = "${random_uuid.uuid.result}"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {

  depends_on = [aws_s3_bucket.s3_bucket]
  bucket     = aws_s3_bucket.s3_bucket.id

  rule {
    id = "log"

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3encrypt" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "s3_bucket" {
  value = aws_s3_bucket.s3_bucket.id
}