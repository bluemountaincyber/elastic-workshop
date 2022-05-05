resource "aws_iam_role" "el_role" {
  name = "ElasticRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          "Service" : "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "el_profile" {
  name = "ElasticInstanceProfile"
  role = aws_iam_role.el_role.name
}

resource "aws_iam_policy" "el_policy" {
  name        = "ElasticKinesisPolicy"
  path        = "/"
  description = "Elastic Kinesis Setup"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElasticKinesisSetup"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "dynamodb:CreateTable",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:DescribeNetworkInterfaces",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "kinesis:CreateStream",
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "logs:DescribeLogGroups",
          "logs:PutSubscriptionFilter",
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "el_policy_attachment" {
  role       = aws_iam_role.el_role.name
  policy_arn = aws_iam_policy.el_policy.arn
}

resource "aws_iam_role" "victim_role" {
  name = "VictimRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          "Service" : "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "victim_profile" {
  name = "VictimInstanceProfile"
  role = aws_iam_role.victim_role.name
}

resource "aws_iam_policy" "victim_policy" {
  name        = "VictimCloudWatchS3Policy"
  path        = "/"
  description = "Victim CloudWatch and S3 Access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBuckets"
        Effect   = "Allow"
        Action   = "s3:List*"
        Resource = "*"
      },
      {
        Sid      = "S3GetObjectAndTag"
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.sensitive.arn}/*"
      },
      {
        Sid    = "CloudWatchReadWrite"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "victim_policy_attachment" {
  role       = aws_iam_role.victim_role.name
  policy_arn = aws_iam_policy.victim_policy.arn
}

resource "aws_iam_role" "cloudtrail_role" {
  name = "ElasticCloudTrailRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          "Service" : "cloudtrail.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "cloudtrail_policy" {
  name        = "ElasticCloudTrailCloudWatchPolicy"
  path        = "/"
  description = "Allow CloudTrail to write to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AWSCloudTrailCreateLogStream"
        Effect   = "Allow"
        Action   = "logs:CreateLogStream"
        Resource = "${aws_cloudwatch_log_group.el_cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
      },
      {
        Sid      = "AWSCloudTrailPutLogEvents"
        Effect   = "Allow"
        Action   = "logs:PutLogEvents"
        Resource = "${aws_cloudwatch_log_group.el_cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = aws_iam_policy.cloudtrail_policy.arn
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "ElasticCloudWatchRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          "Service" : "logs.${var.aws_region}.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
        Condition = {
          "StringLike" : {
            "aws:SourceArn" : "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "ElasticCloudWatchKinesisPolicy"
  path        = "/"
  description = "Allow CloudWatch to write to Kinesis"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSKinesisPutRecord"
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord"
        ]
        Resource = "${aws_kinesis_stream.el_kinesis_stream.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_role" "el_lambda" {
  name = "ElasticLambdaRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "el_lambda_policy" {
  name        = "ElasticLambdaPolicy"
  path        = "/"
  description = "Allow CloudWatch to write to Kinesis"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CreateCloudWatchLogGroup"
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "WriteCloudWatchEvents"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutEventLogs"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.el_function.function_name}:*"
      },
      {
        Sid    = "AddS3ObjectTags"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObjectTagging"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.el_evidence.id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.el_lambda.name
  policy_arn = aws_iam_policy.el_lambda_policy.arn
}

resource "aws_lambda_permission" "el_s3_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.el_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.el_evidence.arn
}