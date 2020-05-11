# TODO break it into modules.

provider "aws" {
  region = var.region
}

# --- start setting up S3 bucket resources. -------

resource "aws_s3_bucket" "chat_bucket" {
  bucket = var.chat_domain
  region = var.region
  acl = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "myBucketPolicy",
  "Statement": [
    {
      "Sid": "PublicReadAccesForWebsite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": ["arn:aws:s3:::${var.chat_domain}/*" ]
    }
  ]
}
POLICY
  # Marking it use for "Static Website hosting"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  key = "index.html"
  content_type = "text/html"
  source = "index.html"
}

resource "aws_s3_bucket_object" "error_html" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  key = "error.html"
  content_type = "text/html"
  source = "error.html"
}

resource "aws_s3_bucket_object" "upload_web_app" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "**")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "text/html"
}

output "web_app_resources_uploaded" {
  value = fileset("${path.module}/web-app", "**")
}

# --- end setting up S3 bucket resources. -------

# --- start lamdba policy/role for  -------
resource "aws_iam_policy" "s3_policy" {
  name = "lets-chat-s3-access"
  description = "lets-chat-s3-access"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.chat_bucket.bucket}/*" ]
    }
  ]
}
EOF
}
#####
resource "aws_iam_role" "lambda_role" {
  name = "lets-chat-lambda-data"

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

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_s3" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_basicExecutionRole" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda/index.js"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "lambda_read_s3" {
  function_name = "lets-chat-API"
  filename = "lambda_function.zip"
  handler = "index.handler"
  role = aws_iam_role.lambda_role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/index.js")
}


# --- end lamdba policy/role for  -------

# --- start API gatewar ---------------

# https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html

resource "aws_api_gateway_rest_api" "api" {
  name = "letsChatAPI"
  description = "Lets Chat Lambda API"
  # Valid values: EDGE, REGIONAL or PRIVATE
  endpoint_configuration {
    types = [
      "EDGE"]
  }
}
resource "aws_api_gateway_resource" "resource" {
  path_part = "resource"
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}
# --- Mock Integration for CORS

resource "aws_api_gateway_method" "options_method" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [
    "aws_api_gateway_method.options_method"]
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
  depends_on = [
    "aws_api_gateway_method.options_method"]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [
    "aws_api_gateway_method_response.options_200"]
}

# --- lambda integration -------------

#https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
resource "aws_api_gateway_method" "method" {
  # http_method - (Required) The HTTP Method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  depends_on = [
    "aws_api_gateway_method.method"]
}


resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  # ANY won't work for integration_http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  # Lambda proxy integration
  uri = aws_lambda_function.lambda_read_s3.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_read_s3.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

# dploy lambda funciton

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "Dev"
  depends_on    = ["aws_api_gateway_integration.integration"]
}

#