---
title: "Prepare to create a Lambda Hook"
weight: 510
---

### **Introduction**

To implement a **Lambda Hook** for validating **DynamoDB configurations**, we need to complete the following steps:

1. **Retrieve the Lambda Function ARN** – This ARN is required to configure the Hook Execution Role.
2. **Deploy the CloudFormation Hook Execution Role** – This role allows CloudFormation Hooks to assume permissions for invoking Lambda and reading DynamoDB configurations.
3. **Register the Hook in AWS CloudFormation** – The Hook will be configured to evaluate DynamoDB resource changes before provisioning.
4. **Attach Hook to a CloudFormation Stack** – This ensures enforcement during stack deployments.

---

### **Step 1: Retrieve Lambda Function ARN**

Since the Lambda function **DynamoDBConfigValidationHook** has already been deployed, follow these steps to find its **ARN**:

1. **Go to the AWS Lambda Console**:

   - Open [AWS Lambda Console](https://console.aws.amazon.com/lambda).
   - Search for **DynamoDBConfigValidationHook**.
   - Click on the function name.

2. **Copy the ARN**:
   - At the top-right of the **Lambda function details page**, find the **Function ARN**.
   - The ARN format will be:
     ```
     arn:aws:lambda:<region>:<account-id>:function:DynamoDBConfigValidationHook
     ```
   - Copy this ARN for use in the next step.

---

### **Step 2: CloudFormation Hook Role Access**

For the CloudFormation Hook to access **both DynamoDB and the Lambda function**, we must create a role that **CloudFormation Hooks** can assume.

#### ** Deploy the Hook Execution Role**

1. **Replace `<lambda arn>` with the copied ARN** in the following **hook-role.yaml** file:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "IAM roles for DynamoDB Configuration Hook"

Resources:
  HookExecutionRole:
    Type: "AWS::IAM::Role"
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: hooks.cloudformation.amazonaws.com
            Action: "sts:AssumeRole"
      ManagedPolicyArns:
        - "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      Policies:
        - PolicyName: DynamoDBHookPolicy
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - "dynamodb:DescribeTable"
                  - "dynamodb:ListTables"
                Resource: "*"
        - PolicyName: InvokeHookFunction
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - "lambda:InvokeFunction"
                Resource: "<lambda arn>" # Replace this with the actual Lambda ARN
```

#### ** Deploy the Hook Role via AWS Console**

1. **Open AWS CloudFormation Console**:

   - Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
   - Click **Create Stack** → **With new resources (standard)**.
   - Upload the modified `hook-role.yaml` file (with the correct Lambda function ARN).
     ![hook-role.png](/static/advanced/hook/hook-role.png "hook-role")

2. **Provide Stack Details**:

   - Enter a **stack name** (e.g., `HookExecutionRoleStack`).
   - Click **Next**.

3. **Configure Stack Settings**:

   - Leave the default values unless modifications are needed.
   - Click **Next**.

4. **Review and Create**:

   - Ensure the role settings are correct.
   - Click **Create Stack**.

5. **Wait for Deployment Completion**:
   - Navigate to the **Resources** tab.
   - Look for `HookExecutionRole` and **copy its Physical ID**.

---

### **Step 3: Using AWS Console to Create a Lambda Hook**

#### **Open AWS CloudFormation Hooks**

1. Open **AWS CloudFormation Console**.
2. Navigate to the **Hooks** section.
3. Click **Create Hook**.

#### **Configure Hook Settings**

1. **Hook Name** – `DynamoDBConfigValidationHook`
2. **Lambda Function ARN** – Enter the **ARN copied earlier**.
3. **Hook Targets** – Select **Resources**, which evaluates CloudFormation resource changes during a stack update.
4. **Hook Actions** – Select **Create, Update, and Delete** to ensure enforcement at all lifecycle stages.
5. **Hook Mode** – Set to **Fail**, stopping the provisioning operation when a validation check fails.
6. **Execution Role** – Choose **Existing Execution Role** and select the **HookExecutionRole** created earlier.

   ![hook-detail.png](/static/advanced/hook/hook-detail.png "hook-detail")

#### ** Review and Create Hook**

1. Click **Next**.
2. Review the settings.
3. Click **Create** to register the Hook.

---

### **Attaching the Hook to a CloudFormation Stack**

1. Open the **AWS CloudFormation Console**.
2. Select the **stack** to which the Hook should be applied.
3. Click **Update**.
4. Under **Hooks**, select `DynamoDBConfigValidationHook`.
5. Save and update the stack.
