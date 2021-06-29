locals {
	es_metrics_endpoint = "${var.api_gateway_endpoint}/metrics"
	es_logs_endpoint = "${var.api_gateway_endpoint}/logs"
}
# firehose s3 bucket
resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "${var.eks_cluster_name}-${data.aws_caller_identity.current.account_id}-${var.region}-firehose"
  acl    = "private"
}

# kinesis firehose
resource "aws_kinesis_firehose_delivery_stream" "metrics" {
  name        = "metrics-${var.eks_cluster_name}"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = local.es_metrics_endpoint
    name               = var.eks_cluster_name
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose.arn
    s3_backup_mode     = "AllData"
    retry_duration     = 0
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_metrics.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_metrics.name
    }
  }

  s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn
  }
}


resource "aws_kinesis_firehose_delivery_stream" "logs" {
  name        = "logs-${var.eks_cluster_name}"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = local.es_logs_endpoint
    name               = var.eks_cluster_name
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose.arn
    s3_backup_mode     = "AllData"
    retry_duration     = 0
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_metrics.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_metrics.name
    }
  }

  s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn
  }
}

resource "aws_cloudwatch_log_group" "firehose_metrics" {
  name = "/aws/kinesis/firehose/log/${var.eks_cluster_name}"
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

resource "aws_cloudwatch_log_stream" "firehose_metrics" {
  name           = "/aws/kinesis/firehose/stream/${var.eks_cluster_name}"
  log_group_name = aws_cloudwatch_log_group.firehose_metrics.name
}

resource "aws_iam_role" "firehose" {
  name = "firehose-stream-${var.eks_cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

resource "aws_iam_role_policy" "firehose_to_s3" {
  name = "default"
  role = aws_iam_role.firehose.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
								"logs:*"
            ],
            "Resource": "${aws_cloudwatch_log_group.firehose_metrics.arn}:*:*"
        },
				{
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "${aws_s3_bucket.firehose_bucket.arn}"
				},
				{
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "${aws_s3_bucket.firehose_bucket.arn}/*"
				},
				{
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:*",
								"glue:*",
								"lambda:*",
								"kms:*",
								"kinesis:*"
            ],
            "Resource": "*"
				}
    ]
}
EOF
}

# metric stream
resource "aws_cloudwatch_metric_stream" "metric" {
  name          = "metric-stream-${var.eks_cluster_name}"
  role_arn      = aws_iam_role.metric_stream_to_firehose.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.metrics.arn
  output_format = "json"

  include_filter {
    namespace = "AWS/Lambda"
  }

  include_filter {
    namespace = "AWS/DynamoDB"
  }

  include_filter {
    namespace = "AWS/Billing"
  }

  include_filter {
    namespace = "AWS/AppSync"
  }
}

resource "aws_iam_role" "metric_stream_to_firehose" {
  name = "metric-stream-to-firehose-${var.eks_cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "streams.metrics.cloudwatch.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

resource "aws_iam_role_policy" "metric_stream_to_firehose" {
  name = "default"
  role = aws_iam_role.metric_stream_to_firehose.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.metrics.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "logs_stream_to_firehose" {
  name = "logs-stream-to-firehose-${var.eks_cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${var.region}.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

resource "aws_iam_role_policy" "logs_stream_to_firehose" {
  role = aws_iam_role.logs_stream_to_firehose.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.logs.arn}"
        }
    ]
}
EOF
}
