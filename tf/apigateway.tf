locals {
  alb_metric_endpoint = "${var.elk_endpoint}/es"
}

resource "aws_api_gateway_rest_api" "elk" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "metrics" {
  parent_id   = aws_api_gateway_rest_api.elk.root_resource_id
  path_part   = "metrics"
  rest_api_id = aws_api_gateway_rest_api.elk.id
}

resource "aws_api_gateway_resource" "logs" {
  parent_id   = aws_api_gateway_rest_api.elk.root_resource_id
  path_part   = "logs"
  rest_api_id = aws_api_gateway_rest_api.elk.id
}

resource "aws_api_gateway_method" "logs" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.logs.id
  rest_api_id   = aws_api_gateway_rest_api.elk.id
}

resource "aws_api_gateway_method" "metrics" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.metrics.id
  rest_api_id   = aws_api_gateway_rest_api.elk.id
}

resource "aws_api_gateway_method_settings" "setting" {
  rest_api_id = aws_api_gateway_rest_api.elk.id
  stage_name  = aws_api_gateway_stage.elk.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "logs" {
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.logs.http_method
  resource_id             = aws_api_gateway_resource.logs.id
  rest_api_id             = aws_api_gateway_rest_api.elk.id
  type                    = "HTTP_PROXY"
  uri                     = "${local.alb_metric_endpoint}/logs"
}

resource "aws_api_gateway_integration" "metrics" {
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.logs.http_method
  resource_id             = aws_api_gateway_resource.metrics.id
  rest_api_id             = aws_api_gateway_rest_api.elk.id
  type                    = "HTTP_PROXY"
  uri                     = "${local.alb_metric_endpoint}/metrics"
}

resource "aws_api_gateway_deployment" "elk" {
  rest_api_id = aws_api_gateway_rest_api.elk.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.elk.root_resource_id,
      aws_api_gateway_method.logs.id,
      aws_api_gateway_method.metrics.id,
      aws_api_gateway_integration.logs.id,
      aws_api_gateway_integration.metrics.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "elk" {
  deployment_id = aws_api_gateway_deployment.elk.id
  rest_api_id   = aws_api_gateway_rest_api.elk.id
  stage_name    = "elk"
  depends_on    = [aws_cloudwatch_log_group.elk]
}

resource "aws_cloudwatch_log_group" "elk" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.elk.id}/elk"
  retention_in_days = 7
}

output "api_endpoint" {
  value = aws_api_gateway_stage.elk.invoke_url
}
