# HTTP API — receives POST /signup requests from the website
resource "aws_apigatewayv2_api" "website" {
  name          = "mythirdspace-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}", "https://${var.www_domain_name}"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

# deploy stage — $default auto-deploys on every change
resource "aws_apigatewayv2_stage" "website" {
  api_id      = aws_apigatewayv2_api.website.id
  name        = "$default"
  auto_deploy = true
}

# integration — connects API Gateway to the Lambda function
resource "aws_apigatewayv2_integration" "signup" {
  api_id                 = aws_apigatewayv2_api.website.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# route — POST /signup triggers the Lambda integration
resource "aws_apigatewayv2_route" "signup" {
  api_id    = aws_apigatewayv2_api.website.id
  route_key = "POST /signup"
  target    = "integrations/${aws_apigatewayv2_integration.signup.id}"
}

# permission — allows API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.website.execution_arn}/*/*"
}
