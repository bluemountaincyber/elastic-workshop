resource "aws_iam_role" "os_role" {
  name = "OpensearchRole"
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

resource "aws_iam_instance_profile" "os_profile" {
  name = "OpensearchInstanceProfile"
  role = aws_iam_role.os_role.name
}

resource "aws_iam_policy" "os_policy" {
  name        = "OpensearchKinesisPolicy"
  path        = "/"
  description = "Opensearch Kinesis Setup"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OpensearchKinesisSetup"
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

resource "aws_iam_role_policy_attachment" "os_policy_attachment" {
  role       = aws_iam_role.os_role.name
  policy_arn = aws_iam_policy.os_policy.arn
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
        Action   = "s3:ListBuckets"
        Resource = "*"
      },
      {
        Sid      = "S3GetObject"
        Effect   = "Allow"
        Action   = "s3:GetObject"
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
  name = "OpensearchCloudTrailRole"
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
  name        = "OpensearchCloudTrailCloudWatchPolicy"
  path        = "/"
  description = "Allow CloudTrail to write to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AWSCloudTrailCreateLogStream"
        Effect   = "Allow"
        Action   = "logs:CreateLogStream"
        Resource = "${aws_cloudwatch_log_group.os_cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
      },
      {
        Sid      = "AWSCloudTrailPutLogEvents"
        Effect   = "Allow"
        Action   = "logs:PutLogEvents"
        Resource = "${aws_cloudwatch_log_group.os_cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${var.aws_region}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attachment" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = aws_iam_policy.cloudtrail_policy.arn
}

resource "aws_iam_role" "cloudwatch_role" {
  name = "OpensearchCloudWatchRole"
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
  name        = "OpensearchCloudWatchKinesisPolicy"
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
        Resource = "${aws_kinesis_stream.os_kinesis_stream.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}