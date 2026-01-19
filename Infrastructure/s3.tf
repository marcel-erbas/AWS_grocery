# Create the S3 bucket for storing user profile pictures
resource "aws_s3_bucket" "avatars" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = "dev"
  }
}


# Create folder in the bucket
resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.avatars.id
  key    = "avatars/"
}


# Upload the default profile image to the avatars folder
resource "aws_s3_object" "default_avatar" {
  bucket       = aws_s3_bucket.avatars.id
  key          = "avatars/default_user.png"
  source       = "default_user.png"
  content_type = "image/png"
}


# Configure Public Access Block to allow public visibility only if needed
resource "aws_s3_bucket_public_access_block" "avatars_access" {
  bucket = aws_s3_bucket.avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Define a bucket policy to grant the EC2 IAM role access to objects
resource "aws_s3_bucket_policy" "allow_ec2_access" {
  bucket = aws_s3_bucket.avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2RoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.grocery_ec2_role.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.avatars.arn,
          "${aws_s3_bucket.avatars.arn}/*"
        ]
      }
    ]
  })
}