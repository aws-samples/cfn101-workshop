---
title: "Template and stack"
weight: 200
---

_Lab Duration: ~10 minutes_

---

### Overview
This lab will start with the most basic template containing only the `Resources` section, which contains a single resource declaration of the S3 bucket.

### Topics Covered
By the end of this lab, you will be able to:

+ Write a simple CloudFormation template that describes an [S3](https://aws.amazon.com/s3/) bucket.
+ Deploy the template and create a CloudFormation stack.

### Start Lab

1. Go to the `code/workspace/` directory.
2. Open the `template-and-stack.yaml` file in your code editor.
3. Here is a sample CloudFormation template that defines an S3 Bucket. It has a single resource that contains the S3 bucket.
   Copy the code below and save to the `template-and-stack.yaml` file.
   ```yaml
   Resources:
     S3Bucket:
       Type: AWS::S3::Bucket
       Properties:
         BucketEncryption:
           ServerSideEncryptionConfiguration:
             - ServerSideEncryptionByDefault:
                 SSEAlgorithm: AES256
   ```
4. It’s now time to create your stack! Follow steps below:

   :::::tabs{variant="container"}
	::::tab{id="cloud9" label="Cloud9"}
	1. In the **Cloud9 terminal** navigate to `code/workspace`:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    cd cfn101-workshop/code/workspace
    :::
    1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws cloudformation create-stack --stack-name cfn-workshop-template-and-stack --template-body file://template-and-stack.yaml
    :::
    1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
    :::code{language=shell showLineNumbers=false showCopyAction=false}
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-template-and-stack/739fafa0-e4d7-11ed-a000-12d9009553ff"
    :::
    1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
    ::::
    ::::tab{id="local" label="Local development"}
   1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
   1. Choose **Create stack** (_With new resources (Standard)_ from the top-right side of the page.
   1. In **Prepare template**, choose **Template is ready**.
   1. In **Template source**, choose **Upload a template file**.
   1. Choose the **Choose file** button and navigate to your workshop directory.
   1. Select the file `template-and-stack.yaml` referenced in step 1.
   1. Choose **Next**.
   1. Provide a **Stack name**. For example `cfn-workshop-template-and-stack`.
        + The _Stack name_ identifies the stack. Use a name to help you distinguish the purpose of this stack.
        + Choose **Next**.
   1. Choose to accept default values for **Configure stack options**; choose **Next**.
   1. On the **Review <stack_name>** page, scroll to the bottom and choose **Submit**.
   1. Use the **refresh** button to update the page as needed, until you see the stack has the **CREATE_COMPLETE** status.
   ::::
   :::::

### Challenge
In this exercise, you'll enable versioning on the S3 bucket to prevent objects from being deleted or
overwritten by mistake or to archive objects so that you can retrieve previous versions of them.

1. Create a `VersioningConfiguration` property in the `Properties` section of the S3 resource.
2. Set the `Status` to `Enabled`.
3. Update the stack to reflect the changes made in the template.

::expand[Check out the AWS Documentation for [AWS::S3::Bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) resource.]{header="Need a hint?"}

::::::expand{header="Want to see the solution?"}
1. Replace the code in your template with the code below:
   ```yaml
   Resources:
     S3Bucket:
       Type: AWS::S3::Bucket
       Properties:
         VersioningConfiguration:
           Status: Enabled
         BucketEncryption:
           ServerSideEncryptionConfiguration:
             - ServerSideEncryptionByDefault:
                 SSEAlgorithm: AES256
   ```
1. It’s now time to update your stack! Follow steps below:

   :::::tabs{variant="container"}
	::::tab{id="cloud9" label="Cloud9"}
	1. In the **Cloud9 terminal** navigate to `code/workspace`:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    cd cfn101-workshop/code/workspace
    :::
    1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws cloudformation update-stack --stack-name cfn-workshop-template-and-stack --template-body file://template-and-stack.yaml
    :::
    1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
    :::code{language=shell showLineNumbers=false showCopyAction=false}
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-template-and-stack/739fafa0-e4d7-11ed-a000-12d9009553ff"
    :::
    1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
    ::::
    ::::tab{id="local" label="Local Development"}
   1. Log in to the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new browser tab.
   1. Select the stack name, for example `cfn-workshop-template-and-stack`.
   1. In the top right corner select **Update**.
   1. In **Prepare template**, choose **Replace current template**.
   1. In **Template source**, choose **Upload a template file**.
   1. Select **Choose file** button and navigate to your workshop directory.
   1. Choose the file `code/workspace/template-and-stack.yaml` and select **Next**.
   1. On **Specify stack details** page, select **Next**.
   1. On the **Configure stack options** page, select **Next**.
   1. On the **Review <stack_name>** page, scroll down and wait for the **Change set** section to complete. Then select **Submit**.
   1. Wait for the stack status to reach **UPDATE_COMPLETE**. You need to periodically select **Refresh** to see the latest stack status.
   ::::
   :::::

::::::

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-template-and-stack`.
1. In the top right corner, select **Delete**.
1. In the pop-up window, select **Delete**.
1. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---

### Conclusion

Great work! You have written your first CloudFormation template and created your first stack.
