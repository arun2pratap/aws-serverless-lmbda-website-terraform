# AWS Building Serverless Chat Web app.

#### STEP 1 - Creating S3 bucket resource.

* Creating S3 bucket resource.
* Setting up policies.
* Uploading static content as S3 bucket object's.    
* Using fileset to upload multiple files recursively.

#### STEP 2 - Creating lambda function

* Creating S3 policy for attaching to lambda role.
* Create role for lambda.
* Attach required policy for lambda role.
* Create lambda function - define a basic javascript lambda function using nodejs to read saved conversation from S3 bucket. - Do test it if it's working replace the bucket name with your own bucket in index.js.
    
#### STEP 3 - Creating Amazon API Gateway  for lambda that we created.

* Creating API gateway rest api "aws_api_gateway_rest_api"
* Creating aws_api_gateway_resource
* Creating aws_api_gateway_method
* Creating aws_api_gateway_integration
* Creating aws_lambda_permission
