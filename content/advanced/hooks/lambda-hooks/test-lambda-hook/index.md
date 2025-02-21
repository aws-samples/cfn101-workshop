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

TODO jjlei: update noncompliant-ddb.yaml to sync with below cfn
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
```
aws cloudformation create-stack \
    --stack-name ddb-noncompliant-stack \
    --template-body file://noncompliant-ddb.yaml \
    --region us-east-1
```
Next, wait for the stack creation to complete:
```
aws cloudformation wait stack-create-complete \
    --stack-name ddb-noncompliant-stack \
    --region us-east-1
```
**TODO jjlei: Verify Below what is the output of wait command**

In this case, since stack contains DynamoDB defination which is non compliant as per validation logic in the Lambda Hook, the stack will fail to create as hook return an error. The previous `wait` command returns back to the shell with a `StackCreateComplete` failed error.

**Understand CloudFormation Stack Failure**

In order to understand the detailed reason for stack failure in the AWS Console, follow the steps below.
   - Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
   - Locate the latest deployment for `ddb-noncompliant-stack` Stack.
   - Navigate to the Events section.
   - Locate the `DynamoDBConfigValidationHook` under the Hook invocations section. This entry will contain details about the status of Hook as *Fail* and Hook Status Reason with a detailed error message as provided by the Lambda Function.

  **CloudFormation Stack Failure Output**
   ![noncompliant-stack.png](/static/advanced/hook/hook-test-noncompliant-stack.png "Non-Compliant Stack Creation Failure")

  **Hook Invocation Error Details**

   ![noncompliant-logs.png](/static/advanced/hook/hook-test-noncompliant-stack-log.png "CloudFormation Hook Validation Failure Logs")

---

### **Scenario 2: Compliant DynamoDB Table**
Locate and open the `compliant-ddb.yaml` file.
The CloudFormation template in this file **meets all the required compliance checks** that the Lambda Hook is currently validating.

**TODO: Update stack with comments for validation compliance**

```
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  CompliantDynamoDB:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: CompliantTable
      AttributeDefinitions:
        - AttributeName: "Id"
          AttributeType: "S"
      KeySchema:
        - AttributeName: "Id"
          KeyType: "HASH"
      BillingMode: "PAY_PER_REQUEST"
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: true # Point in time Recovery Enabled
      GlobalSecondaryIndexes:
        - IndexName: "GSI1"
          KeySchema:
            - AttributeName: "Id"
              KeyType: "HASH"
          Projection:
            ProjectionType: "ALL"
```
Next, from the directory where the file above is, use the AWS CLI to create a stack, in the us-east-1 region, with that template:
```
aws cloudformation create-stack \
    --stack-name ddb-compliant-stack \
    --template-body file://compliant-ddb.yaml \
    --region us-east-1
```
Next, wait for the stack creation to complete:
```
aws cloudformation wait stack-create-complete \
    --stack-name ddb-compliant-stack \
    --region us-east-1
```
**TODO jjlei: Verify Below what is the output of wait command**

The `ddb-compliant-stack` passes all the validation checks from Lambda Hook and stack is executed sucessfully and previous`wait` command returns back to shell with a `StackCreateComplete` status.

You can see that the bucket creation only started after the hook completed the validation of your bucket successfully

**Review CloudFormation Stack Creation**
You can review stack and Hook execution status in the AWS Console, by following the steps below.
   - Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
   - Locate the latest deployment for `ddb-compliant-stack` Stack.
   - Navigate to the Events section.
   - Locate the `DynamoDBConfigValidationHook` under the Hook invocations section. This entry will contain details about the status of Hook * and Hook Status Reason with a sucessfull execution message as provided by the Lambda Function.


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
4. Review log messages to confirm validation checks and errors.
---
**TODO jjlei: Add screenshots for CW Logs**

TODO: dessumi move this to cleanup section
### Clean Up Resources

After testing, you can delete the test resources.
#### Using AWS CLI**

Run the following command to delete a specific stack:
**TODO dessumi:add commands for each Stack deletion**
```
aws cloudformation delete-stack --stack-name YourStackName
```
#### Ensure Complete Cleanup**

- Verify that the **Lambda function, IAM roles, and log groups** are deleted if they are no longer needed.

**TODO dessumi:Add deregistring the Hook steps**
**TODO dessumi:add undeploy Lambds function steps**
---

**Congratulations! You have successfully tested and validated your Lambda Hook for DynamoDB configurations.**
