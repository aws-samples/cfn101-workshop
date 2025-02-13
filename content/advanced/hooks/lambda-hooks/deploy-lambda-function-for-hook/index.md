---
title: "Deploy Lambda function for Hook"
weight: 510
---

### Review Lambda Function

TODO: Instructions to navigate to the fucntion code

Now, let's do a quick overview of Lambda function implementation.
#### Request Input

#### Response
Now, lets review how Lambda function needs to respond back to communicate request sucess or failure.

TODO: Add Code snippet here

Based on whether the encryption is enabled for the DynamoDB table for the CloudFormation stack in the request, it `hookStatus` will have SUCCESS or FAILED. Also, in case of failed requests, appropriate `erroCode` details and `message` will be included for understanding the error.

#### Stack Resource Evaluation

### Deploy Lambda Function

Deployment Instructions

Test Lambda Function
