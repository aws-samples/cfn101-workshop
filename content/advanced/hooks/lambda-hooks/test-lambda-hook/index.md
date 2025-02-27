---
title: "Test Lambda Hook"
weight: 540
---

### **Introduction**

Now that we have deployed the **DynamoDBConfigValidationHook**, we need to test it to ensure it correctly validates DynamoDB configurations before CloudFormation provisions resources.

We will test the hook with two diffrent CloudFormation stacks.

1. **A non-compliant DynamoDB table** that violates the validation rules and fails the CloudFormation Stack deployment.
2. **A compliant DynamoDB table** that meets all validation criteria which results into sucessful deployment of CloudFormation stack.

---

::alert[To get started, ensure that you are in `cfn101-workshop/code/workspace/hooks/lambda_hook`directory.]{type="info"}

#### **Scenario 1: Non-Compliant DynamoDB Table (Validation Failure)**

Locate and open the `noncompliant-ddb.yaml` file.
The CloudFormation template in this file **violates several validation rules** that the Lambda Hook is currently validating.

```
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  NonCompliantDynamoDB:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: NonCompliantTable
      AttributeDefinitions:
        - AttributeName: "Id"
          AttributeType: "S"
      KeySchema:
        - AttributeName: "Id"
          KeyType: "HASH"
      ProvisionedThroughput:
        ReadCapacityUnits: 25  # Exceeds allowed limit
        WriteCapacityUnits: 10
      GlobalSecondaryIndexes: []
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: false  # Must be enabled
      BillingMode: "PROVISIONED"  # Must be PAY_PER_REQUEST
```

Next, from the directory where the file above is, use the AWS CLI to create a stack, in the us-east-1 region, with that template:

:::code{language=shell showLineNumbers=false showCopyAction=true}

aws cloudformation create-stack \
    --stack-name ddb-noncompliant-stack \
    --template-body file://noncompliant-ddb.yaml \
    --region us-east-1
:::

The cloudformation `create-stack` command will return an output in JSON format like this:

```JSON
{
    "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxx:stack/ddb-noncompliant-stack/b2xxxxxxx-fxx-11xxf-9xx4-xxxxxxxxxxx7"
}
```

Then let's wait for the deployment of the stack to be completed by the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name ddb-noncompliant-stack \
    --region us-east-1
:::

Use the following command to wait for stack creation completion:

In this case, since stack contains DynamoDB defination which is non compliant as per validation logic in the Lambda Hook, the stack will fail to create as hook return an error. The previous `wait` command returns back to the shell with a `StackCreateComplete` failed error lie the following:

```
Waiter StackCreateComplete failed: Waiter encountered a terminal failure state: For expression "Stacks[].StackStatus" we matched expected path: "ROLLBACK_COMPLETE" at least once
```

**Understand CloudFormation Stack Failure**

In order to understand the detailed reason for stack failure in the AWS Console, follow the steps below.

- Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
- Locate the latest deployment for `ddb-noncompliant-stack` Stack.
- Navigate to the Events section.
- Locate the `DynamoDBConfigValidationHook` under the Hook invocations section. This entry will contain details about the status of Hook as _Fail_ and Hook Status Reason with a detailed error message as provided by the Lambda Function.

**CloudFormation Stack Failure Output**
![noncompliant-stack.png](/static/advanced/hook/hook-test-noncompliant-stack.png "Non-Compliant Stack Creation Failure")

**Hook Invocation Error Details**
Here is an example of the `HOOK_COMPLETE_FAILED` status:

![noncompliant-logs.png](/static/advanced/hook/hook-test-noncompliant-stack-log.png "CloudFormation Hook Validation Failure Logs")

---

### **Scenario 2: Compliant DynamoDB Table**

Locate and open the `compliant-ddb.yaml` file.
The CloudFormation template in this file **meets all the required compliance checks** that the Lambda Hook is currently validating.

```
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  CompliantDynamoDB:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: CompliantTable  # Ensuring a table name is set
      AttributeDefinitions:
        - AttributeName: "Id"
          AttributeType: "S"  # Defining the primary key attribute type as String
      KeySchema:
        - AttributeName: "Id"
          KeyType: "HASH"  # Using a HASH key as the partition key
      BillingMode: "PAY_PER_REQUEST"  # Compliance: Must be PAY_PER_REQUEST
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true  # Compliance: Point-in-time recovery must be enabled
      GlobalSecondaryIndexes:
        - IndexName: "GSI1"
          KeySchema:
            - AttributeName: "Id"
              KeyType: "HASH"
          Projection:
            ProjectionType: "ALL"  # Compliance: At least one Global Secondary Index (GSI) must be defined

```

Next, from the directory where the file above is, use the AWS CLI to create a stack, in the us-east-1 region, with that template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name ddb-compliant-stack \
    --template-body file://compliant-ddb.yaml \
    --region us-east-1
:::

Next, just like for the non-compliant stack deployment, wait for the stack creation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name ddb-compliant-stack \
    --region us-east-1
:::

Unlike the non-compliant stack, this command will not output any message upon successful completion. To confirm that the stack was created successfully, navigate to the **AWS CloudFormation Console** and review the results.

**Review CloudFormation Stack Creation**
You can review stack and Hook execution status in the AWS Console, by following the steps below.

- Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
- Locate the latest deployment for `ddb-compliant-stack` Stack.
  - If the status is `CREATE_COMPLETE`, it means the DynamoDB table configuration met all compliance checks enforced by the Lambda Hook, and the stack deployment was successful.
  - If not check the Events output for errors.
- Navigate to the Events section.
- Locate the `DynamoDBConfigValidationHook` under the Hook invocations section. This entry will contain details about the status of Hook \* and Hook Status Reason with a sucessfull execution message as provided by the Lambda Function.

1. **CloudFormation Stack Creation Output**
   ![compliant-stack.png](/static/advanced/hook/hook-test-compliant-stack.png "Compliant Stack Creation")

2. **Hook Invocation Details**
   ![compliant-hook-logs.png](/static/advanced/hook/hook-test-compliant-stack-log.png "Compliant Hook Logs")

---

### View Logs in CloudWatch

To analyze validation logs, follow these steps:

1. Open **Amazon CloudWatch Console**.
2. Navigate to **Log Groups**.
3. Locate **`/aws/lambda/DynamoDBConfigValidationHook`**.
4. Review log messages to confirm validation checks and errors:

- The following screenshot shows **an example log of the successful execution of our Lambda Hook**, confirming that the stack creation passed all validation checks:
  ![cloudwatch-hook-success.png](/static/advanced/hook/cloudwatch-hook-success.png "Compliant Hook Logs")

- In contrast, the screenshot below illustrates **an example log of a failed stack** creation due to non-compliance with the validation rules enforced by the Lambda Hook:
  ![cloudwatch-hook-fail.png](/static/advanced/hook/cloudwatch-hook-fail.png "non Compliant Hook Logs")

**Congratulations! You have successfully tested and validated your Lambda Hook for DynamoDB configurations.**
