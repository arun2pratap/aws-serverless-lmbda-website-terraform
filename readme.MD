# AWS Building Serverless Chat Web app.

### NOTE
 * replace var bucket = 'lets-chat-neo'
 * replace /js/config.js with API Gateway api address - ChatApp.apiEndpoint = 'https://wh4ts4x4sf.execute-api.us-east-1.amazonaws.com/Dev'; 

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
* The difficult part making API CORS enable.
    that was little difficult for me to implement, setting proxy , producers, consumers, cors enable.
* LAMBDA proxy enabled
* Deploying the API
* updated lambda function to read from "pathParameter" i.e event.pathParameters.proxy