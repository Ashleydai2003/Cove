resource "aws_s3_bucket" "user_images" {
  bucket = "cove-user-images"

  tags = local.common_tags
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "user_images_versioning" {
  bucket = aws_s3_bucket.user_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "user_images_encryption" {
  bucket = aws_s3_bucket.user_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

