---
title: "Test Lambda Hook"
weight: 540
---

<<<<<<< Updated upstream
### Introduction

Test Scenarios and instructions
=======
### **Introduction**

Now that we have deployed the **DynamoDBConfigValidationHook**, we need to test it to ensure it correctly validates DynamoDB configurations before CloudFormation provisions resources.

We will test the hook by creating two CloudFormation stacks:

1. **A compliant DynamoDB table** that meets all validation criteria.
2. **A non-compliant DynamoDB table** that violates the validation rules.

---

### **Test Scenario 1: Compliant DynamoDB Table**

#### **a. Test CloudFormation Template (Compliant Table)**

The following CloudFormation template defines a **DynamoDB table** that meets all the required compliance checks.

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
        PointInTimeRecoveryEnabled: true
      GlobalSecondaryIndexes:
        - IndexName: "GSI1"
          KeySchema:
            - AttributeName: "Id"
              KeyType: "HASH"
          Projection:
            ProjectionType: "ALL"
```

::alert[If you've cloned our repo then you can also find this **compliant-ddb.yaml** file in our _cfn101-workshop/code/workspace/hooks/_ folder.]{type="info"}

#### **b. Expected Result: Validation passes** as all checks are met.

##### **i. Screenshot(s)**

1. **CloudFormation Stack Creation Output**
   ![compliant-stack.png](/static/advanced/hook/hook-test-compliant-stack.png "Compliant Stack Creation")

2. **Hook Invocation Logs**
   ![compliant-hook-logs.png](/static/advanced/hook/hook-test-compliant-stack-log.png "Compliant Hook Logs")

---

### **Test Scenario 2: Non-Compliant DynamoDB Table (Validation Failure)**

#### **a. Test CloudFormation Template (Non-Compliant Table)**

The following CloudFormation template **violates multiple validation rules** to trigger the Lambda Hook.

::alert[If you've cloned our repo then you can also find this **noncompliant-ddb.yaml** file in our _cfn101-workshop/code/workspace/hooks/_ folder.]{type="info"}

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
      GlobalSecondaryIndexes: []  # No GSI defined
      PointInTimeRecoverySpecification:
        PointInTimeRecoveryEnabled: false  # Must be enabled
      BillingMode: "PROVISIONED"  # Must be PAY_PER_REQUEST
```

#### **b. Expected Result: Validation fails** due to multiple violations.

##### **i. Screenshot(s)**

1. **CloudFormation Stack Failure Output**
   ![noncompliant-stack.png](/static/advanced/hook/hook-test-noncompliant-stack.png "Non-Compliant Stack Creation Failure")

2. **Error Logs in CloudFormation**
   ![noncompliant-logs.png](/static/advanced/hook/hook-test-noncompliant-stack-log.png "CloudFormation Hook Validation Failure Logs")

---

### **Step 3: View Logs in CloudWatch**

To analyze validation logs, follow these steps:

1. Open **Amazon CloudWatch Console**.
2. Navigate to **Log Groups**.
3. Locate **`/aws/lambda/DynamoDBConfigValidationHook`**.
4. Review log messages to confirm validation checks and errors.

---

### **Step 4: Clean Up Resources**

After testing, you can delete the test resources using the AWS Console or CLI.

#### **a. Using AWS Console**

1. Open **AWS CloudFormation Console**.
2. Select the test stacks (`CompliantStack` and `NonCompliantStack`).
3. Click **Delete**.

#### **b. Using AWS CLI**

Run the following command to delete a specific stack:

```
aws cloudformation delete-stack --stack-name YourStackName
```

#### **c. Ensure Complete Cleanup**

- Verify that the **Lambda function, IAM roles, and log groups** are deleted if they are no longer needed.

---

**Congratulations! You have successfully tested and validated your Lambda Hook for DynamoDB configurations.**
>>>>>>> Stashed changes
