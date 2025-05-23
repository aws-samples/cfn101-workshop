---
title: "Deploy Lambda function for Hook"
weight: 510
---

### Deploy Lambda Function

To ensure that our AWS Lambda Hook is functional, we need to deploy the Lambda function that will validate the DynamoDB configurations. This function will check attributes such as read/write capacity and point-in-time recovery before a CloudFormation stack is created or updated.

This guide will walk you through deploying the Lambda function manually via the AWS Console.

Before deploying, ensure you have access to the Lambda function code, you could achieve that by the using following commands in your terminal:

```sh
# clone our repo if you have not already done so.
git clone https://github.com/aws-samples/cfn101-workshop.git

# Navigate to the directory where the Lambda function is stored
cd cfn101-workshop/code/workspace/hooks/lambda_hook
```

#### **Step 1: Open AWS Lambda Console**

1. Go to [AWS Lambda Console](https://console.aws.amazon.com/lambda).
2. Click on **Create function**.
3. Under **Choose a function type**, select **Author from scratch**.

#### **Step 2: Configure Function Settings**

1. **Function name**: Enter a name (e.g., `DynamoDBConfigValidationHook`).
2. **Runtime**: Select `Python 3.13`.
3. **Execution role**:
   - Choose **Create a new role with basic Lambda permissions** which is the default option for execution role.
     ![lambda-creation.png](/static/advanced/hook/lambda-creation.png "lambda-creation")
4. **Click on Create function**

#### **Step 3: Deploy the Lambda Code**

1. Paste in below lambda code:

```python
# Lambda function for evaluating DynamoDB table compliance

import json
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def validate_dynamodb_table(table_config):
    """
    Validate the DynamoDB table properties to enforce compliance.
    """
    validation_errors = []

    logger.info(f"Validating DynamoDB table properties: {json.dumps(table_config, indent=2)}")

    # Check Read and Write Capacity
    read_capacity = table_config.get('ProvisionedThroughput', {}).get('ReadCapacityUnits', 0)
    write_capacity = table_config.get('ProvisionedThroughput', {}).get('WriteCapacityUnits', 0)
    if read_capacity > 20 or write_capacity > 20:
        validation_errors.append("ReadCapacityUnits and WriteCapacityUnits must not exceed 20.")

    # Check Point-In-Time Recovery
    point_in_time_recovery = table_config.get('PointInTimeRecoverySpecification', {}).get('PointInTimeRecoveryEnabled', False)
    if not point_in_time_recovery:
        validation_errors.append("PointInTimeRecoverySpecification must be enabled.")

    return validation_errors

def lambda_handler(event, context):
    """
    Entry point for the Lambda function. Handles validation of DynamoDB configurations.
    """
    logger.info(f"Received event: {json.dumps(event, indent=2)}")

    try:
        # Validate if 'requestData' is present in the event
        if "requestData" not in event:
            logger.error("Error: Missing 'requestData' key in event payload.")
            return {
                'hookStatus': 'FAILED',
                'errorCode': 'InvalidRequest',
                'message': "Missing 'requestData' key in event payload.",
                'clientRequestToken': event.get('clientRequestToken', 'N/A')
            }

        request_data = event['requestData']
        logger.info(f"Processing Request Data: {json.dumps(request_data, indent=2)}")

        # Ensure 'targetType' and 'targetModel' are present
        if 'targetType' not in request_data or 'targetModel' not in request_data:
            logger.error("Error: Missing 'targetType' or 'targetModel' in requestData.")
            return {
                'hookStatus': 'FAILED',
                'errorCode': 'InvalidRequest',
                'message': "Missing 'targetType' or 'targetModel' in requestData.",
                'clientRequestToken': event.get('clientRequestToken', 'N/A')
            }

        # Process only DynamoDB table resources
        if request_data['targetType'] == 'AWS::DynamoDB::Table':
            table_properties = request_data['targetModel'].get('resourceProperties', {})
            validation_errors = validate_dynamodb_table(table_properties)

            if validation_errors:
                logger.warning(f"Validation failed: {', '.join(validation_errors)}")
                return {
                    'hookStatus': 'FAILED',
                    'errorCode': 'NonCompliant',
                    'message': f"DynamoDB configuration validation failed: {', '.join(validation_errors)}",
                    'clientRequestToken': event['clientRequestToken']
                }

            logger.info("DynamoDB configuration validation successful.")
            return {
                'hookStatus': 'SUCCESS',
                'message': 'DynamoDB configuration validation successful',
                'clientRequestToken': event['clientRequestToken']
            }

        else:
            logger.error(f"Error: Unsupported targetType {request_data['targetType']}.")
            return {
                'hookStatus': 'FAILED',
                'errorCode': 'InvalidResource',
                'message': f"Unsupported targetType {request_data['targetType']}.",
                'clientRequestToken': event['clientRequestToken']
            }

    except Exception as e:
        logger.exception("Unexpected error occurred.")
        return {
            'hookStatus': 'FAILED',
            'errorCode': 'InternalFailure',
            'message': f'Hook encountered an error: {str(e)}',
            'clientRequestToken': event.get('clientRequestToken', 'N/A')
        }

```

2. Click on the **Deploy** button.
   ![lambda-deploy.png](/static/advanced/hook/lambda-deploy.png "lambda-deploy")
3. The function is now live and ready to be tested.

#### Step 4: Review Lambda Function

Before we dive into testing the lambda function let's review what this lambda function is doing.

To navigate to the Lambda function code:

1. Open the **AWS Lambda Console**.
2. Locate the function deployed for the hook (e.g., `DynamoDBConfigValidationHook`).
3. Click on the function to view its implementation.

Now, let's do a quick overview of the Lambda function implementation. There are plenty comments in the lambda code explaining each line of the code, take a look at them if you have time.

##### Stack Resource Evaluation

The function evaluates below deployment configurations for Amazon DynamoDB:

- **Read and Write Capacity** (should not exceed 20).
- **Point-In-Time Recovery** (must be enabled).
- **Billing Mode** (must be PAY_PER_REQUEST).

##### Request Input

Here is an example input for the request:

```json
{
  "requestData": {
    "targetName": "AWS::DynamoDB::Table",
    "targetType": "AWS::DynamoDB::Table",
    "targetModel": {
      "resourceProperties": {
        "TableName": "ExampleTable",
        "BillingMode": "PAY_PER_REQUEST",
        "PointInTimeRecoverySpecification": {
          "PointInTimeRecoveryEnabled": true
        },
        "GlobalSecondaryIndexes": [
          {
            "IndexName": "ExampleGSI",
            "KeySchema": [{ "AttributeName": "Id", "KeyType": "HASH" }]
          }
        ],
        "ProvisionedThroughput": {
          "ReadCapacityUnits": 10,
          "WriteCapacityUnits": 10
        }
      }
    }
  },
  "clientRequestToken": "example-token"
}
```

##### Response

Now, lets review how Lambda function needs to respond back to communicate request success or failure.

##### Response Attributes Explanation

**hookStatus**: Represents the overall validation status. Possible values include:

- "SUCCESS": Indicates that the validation checks have passed.
- "FAILED": Indicates that the validation checks have failed.

**message**: Provides a human-readable explanation of the validation result.

- In a success response, it confirms that the configuration meets the required standards.
- In a failure response, it specifies the issue that caused the validation failure.

**clientRequestToken**: A unique identifier associated with the request, which helps track validation attempts.

**errorCode** (only in failure responses): Provides a specific error code related to the validation failure.

- "NonCompliant": Indicates that the DynamoDB configuration does not meet compliance requirements.
- "InvalidRequest": This means needed input from the hook event did not include attributes like `requestData,targetModel or targetType`

###### Example of a Successful Response

If the DynamoDB configuration has passed all validation checks, including Check Point-In-Time Recovery and Check Read and Write Capacity, the Lambda function returns the following response:

```json
{
  "hookStatus": "SUCCESS",
  "message": "DynamoDB configuration validation successful",
  "clientRequestToken": "example-token"
}
```

##### Example of a Failed Response

If the DynamoDB configuration does not have the Check Point-In-Time Recovery feature enabled, the validation will fail, and the Lambda function will return a response similar to this:

```json
{
  "hookStatus": "FAILED",
  "errorCode": "NonCompliant",
  "message": "Point-In-Time Recovery must be enabled.",
  "clientRequestToken": "example-token"
}
```

This response indicates that the configuration is non-compliant and requires corrective action to pass the validation checks.

#### **Step 5(Optional): Mock Test Lambda Function**

Before integrating the Lambda function with CloudFormation hooks, it's helpful to test it independently. This step allows you to simulate how the hook will utilize the Lambda function during actual CloudFormation deployments.

Let's create a test event to mock the hook's behavior:

1. Navigate to the Lambda console and select the function we've created earlier in step 3.
2. Click on the "Test" tab
3. Create a new test event with this sample payload:

```json
{
  "requestData": {
    "targetName": "AWS::DynamoDB::Table",
    "targetType": "AWS::DynamoDB::Table",
    "targetModel": {
      "resourceProperties": {
        "TableName": "TestTable",
        "PointInTimeRecoverySpecification": {
          "PointInTimeRecoveryEnabled": true
        },
        "ProvisionedThroughput": {
          "ReadCapacityUnits": 5,
          "WriteCapacityUnits": 5
        }
      }
    }
  },
  "clientRequestToken": "test-token-123"
}
```

##### To create a test event in the AWS Management Console, please follow these steps:

1. Go to the Lambda we've created earlier, click on the blue **Test** button to create a test event.
2. A dropdown will appear, click on the **Create a new test event**, then give the test event a name of your choice. (in the example below we've named it **_mytestevent_**)
3. Paste the above event JSON into the **Event JSON** box.
4. Save the test and then invoke it to test the lambda.

![lambda-test.png](/static/advanced/hook/lambda-test.png "lambda-test")

##### Test Scenario 1: Compliant Configuration

When you execute the test with the above payload, you should receive a successful response:
Click on the test button to test this hook, you will see the lambda return something similar to this:

```JSON
{
"hookStatus": "SUCCESS",
"message": "DynamoDB configuration validation successful",
"clientRequestToken": "test-token-123"
}
```

##### Test Scenario 2: Non-Compliant Configuration

Modify the test event with these changes:

- Update the test event with `ReadCapacityUnits` value to more than 20,
- `PointInTimeRecoveryEnabled` value to `False`
  and test again, with our non-compliant input, the Lambda function should return a failure response like below:

```JSON
{
"hookStatus": "FAILED",
"errorCode": "NonCompliant",
"message": "DynamoDB configuration validation failed: ReadCapacityUnits and WriteCapacityUnits must not exceed 20., PointInTimeRecoverySpecification must be enabled.",
"clientRequestToken": "test-token-123"
}
```

These test scenarios demonstrate how the Lambda function validates DynamoDB table configurations before actual deployment. This pre-deployment validation helps ensure that your DynamoDB tables meet the required security and operational standards.

Congrats on reaching this point! Now that we've verified the Lambda function works as expected, let's proceed to configuring the CloudFormation hook to use this Lambda function we've deployed.
