---
title: "Deploy Lambda function for Hook"
weight: 510
---

### Deploy Lambda Function
TODO: add intro text
TODO: Add intructions how to access lambda code
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
4. **Click on Creat function**

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

2. Click on the **Depoly** button.
   ![lambda-deploy.png](/static/advanced/hook/lambda-deploy.png "lambda-deploy")
3. The function is now live and ready to be tested.

#### Step 4: Review Lambda Function

Before we dive into  testing the lambda function let's review what this lambda function is doing.

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

Now, lets review how Lambda function needs to respond back to communicate request sucess or failure.

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

#### **Step 5: Optional: Mock Test Lambda Function**

If you are wondering that how will we test the Lambda function? create sample payload for testing.

Create Test Event Create a new test event in the Lambda console with this sample payload:

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

Create a test event just like this one below with the above JSON text:
![lambda-test.png](/static/advanced/hook/lambda-test.png "lambda-test")

Click on the test button to test this hook, you will see the lambda return something similar to this:

   ```JSON
   {
   "hookStatus": "SUCCESS",
   "message": "DynamoDB configuration validation successful",
   "clientRequestToken": "test-token-123"
   }
   ```

Update the test event with `ReadCapacityUnits` value to more than 20, `PointInTimeRecoveryEnabled` value to `False`  and test again. In this case, lambda fucntion validation fails for multiple checks and lambda fucntion response will be similar to this:
   ```JSON
   {
   "hookStatus": "FAILED",
   "errorCode": "NonCompliant",
   "message": "DynamoDB configuration validation failed: ReadCapacityUnits and WriteCapacityUnits must not exceed 20., PointInTimeRecoverySpecification must be enabled.",
   "clientRequestToken": "test-token-123"
   }
   ```
Now lambda fucntion has deployed and validated, lets focus on using this lambda function to confgiure lambda hook.
