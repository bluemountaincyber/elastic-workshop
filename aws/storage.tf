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

resource "aws_s3_bucket" "el_cloudtrail" {
  bucket        = "el-cloudtrail-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "el_cloudtrail" {
  bucket = aws_s3_bucket.el_cloudtrail.id
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
        Resource = "${aws_s3_bucket.el_cloudtrail.arn}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          "Service" : "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.el_cloudtrail.arn}/Elastic/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "el_evidence" {
  bucket        = "el-evidence-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_notification" "lambda_notification" {
  bucket = aws_s3_bucket.el_evidence.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.el_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_lambda_permission.el_s3_lambda
  ]
}

module "shell_execute" {
  source               = "github.com/matti/terraform-shell-resource"
  command_when_destroy = "aws dynamodb delete-table --table-name logstash --region ${var.aws_region} 2>/dev/null || exit 0"
}