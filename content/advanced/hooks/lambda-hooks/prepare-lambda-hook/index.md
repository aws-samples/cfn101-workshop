---
title: "Prepare to create a Lambda Hook"
weight: 510
---

### **Introduction**

Queston : The user or role that creates the Hook must have sufficient permissions to activate Hooks??? update Workshop Studio persmission model contentspec.yaml.

Before you create a **Lambda Hook** for validating **DynamoDB configurations**, we need to complete the following steps to create an execution role with IAM permissions and a trust policy to allow CloudFormation to invoke a Lambda Hook.

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

To enable the **CloudFormation Hook** to validate **DynamoDB configurations** by invoking the Lambda function, we must create an IAM role that CloudFormation Hooks can assume. This role ensures that the hook has the necessary permissions to:

1. **Access DynamoDB**: The hook needs permission to check the table configurations, such as whether Point-In-Time Recovery is enabled.
2. **Invoke the Lambda Function**: The hook calls the Lambda function, which performs validation checks on the DynamoDB configuration.

By defining a dedicated **IAM role**, we ensure that CloudFormation Hooks can securely perform these operations without requiring excessive permissions across AWS services.

#### **Deploy the Hook Execution Role**

1. Copy the **Amazon Resource Name (ARN) of your Lambda function** from the AWS Management Console.
2. **Replace `<lambda arn>` with the copied ARN** in the following **hook-role.yaml** file:

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
        - PolicyName: InvokeHookFunction
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - "lambda:InvokeFunction"
                Resource: "<lambda arn>" # Replace this with the actual Lambda ARN
```

3.  Deploy the IAM role using AWS CloudFormation, which grants necessary permissions to the hook.

::alert[If you've cloned our repo then you can also find this yaml file in our _cfn101-workshop/code/workspace/hooks/hook-role.yaml_ folder.]{type="info"}

#### **3.Deploy the Hook Role via AWS Console**

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
   - Look for `HookExecutionRole` and **copy its Physical ID** for later use.

Now, all the preparation is done. The Lambda we created is now ready and we need to activate the Lambda hook.

Choose **Next** to continue!

---
