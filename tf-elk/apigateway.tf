locals {
  alb_metric_endpoint = "${var.alb_endpoint}/es/test_metrics/_doc"
}

resource "aws_api_gateway_rest_api" "es" {
  name = "es"
}

resource "aws_api_gateway_resource" "metrics" {
  parent_id   = aws_api_gateway_rest_api.es.root_resource_id
  path_part   = "test_metrics"
  rest_api_id = aws_api_gateway_rest_api.es.id
}

resource "aws_api_gateway_resource" "metrics_doc" {
  parent_id   = aws_api_gateway_resource.metrics.id
  path_part   = "_doc"
  rest_api_id = aws_api_gateway_rest_api.es.id
}

resource "aws_api_gateway_method" "metrics_doc" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.metrics_doc.id
  rest_api_id   = aws_api_gateway_rest_api.es.id
}

resource "aws_api_gateway_method_settings" "metrics_doc" {
  rest_api_id = aws_api_gateway_rest_api.es.id
  stage_name  = aws_api_gateway_stage.es.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "metrics_doc" {
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.metrics_doc.http_method
  resource_id             = aws_api_gateway_resource.metrics_doc.id
  rest_api_id             = aws_api_gateway_rest_api.es.id
  type                    = "HTTP_PROXY"
  uri                     = local.alb_metric_endpoint
}

resource "aws_api_gateway_deployment" "es" {
  rest_api_id = aws_api_gateway_rest_api.es.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.metrics.id,
      aws_api_gateway_resource.metrics_doc.id,
      aws_api_gateway_method.metrics_doc.id,
      aws_api_gateway_integration.metrics_doc.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "es" {
  deployment_id = aws_api_gateway_deployment.es.id
  rest_api_id   = aws_api_gateway_rest_api.es.id
  stage_name    = "es"
  depends_on    = [aws_cloudwatch_log_group.es]
}

resource "aws_cloudwatch_log_group" "es" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.es.id}/es"
  retention_in_days = 7
}

output "api_endpoint" {
  value = aws_api_gateway_stage.es.invoke_url
}
