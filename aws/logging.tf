resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "aws_cloudtrail" "el_cloudtrail" {
  name                          = "el-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.el_cloudtrail.id
  s3_key_prefix                 = "Elastic"
  include_global_service_events = false
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.el_cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  depends_on                    = [aws_s3_bucket_policy.el_cloudtrail]
}

resource "aws_kinesis_stream" "el_kinesis_stream" {
  name             = "AWS_Logs"
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_cloudwatch_log_group" "el_cloudtrail" {
  name = "elastic/cloudtrail"
}

resource "aws_cloudwatch_log_group" "el_victim_access" {
  name = "elastic/apache-access-log"
}

resource "aws_cloudwatch_log_group" "el_victim_syslog" {
  name = "elastic/syslog"
}

resource "aws_cloudwatch_log_subscription_filter" "el_cloudtrail_logfilter" {
  name            = "el-cloudtrail-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.el_cloudtrail.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.el_kinesis_stream.arn
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "el_access_logs_logfilter" {
  name            = "el-access-logs-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.el_victim_access.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.el_kinesis_stream.arn
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "el_syslog_logfilter" {
  name            = "el-syslog-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = aws_cloudwatch_log_group.el_victim_syslog.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.el_kinesis_stream.arn
  distribution    = "Random"
}