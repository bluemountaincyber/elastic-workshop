resource "aws_s3_bucket" "sensitive" {
  bucket        = "sensitive-${random_string.suffix.result}"
  force_destroy = true
}

resource "local_file" "sensitive_file" {
  content  = "https://www.youtube.com/watch?v=xfr64zoBTAQ"
  filename = "${path.module}/sensitive.txt"
}

resource "aws_s3_object" "sensitive_object" {
  bucket     = aws_s3_bucket.sensitive.id
  key        = "sensitive.txt"
  source     = "${path.module}/sensitive.txt"
  depends_on = [local_file.sensitive_file]
}

resource "aws_s3_bucket" "os_cloudtrail" {
  bucket        = "os-cloudtrail-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "os_cloudtrail" {
  bucket = aws_s3_bucket.os_cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          "Service" : "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "${aws_s3_bucket.os_cloudtrail.arn}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          "Service" : "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.os_cloudtrail.arn}/Opensearch/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}