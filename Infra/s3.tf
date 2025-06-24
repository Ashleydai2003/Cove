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

resource "aws_s3_bucket" "cove_images" {
  bucket = "cove-cove-images"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "cove_images_versioning" {
  bucket = aws_s3_bucket.cove_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cove_images_encryption" {
  bucket = aws_s3_bucket.cove_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "event_images" {
  bucket = "cove-event-images"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "event_images_versioning" {
  bucket = aws_s3_bucket.event_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "event_images_encryption" {
  bucket = aws_s3_bucket.event_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

