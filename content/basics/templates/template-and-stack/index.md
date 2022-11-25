---
title: "Template and stack"
weight: 200
---

_Lab Duration: ~10 minutes_

---

### Overview
This lab will start with the most basic template containing only Resources object, which contains a single resource declaration of the S3 bucket.

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
4. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
5. Click on **Create stack** (_With new resources (Standard)_ if you have clicked in the top right corner).
6. In **Prepare template**, choose **Template is ready**.
7. In **Template source**, choose **Upload a template file**.
8. Click on **Choose file** button and navigate to your workshop directory.
9. Select the file `template-and-stack.yaml` referenced in step 1.
10. Click **Next**.
11. Provide a **Stack name**. For example **cfn-workshop-s3**.
     + The _Stack name_ identifies the stack. Use a name to help you distinguish the purpose of this stack.
     + Click **Next**.
12. You can leave **Configure stack options** default, click **Next**.
13. On the **Review <stack_name>** page, scroll down to the bottom and choose **Submit**.
14. You can click the **refresh** button a few times until you see in the status **CREATE_COMPLETE**.

### Challenge
In this exercise, enable versioning on the S3 bucket. Enabled versioning will prevent objects from being deleted or
overwritten by mistake or to archive objects so that you can retrieve previous versions of them.

1. Create a property `VersioningConfiguration` in the `Properties` section of the S3 resource.
2. Set the `Status` to `Enabled`.
3. Update the stack to reflect the changes made in the template.

::expand[Check out the AWS Documentation for [AWS::S3::Bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) resource.]{header="Need a hint?"}

:::expand{header="Want to see the solution?"}
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
1. Go to the AWS console to update your CloudFormation Stack:

   1. Log in to the **[AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation)** in a new browser tab.
   1. Select the stack name, for example **cfn-workshop-s3**.
   1. In the top right corner select **Update**.
   1. In **Prepare template**, choose **Replace current template**.
   1. In **Template source**, choose **Upload a template file**.
   1. Select **Choose file** button and navigate to your workshop directory.
   1. Choose the file `code/workspace/template-and-stack.yaml` and select **Next**.
   1. On **Specify stack details** page, select **Next**.
   1. On the **Configure stack options** page, select **Next**.
   1. On the **Review <stack_name>** page, scroll down and wait for the **Change set** section to complete. Then select **Submit**.
   1. Wait for the stack status to reach **UPDATE_COMPLETE**. You need to periodically select **Refresh** to see the latest stack status.
   :::

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-s3`.
1. In the top right corner, click on **Delete**.
1. In the pop-up window click on **Delete stack**.
1. You can click the **refresh** button a few times until you see in the status **DELETE_COMPLETE**.

---

### Conclusion

Great work! You have written your first CloudFormation template and created your first stack.
