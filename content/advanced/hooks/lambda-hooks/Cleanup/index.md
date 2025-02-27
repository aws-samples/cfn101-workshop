---
title: "Cleanup"
weight: 550
---

### Introduction

### Clean Up Resources

After testing is completed, please delete the resources we created during this Lab.
#### Using AWS CLI
Run the following commands to delete the test CloudFormation stacks:
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name ddb-noncompliant-stack --region us-east-1
:::

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name ddb-compliant-stack --region us-east-1
:::
#### Disable The Lambda Hook
To disable a Hook in your account
1. Sign in to the AWS Management Console and open the AWS [CloudFormation console](https://console.aws.amazon.com/cloudformation).

2. On the navigation bar at the top of the screen, choose the AWS Region where the Hook is located.

3. From the navigation pane, choose **Hooks**.

4. Choose the name of the Hook you want to **disable**.

5. On the Hook details page, to the right of the Hook's name, choose the Disable button.

6. When prompted for confirmation, choose **Disable Hook**.

#### Remove the Lambda Function

To remove the lambda function using the AWS Console:

1. Open the [AWS Lambda Console](https://console.aws.amazon.com/lambda).
2. Find `DynamoDBConfigValidationHook` and click on the function.
3. Click **Delete** from the **Actions** drop-down menu.

**Remove Hook Execution Role**

Please use the stackname provided in [Prepare to create a Lambda Hook](../prepare-lambda-hook/#deploy-the-hook-execution-role)  Section
```
aws cloudformation delete-stack --stack-name HookExecutionRoleStack --region us-east-1
```
Verify that the **Lambda function, IAM roles(deployed using hook-role.yaml file)** are deleted if they are no longer needed.

Almost done! Choose **Next** to continue!
