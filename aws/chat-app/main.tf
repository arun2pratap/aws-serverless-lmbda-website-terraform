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

resource "aws_s3_bucket_object" "upload_web_app_html" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "**.html")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "upload_web_app_css" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "*/*.css")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "upload_web_app_js" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "*/*.js")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "application/javascript"
}

resource "aws_s3_bucket_object" "upload_web_app_json" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "**/*.json")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "application/json"
}


resource "aws_s3_bucket_object" "upload_web_app_fonts" {
  bucket = aws_s3_bucket.chat_bucket.bucket
  for_each = fileset("${path.module}/web-app", "fonts/*")
  key = each.value
  source = "${path.module}/web-app/${each.value}"
  # tracks the versoning identify any changes in file's for upload
  etag = filemd5("${path.module}/web-app/${each.value}")
  content_type = "image/svg+xml"
}

## --- end s3 bucket ---------------

# ------ start DynamoDB ------------

resource "aws_dynamodb_table" "chat-conv" {
  name = "Chat-Conversations"
  read_capacity = 1
  write_capacity = 1
  hash_key = "ConversationId"
  range_key = "Username"

  attribute {
    name = "ConversationId"
    type = "S"
  }
  attribute {
    name = "Username"
    type = "S"
  }
  global_secondary_index {
    name = "Username-ConversationId-index"
    projection_type = "ALL"
    hash_key = "Username"
    range_key = "ConversationId"
    write_capacity = 1
    read_capacity = 1
  }
}

resource "aws_dynamodb_table" "chat-messages" {
  name = "Chat-Messages"
  read_capacity = 1
  write_capacity = 1
  hash_key = "ConversationId"
  range_key = "Timestamp"

  attribute {
    name = "ConversationId"
    type = "S"
  }
  attribute {
    name = "Timestamp"
    type = "N"
  }
}
# add some sample data
/*
resource "aws_dynamodb_table_item" "chat-messages_01" {
  table_name = aws_dynamodb_table.chat-messages.name
  hash_key = aws_dynamodb_table.chat-messages.hash_key
  range_key = aws_dynamodb_table.chat-messages.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-messages.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-messages.range_key}": {"N": "1589307976345"},
  "Sender": {"S": "arun"},
  "Message": {"S": "Hello World! again"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-messages_02" {
  table_name = aws_dynamodb_table.chat-messages.name
  hash_key = aws_dynamodb_table.chat-messages.hash_key
  range_key = aws_dynamodb_table.chat-messages.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-messages.hash_key}": {"S": "2"},"${aws_dynamodb_table.chat-messages.range_key}": {"N": "1589307996345"},
  "Sender": {"S": "neo"},
  "Message": {"S": "Its beautiful world"}
}
ITEM
}


resource "aws_dynamodb_table_item" "chat-conv_01" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
"${aws_dynamodb_table.chat-conv.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "arun"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-conv_01_01" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
"${aws_dynamodb_table.chat-conv.hash_key}": {"S": "1"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "Student"}
}
ITEM
}

resource "aws_dynamodb_table_item" "chat-conv_02" {
  table_name = aws_dynamodb_table.chat-conv.name
  hash_key = aws_dynamodb_table.chat-conv.hash_key
  range_key = aws_dynamodb_table.chat-conv.range_key

  item = <<ITEM
{
  "${aws_dynamodb_table.chat-conv.hash_key}": {"S": "2"},"${aws_dynamodb_table.chat-conv.range_key}": {"S": "neo"}
}
ITEM
}
*/
# ------ end DynamoDB ------------


#####CREATE COGNITO USER#######

# cognito user_pool

resource "aws_cognito_user_pool" "pool" {
  name = "chatPool"

  admin_create_user_config {
    allow_admin_create_user_only = false
    //    invite_message_template {
    //      email_message = "Your username is {username} and temporary password is {####}. "
    //      email_subject = "Your temporary password"
    //    }
  }
  alias_attributes = [
    "email"]
  auto_verified_attributes = [
    "email"]
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  email_verification_message = "Lets Chat App verification code is {####}. "
  email_verification_subject = "Lets Chat App Your verification code"
  mfa_configuration = "OFF"
  password_policy {
    minimum_length = 6
    require_lowercase = false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
    temporary_password_validity_days = 7
  }

}


resource "aws_cognito_user_pool_client" "client" {
  name = "website"
  user_pool_id = aws_cognito_user_pool.pool.id
  prevent_user_existence_errors = "ENABLED"
  read_attributes = [
    "email",
    "email_verified"]
  write_attributes = [
    "email"]
  generate_secret = false
}

############ Cognito authorizer
resource "aws_api_gateway_authorizer" "authorizer" {
  name = "Cognito"
  type = "COGNITO_USER_POOLS"
  rest_api_id = aws_api_gateway_rest_api.api.id
  provider_arns = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"

}
############ Cognito authorizer

########## end Create Congntio user
resource "aws_iam_role" "role" {
  name = "lets-caht-lambda-role"

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

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_basicExecutionRole" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_attach_policy_cognito_readOnly" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoReadOnly"
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy_dynamoDB" {
  role = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
# lambda function conversation get
data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "lambda/conversation_get.js"
  output_path = "lambda_function_conversation_get.zip"
}

resource "aws_lambda_function" "lambda_conversation_get" {
  function_name = "Chat-Conversation-Get"
  filename = "lambda_function_conversation_get.zip"
  handler = "conversation_get.handler"
  role = aws_iam_role.role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/conversation_get.js")
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_conversation_get.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}
# lambda function message GET

data "archive_file" "lambda_zip_message_get" {
  type = "zip"
  source_file = "lambda/messages-get.js"
  output_path = "lambda_function_messages-get.zip"
}

resource "aws_lambda_function" "lambda_message_get" {
  function_name = "Chat-Messages-GET"
  filename = "lambda_function_messages-get.zip"
  handler = "messages-get.handler"
  role = aws_iam_role.role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/messages-get.js")
}
resource "aws_lambda_permission" "apigw_lambda_message_get" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_message_get.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
# lambda function post

data "archive_file" "lambda_zip_message_post" {
  type = "zip"
  source_file = "lambda/messages-post.js"
  output_path = "lambda_function_messages-post.zip"
}

resource "aws_lambda_function" "lambda_message_post" {
  function_name = "Chat-Messages-POST"
  filename = "lambda_function_messages-post.zip"
  handler = "messages-post.handler"
  role = aws_iam_role.role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/messages-post.js")
}

resource "aws_lambda_permission" "apigw_lambda_message_post" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_message_post.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
# lambda function get cognito user list
data "archive_file" "lambda_cognito_zip" {
  type = "zip"
  source_file = "lambda/Chat-Users-Get.js"
  output_path = "lambda_function_users_get.zip"
}

resource "aws_lambda_function" "lambda_users_get" {
  function_name = "Chat-Users-Get"
  filename = "lambda_function_users_get.zip"
  handler = "Chat-Users-Get.handler"
  role = aws_iam_role.role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/Chat-Users-Get.js")
}
resource "aws_lambda_permission" "apigw_lambda_cognito_post" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_users_get.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
##############

# lambda function post cognito user list to dynamodb
data "archive_file" "lambda_conv_post_zip" {
  type = "zip"
  source_file = "lambda/Chat-Conversation-POST.js"
  output_path = "lambda_function_converstaion_post.zip"
}

resource "aws_lambda_function" "lambda_conversation_post" {
  function_name = "Chat-Conversation-POST"
  filename = "lambda_function_converstaion_post.zip"
  handler = "Chat-Conversation-POST.handler"
  role = aws_iam_role.role.arn
  runtime = "nodejs12.x"
  source_code_hash = filebase64sha256("lambda/Chat-Conversation-POST.js")
}

resource "aws_lambda_permission" "apigw_lambda_conv_post" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_conversation_post.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
# --- end lamdba policy/role for  -------

# --- start API gateway ---------------

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
  path_part = "conversations"
  # To define it's a proxy resource
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# --- lambda integration -------------

#https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
resource "aws_api_gateway_method" "method" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  # ANY won't work for integration_http_method
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" : <<EOF
#set($inputRoot = $input.path('$'))
{
    "cognitoUsername": "$context.authorizer.claims['cognito:username']"
}
EOF
  }
  type = "AWS"
  uri = aws_lambda_function.lambda_conversation_get.invoke_arn
}

resource "aws_api_gateway_method_response" "response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.conversationList.name
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
# end of converstaions GET
# start for conversations POST

resource "aws_api_gateway_method" "method_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  request_models = {
    "application/json" : aws_api_gateway_model.newConversation.name
  }
}
resource "aws_api_gateway_integration" "integration_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_post.http_method
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  # velocity parameter read's path variable and generate param as needed.
  request_templates = {
    "application/json": <<EOF
#set($inputRoot = $input.path('$'))
{
"cognitoUsername": "$context.authorizer.claims['cognito:username']",
"users":
[
#foreach($elem in $inputRoot)
 "$elem"
#if($foreach.hasNext),#end
#end
]
}
  EOF
  }
  # velocity parameter read's path variable and generate param as needed.
  type = "AWS"
  uri = aws_lambda_function.lambda_conversation_post.invoke_arn
}

resource "aws_api_gateway_method_response" "response_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_post.http_method
  status_code = 204
  response_models = {
    "application/json" = aws_api_gateway_model.conversationId.name
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_response_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_post.http_method
  status_code = aws_api_gateway_method_response.response_post.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

#end for conversations POST
# create another child resource

resource "aws_api_gateway_resource" "resource_conv" {
  path_part = "{id}"
  parent_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# Get API Gateway flow

resource "aws_api_gateway_method" "method_conv_GET" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
}

resource "aws_api_gateway_integration" "integration_conv_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_GET.http_method
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  # velocity parameter read's path variable and generate param as needed.
  request_templates = {
    "application/json": <<EOF
#set($inputRoot = $input.path('$'))
{
    "cognitoUsername": "$context.authorizer.claims['cognito:username']",
    "id": "$input.params('id')"
}
  EOF
  }

  type = "AWS"
  uri = aws_lambda_function.lambda_message_get.invoke_arn
}

resource "aws_api_gateway_method_response" "response_conv_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_GET.http_method
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.conversations.name
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_res_conv_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_GET.http_method
  status_code = aws_api_gateway_method_response.response_conv_get.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
### MESSAGE post API gateway flow

resource "aws_api_gateway_method" "method_conv_POST" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  request_models = {
    "application/json" : aws_api_gateway_model.newMessage.name
  }
}
resource "aws_api_gateway_integration" "integration_conv_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_POST.http_method
  integration_http_method = "POST"
  # velocity parameter read's path variable and generate param as needed.
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" :  <<EOF
 #set($inputRoot = $input.path('$'))
{
    "cognitoUsername": "$context.authorizer.claims['cognito:username']",
    "id": "$input.params('id')",
    "message": "$inputRoot"
}
EOF
  }
  type = "AWS"
  uri = aws_lambda_function.lambda_message_post.invoke_arn
}

resource "aws_api_gateway_method_response" "response_conv_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_POST.http_method
  status_code = 204
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_res_conv_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_POST.http_method
  status_code = aws_api_gateway_method_response.response_post.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
######### cognito API gateway configuration's #####

resource "aws_api_gateway_resource" "resource_users" {
  path_part = "users"
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method_users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
}

resource "aws_api_gateway_integration" "integration_users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users.http_method
  # ANY won't work for integration_http_method
  integration_http_method = "POST"
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  request_templates = {
    "application/json" :  <<EOF
 #set($inputRoot = $input.path('$'))
#set($inputRoot = $input.path('$'))
{
    "cognitoUsername": "$context.authorizer.claims['cognito:username']"
}
EOF
  }
  type = "AWS"
  uri = aws_lambda_function.lambda_users_get.invoke_arn
}

resource "aws_api_gateway_method_response" "response_users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users.http_method
  status_code = "200"
  response_models = {
    "application/json" = aws_api_gateway_model.userList.name
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_response_users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users.http_method
  status_code = aws_api_gateway_method_response.response_users.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

#################

# --- Mock Integration for Enable CORS for resource /converstations

resource "aws_api_gateway_method" "method_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "response_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_res_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method_cors.http_method
  status_code = aws_api_gateway_method_response.response_cors.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
############

# --- Mock Integration for Enable CORS for resource_conv /converstations/{id}

resource "aws_api_gateway_method" "method_conv_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_conv_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_cors.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "response_conv_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_cors.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_res_conv_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_conv.id
  http_method = aws_api_gateway_method.method_conv_cors.http_method
  status_code = aws_api_gateway_method_response.response_conv_cors.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
############


# --- Mock Integration for Enable CORS for resource /users

resource "aws_api_gateway_method" "method_users_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_users_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users_cors.http_method
  type = "MOCK"
  request_templates = {
    "application/json": "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "response_users_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users_cors.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_users_res_cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_users.id
  http_method = aws_api_gateway_method.method_users_cors.http_method
  status_code = aws_api_gateway_method_response.response_users_cors.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}
##########
# dploy lambda funciton
# aws_api_gateway_deployment is flaky try commenting/un-commenting depends_on it works, yup silly but it works, terraform mess up the sequence of resource.
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_resource.resource,
    aws_api_gateway_resource.resource_users,
    aws_api_gateway_resource.resource_conv,

    aws_api_gateway_method.method,
    aws_api_gateway_method.method_post,
    aws_api_gateway_method.method_conv_GET,
    aws_api_gateway_method.method_conv_POST,
    aws_api_gateway_method.method_users,
    aws_api_gateway_method.method_cors,
    aws_api_gateway_method.method_conv_cors,
    aws_api_gateway_method.method_users_cors,

    aws_api_gateway_method_response.response,
    aws_api_gateway_method_response.response_post,
    aws_api_gateway_method_response.response_cors,
    aws_api_gateway_method_response.response_conv_cors,
    aws_api_gateway_method_response.response_conv_get,
    aws_api_gateway_method_response.response_conv_post,
    aws_api_gateway_method_response.response_users,
    aws_api_gateway_method_response.response_users_cors,

    aws_api_gateway_integration.integration,
    aws_api_gateway_integration.integration_post,
    aws_api_gateway_integration.integration_users,
    aws_api_gateway_integration.integration_conv_get,
    aws_api_gateway_integration.integration_conv_post,
    aws_api_gateway_integration.integration_cors,
    aws_api_gateway_integration.integration_conv_cors,
    aws_api_gateway_integration.integration_users_cors,


    aws_api_gateway_integration_response.integration_response,
    aws_api_gateway_integration_response.integration_response_post,
    aws_api_gateway_integration_response.integration_response_users,
    aws_api_gateway_integration_response.integration_res_conv_get,
    aws_api_gateway_integration_response.integration_res_conv_post,
    aws_api_gateway_integration_response.integration_res_cors,
    aws_api_gateway_integration_response.integration_res_conv_cors,
    aws_api_gateway_integration_response.integration_users_res_cors
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "Dev"
  lifecycle {
    create_before_destroy = true
  }
}
#########################  model models

resource "aws_api_gateway_model" "conversationList" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "ConverstationList"
  description = "a JSON schema"
  content_type = "application/json"

  schema = <<EOF
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "participants": {
        "type": "array",
        "items": {
          "type": "string"
        }
      },
      "last": {
        "type": "number",
        "format": "utc-millisec"
      }
    }
  }
}
EOF
}

resource "aws_api_gateway_model" "newConversation" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "newConversation"
  description = "a JSON schema"
  content_type = "application/json"

  schema = <<EOF
{
  "type": "array",
  "items": {
    "type": "string"
  }
}
EOF
}
resource "aws_api_gateway_model" "conversationId" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "conversationId"
  description = "a JSON schema"
  content_type = "application/json"
  schema = <<EOF
{"type":"string"}
EOF
}

resource "aws_api_gateway_model" "conversations" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "Converstation"
  description = "a JSON schema"
  content_type = "application/json"
  schema = <<EOF
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string"
    },
    "participants": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "last": {
      "type": "number",
      "format": "utc-millisec"
    },
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "sender": {
            "type": "string"
          },
          "time": {
            "type": "number",
            "format": "utc-millisec"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
EOF
}

resource "aws_api_gateway_model" "newMessage" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "NewMessage"
  description = "a JSON schema"
  content_type = "application/json"
  schema = <<EOF
{
  "type": "string"
}
EOF
}

resource "aws_api_gateway_model" "userList" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  name = "usersList"
  description = "a JSON schema"
  content_type = "application/json"
  schema = <<EOF
{
  "type":"array",
  "items": {
    "type":"string"
  }
}
EOF
}

########################