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

#### STEP 4 - Routing lambda call from S3 to DynamoDB 
* Creating DynamoDB tables.
* Generate some sample data to play with.
* Give access to lambda role to communicate with DynamoDB.
* Necessary changes to .js and .html file to read/write conversations from DynamoDB.
* Detaching lambda from S3, as S3 is no more required to read conversations from.

#### STEP 5 - Breaking up the lambda function into modular function's doing there part.
 
 It does what /terraform-api-gateway-with-lmbda-proxy for resource creation
 * The difference it use's API Gateway Requet Flow with Schema Model for response.
 * Modular lambda function, per lambda function per operation
 * API gateway configured for each lambda function, and javascript function's for the same.
 * Using request and response model - to set schema that we accept.
 * Use velocity parameter read's path variable and generate param as needed.
 ```javascript
     passthrough_behavior = "WHEN_NO_TEMPLATES"
     request_templates = {
       "application/json" :  "#set($inputRoot = $input.path('$'))    {    \"id\": \"$input.params('id')\",    \"message\": \"$inputRoot\"  }"
     }
```

* Deploying the same, It does give some exception because terraform was not able to deploy that in the right sequence, had to give depends_on = [] tag to control that behaviour.

* Downloading api gateway SDK from  STAGE -> generator generator- and will use that in our script's
* ##### Preparing for cognito , removing hardcorded value fo 'Student' from .js files and updating the reuquest_templates for the same. 
* 
  "application/json" : <<EOF
{
  "cognitoUsername":"Student"
}
EOF

request_templates = {
    #    "application/json" :  "#set($inputRoot = $input.path('$'))    {    \"id\": \"$input.params('id')\",    \"message\": \"$inputRoot\"  }"
    "application/json" :  <<EOF
  #set($inputRoot = $input.path('$'))
  {
      "id": "$input.params('id')",
      "message": "$inputRoot",
      "cognitoUsername": "Student"
  }
EOF
  }
  
  * creating cognito user pool
    * Lmabda function for the same read user's
    * Attaching cognito read policy to lambda  
    * API gateway configuration for the same
  * Another lambda function to post conversation to DynamoDB
    * API gateway configuration for the same.
   
  * npm install --save amazon-cognito-identity-js
    * copy node_modules\amazon-cognito-identity-js\dist\amazon-cognito-identity.min.js to our /js/ folder
  
  * Update Config.js with 
  ```javascript
var poolData = {
    UserPoolId: 'us-east-1_f5W2BETw2',
    ClientId: '4nffgdp2be4ansrgrkd5qnflht'
};
```
* create a cognito authorizer for API.
* updated all the API Gateway's to use Cognito authentication.
   
   
Note: Though everything has been changed updated in repository, for keeping a tab.
* Update Config.js with 
    ```javascript
  var poolData = {
      UserPoolId: 'us-east-1_f5W2BETw2',
      ClientId: '4nffgdp2be4ansrgrkd5qnflht'
  };
  ```
* npm install --save amazon-cognito-identity-js
    * copy node_modules\amazon-cognito-identity-js\dist\amazon-cognito-identity.min.js to our /js/ folder
* Chat-Conversation-POST. //  const uuidV4 = require('uuid/v4'); // doesnot work's.
    * isntead use context.awsRequestId; // it's unique.
* Chat-Users-GET.js // update UserPoolId: 'us-east-1_Se3DtD5Ze',
* Downloading api gateway SDK from  STAGE -> generator generator- and will use that in our script's. In site.js now can use use apiGateWayClient instead of using gateway endpoint.
  * Put in the apiGateway-js-sdk in /js/ folder.
  * apiGateway-js-sdk/appClient.js -- replace parseParametersToObject(params, [])) with parseParametersToObject(params, ["id"]))
  * apiGateway-js-sdk/readme.md - the include .js files need to be included in .HTML * chats.html, chat.html