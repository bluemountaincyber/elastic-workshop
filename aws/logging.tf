resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "aws_cloudtrail" "os_cloudtrail" {
  name                          = "os-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.os_cloudtrail.id
  s3_key_prefix                 = "Opensearch"
  include_global_service_events = false
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.os_cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
}

resource "aws_kinesis_stream" "os_kinesis_stream" {
  name             = "AWS_Logs"
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_cloudwatch_log_group" "os_cloudtrail" {
  name = "opensearch/cloudtrail"
}

resource "aws_cloudwatch_log_group" "os_victim_access" {
  name = "opensearch/apache-access-log"
}

resource "aws_cloudwatch_log_group" "os_victim_syslog" {
  name = "opensearch/syslog"
}

resource "aws_cloudwatch_log_subscription_filter" "os_cloudtrail_logfilter" {
  name            = "os-cloudtrail-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.os_cloudtrail.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.os_kinesis_stream.arn
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "os_access_logs_logfilter" {
  name            = "os-access-logs-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.os_victim_access.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.os_kinesis_stream.arn
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "os_syslog_logfilter" {
  name            = "os-syslog-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.os_victim_syslog.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.os_kinesis_stream.arn
  distribution    = "Random"
}