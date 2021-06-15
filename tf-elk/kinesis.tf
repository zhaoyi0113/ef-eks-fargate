resource "aws_kinesis_firehose_delivery_stream" "stream" {
  name        = "stream-${var.eks_cluster_name}"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = var.es_endpoint
    name               = var.eks_cluster_name
    buffering_size     = 15
    buffering_interval = 600
    role_arn           = aws_iam_role.firehose.arn
  }

	s3_configuration {
		role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.firehose_bucket.arn
	}
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-elk-firehose"
  acl    = "private"
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