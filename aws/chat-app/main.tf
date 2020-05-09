provider "aws" {
  region = var.region
}

# --- start setting up S3 bucket resources. -------

resource "aws_s3_bucket" "chat_bucket" {
  bucket = var.chat_domain
  region = var.region
  acl = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "myBucketPolicy",
  "Statement": [
    {
      "Sid": "PublicReadAccesForWebsite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": ["arn:aws:s3:::${var.chat_domain}/*" ]
    }
  ]
}
POLICY
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  key = "index.html"
  content_type = "text/html"
  source = "index.html"
}

resource "aws_s3_bucket_object" "error_html" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  key = "error.html"
  content_type = "text/html"
  source = "error.html"
}

resource "aws_s3_bucket_object" "upload_web_app" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "**")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "text/html"
}

output "web_app_resources_uploaded" {
  value = fileset("${path.module}/web-app", "**")
}

# --- end setting up S3 bucket resources. -------