---
title: "Language extensions"
weight: 640
---

_Lab Duration: ~30 minutes_

---

### Overview

With the goal of extending the AWS CloudFormation language, the CloudFormation team has been having open discussions with the CloudFormation community, by using an [RFC mechanism](https://github.com/aws-cloudformation/cfn-language-discussion). These discussions have led to the launch of new language extensions for CloudFormation. A language extension is a transform, which is a macro hosted by CloudFormation. In its first release in 2022, three new language extensions were added:

1. JSON string conversion ([Fn::ToJsonString](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ToJsonString.html)): converts an object or array to its corresponding JSON string.
2. Length ([Fn::Length](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-length.html)): returns the number of elements within an array.
3. [Intrinsic functions and pseudo-parameter references](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/function-refs-in-policy-attributes.html): allow the user to define the `DeletionPolicy` and `UpdateReplacePolicy` [resource attributes](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-product-attribute-reference.html) whose values can be referenced by parameters, for example.


For more information, see [Introducing new language extensions in AWS CloudFormation](https://aws.amazon.com/blogs/mt/introducing-new-language-extensions-in-aws-cloudformation/).

In this lab, you'll explore and learn how you can leverage these language extensions to augment your developer experience.


### Topics Covered

By the end of this lab, you'll be able to:

* Understand how to incorporate the `AWS::LanguageExtensions` transform in your CloudFormation templates.
* Use language extensions in your CloudFormation template.

### Start Lab

### Prerequisites

You can use the default VPC that comes with your AWS account.


### Part 1

In part 1 of this lab, you'll use an example CloudFormation template, `language-extensions.yaml`, to create a stack in the `us-east-1` region. To get started, follow steps shown next:

1. Navigate to `code/workspace/language-extensions` directory.
1. Open the `language-extensions.yaml` CloudFormation template in your own text editor.
1. Familiarize with the configuration of resources in the template. This template creates an [Amazon Elastic Compute Cloud (Amazon EC2)](https://aws.amazon.com/ec2/) instance tagged as a `DEV` environment resource. Note that, up to this point, the template does not specify a `DeletionPolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) for the EC2 instance.

By default, CloudFormation uses `Delete` as the default value for the `DeletionPolicy` attribute for resources; exceptions to this are `AWS::RDS::DBCluster` resources, and `AWS::RDS::DBInstance` resources that don't specify the `DBClusterIdentifier` property. If you use the template above for the creation of a stack, upon deletion of the stack itself the EC2 instance will be terminated. One of the common use cases is to retain the resources that are created in production, whilst having the flexibility to discard and recreate test resources, as needed, for development activities: with the `AWS::LanguageExtensions` transform in your template, you can reference the `DeletionPolicy` value you need from a parameter. The language extension you'll use adds the functionality of referencing a value for resource attributes like `DeletionPolicy` and `UpdateReplacePolicy` that natively accept a string value and not a parameter reference.

In this example, your intent is to specify `DeletionPolicy` as `Delete` for your instance in the `DEV` environment; follow steps shown next:


1. Open the `language-extensions.yaml` template. Add the `AWS::LanguageExtensions` transform line by copying and pasting the content below _underneath_ the `AWSTemplateFormatVersion: "2010-09-09"` line:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=3}
Transform: AWS::LanguageExtensions
:::
1. Add a parameter, called for example `DeletionPolicyParameter`, by copying and pasting the content below _underneath_ the existing `Parameters` section:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=13}
DeletionPolicyParameter:
  Type: String
  AllowedValues: [Delete, Retain]
  Default: Delete
:::
1. Underneath the `Resources` section, modify the EC2 instance resource configuration: add `DeletionPolicy` at the same level as `Type`, and reference the `DeletionPolicyParameter` you added earlier, as shown next:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=18 highlightLines=20}
Resources:
  EC2Instance:
    DeletionPolicy: !Ref DeletionPolicyParameter
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      Tags:
        - Key: Environment
          Value: DEV
:::

Save the template file, and proceed to the next steps.

You'll now create a new stack, using the template you modified, in the `us-east-1` region.
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's create a stack by running the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-language-extensions \
--template-body file://language-extensions.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation returns the following output.
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. Wait until the `CREATE` operation is complete, by using the [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-language-extensions
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From the left navigation panel, select the **Stacks** tab. From the right side of the page, choose **Create Stack**, and then choose **With new resources (standard).**
1. From **Prerequisite**-**Prepare template**, choose **Template is ready**.
1. Under **Specify template**, select **Template source**, and choose **Upload a template file**. Select **Choose file**, and supply the `language-extensions.yaml` template you updated earlier, and then choose **Next**.
1. In the **Specify Stack details** page:
    1. Specify a **Stack** name. For example, choose `cfn-workshop-language-extensions`.
    1. Under **Parameters**, choose to accept the value for `DeletionPolicyParameter` as `Delete`, which is set as the default value in the template; keep the value for `LatestAmiId` as it is. Choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
1. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.
::::
:::::

Congratulations! You have learned how to use intrinsic function references for the `DeletionPolicy` attribute; you can also use them with the `UpdateReplacePolicy` attribute as well. In the next part, you'll learn how to use another language extension: `Fn::ToJsonString`.

### Part 2

Now that you have your EC2 instance running, you choose to monitor it by creating an [Amazon CloudWatch dashboard](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html) that provides customized views of the metrics and alarms for your AWS resources. You can add metrics such as `CPUUtilization`, `DiskReadOps`, etc. to a dashboard as a [widget](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-and-work-with-widgets.html).

A dashboard body is a string in JSON format: for more information, see [Dashboard Body Structure and Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html). When you describe a CloudWatch dashboard with CloudFormation, you specify a JSON string that contains keys and values, such as:

:::code{language=json showLineNumbers=true showCopyAction=false}
{
    "start":"-PT6H",
    "periodOverride":"inherit",
    [...]
}
:::


To make it easier to write and consume a dashboard (for example, to avoid escaping inner quotes like `\"`), and to avoid maintaining a single-line string you can use the `Fn::ToJsonString` language extension to specify a JSON object, which is easier to compose and to maintain. With this language extension, you can specify the structure of a CloudWatch dashboard as a JSON object instead, thus simplifying the task.

`Fn::ToJsonString` allows developers to convert a template block in the form of an object or array into an escaped JSON string. You can then use a newly-converted JSON string as a set of input values to string-type properties for resources that include the CloudWatch dashboard resource type. This simplifies the code in your template, and enhances its readability.

In this part 2 of the lab, you'll update the `language-extensions` stack you created earlier, and add a CloudWatch dashboard with the `CPUUtilization` metric for your EC2 instance.

For simplicity, in this exercise you'll add the dashboard to your existing template, so you can focus on the language extension you'll use. Normally, you would create a separate template for your dashboards, for considerations on best practices that also include organizing your stacks by [lifecycle and ownership](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html#organizingstacks): you would want to, for example, create a separate template to decouple the lifecycle of your CloudWatch dashboard from the lifecycle of your EC2 instance.

You'll now update the `language-extensions.yaml` template to add a CloudWatch dashboard with CPU utilization data of the EC2 instance you created in part 1. To do so, follow steps shown next:

1. Open the `language-extensions.yaml` template. Underneath `Resources` section, add `Dashboard`:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=29}
Dashboard:
  Type: AWS::CloudWatch::Dashboard
  Properties:
    DashboardBody:
      Fn::ToJsonString:
        start: -PT6H
        periodOverride: inherit
        widgets:
          - type: metric
            x: 0
            "y": 7
            width: 3
            height: 3
            properties:
              metrics: [[AWS/EC2, CPUUtilization, InstanceId, !Ref EC2Instance]]
              period: 300
              stat: Average
              region: !Ref AWS::Region
              title: EC2 Instance CPU
:::

In the above snippet, note that the `CPUUtilization` metric is reflected underneath the `properties` section through the `metrics` field. Note also the references to your EC2 instance with `!Ref`, that in this case will return the instance ID, and the reference to the current region with `!Ref AWS::Region`, where you'll use the `AWS::Region` CloudFormation pseudo parameter to resolve the name of the region where you are creating the stack and the EC2 instance (in this lab, `us-east-1`).

Save the template file, and proceed to the next steps.

You'll now update your existing stack that you created in Part 1. To do so, follow steps shown next:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Update the stack `cfn-workshop-language-extensions` by running the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-language-extensions \
--template-body file://language-extensions.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation returns the following output.
:::code{language=json showLineNumbers=false showCopyAction=false}
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. Wait until the `UPDATE` operation is complete, by using the [wait stack-update-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-update-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-language-extensions
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From the left navigation panel, select the **Stacks** tab. Select the `cfn-workshop-language-extensions` stack you created earlier.
1. From the top-right menu, choose **Update**.
1. Under **Prerequisite - Prepare template,** select **Replace current template** and choose **Upload a template file**. Select **Choose file**, and supply the `language-extensions.yaml` template you updated earlier, and then choose **Next**.
1. On **Specify Stack details** page, leave the configuration as it is. Choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section.
1. Choose **Submit**. Refresh the stack creation page until you see the stack in the `UPDATE_COMPLETE` status.
::::
:::::

* Navigate to the [CloudWatch console](https://console.aws.amazon.com/cloudwatch/). From the right navigation panel, choose **Dashboards**.
* Select the **Dashboard** that you have created, From the top-right, choose **Actions**.
* Select **View/edit source**, you should see `JSON` for the dashboard that matches `YAML` from `language-extensions.yaml`

Congratulations! You have learned how to use `Fn::ToJsonString` to transform JSON objects into escaped JSON strings as inputs to resource properties.

### Challenge

In this exercise, you'll use the knowledge gained from earlier parts of this lab. Your task is to create an [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) bucket with its deletion policy set to a parameterized value of `Delete`, and create a CloudWatch dashboard that reflects the number of objects in the bucket. Use the `language-extensions-challenge.yaml` template, and add content to it.

Refer to the [CloudWatch Dashboard structure](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html) mentioned in Part 2 of the lab as you describe the dashboard in your CloudFormation template. For the `metrics` field underneath `properties`, use `[[AWS/S3, NumberOfObjects, StorageType, AllStorageTypes, BucketName, !Ref S3Bucket]]` to denote the `NumberOfObjects` metrics in an S3 bucket for your CloudWatch widget. Please note that [S3 storage metrics are reported once per day](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cloudwatch-monitoring.html) at no additional cost, so you may not see them when you are running the lab.


:::expand{header="Need a hint?"}
* Recall using the language extension in Part 1 of the lab to use a parameter for the deletion policy.
* Don’t forget to reference the deletion policy parameter in your S3 bucket resource.
* Additionally, recall how you added a CloudWatch dashboard earlier, add use the `NumberOfObjects` metrics for the relevant field.
:::

::::::expand{header="Want to see the solution?"}
* Add the `Transform: AWS::LanguageExtensions` line to the template like you did in Part 1 of the lab.
* Edit the `Parameters` section to add the `DeletionPolicyParameter` like you did in Part 1 of the lab.
* Underneath the `Resources` section for the `S3Bucket` resource, add the `DeletionPolicy` attribute with a reference to the parameter.
* Underneath the `Resources` section, add the `Dashboard` resource.
* You can find the full challenge solution in the template called `language-extensions-solution.yaml`, that is in the `code/solutions/language-extensions` directory.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's create the stack by running the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-language-extensions-solution \
--template-body file://language-extensions-challenge.yaml \
--capabilities CAPABILITY_AUTO_EXPAND
1. CloudFormation returns the following output.
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-language-extensions-solution/466df9e0-0dff-08e3-8e2f-5088487c4896"
:::
1. Wait until the `CREATE` operation is complete, by using the [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-language-extensions-solution
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From the left navigation panel, select the **Stacks** tab. From the right side of the page, choose **Create Stack**, and then choose **With new resources (standard).**
1. From **Prerequisite**-**Prepare template**, choose **Template is ready**.
1. Under **Specify template**, select **Template source**, and choose **Upload a template file**. Select **Choose file**, and supply the `language-extensions-challenge.yaml` template you updated earlier, and then choose **Next**.
1. In the **Specify Stack details** page:
   1. Specify a **Stack** name. For example, choose `cfn-workshop-language-extensions-solution`.
   1. Under **Parameters**, choose to accept the value for `DeletionPolicyParameter` as `Delete`, which is set as the default value in the template, Choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
1. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.
::::
:::::
::::::

### Clean up

You'll now tear down the resources you created in this lab. Use following steps:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Delete the stack `cfn-workshop-language-extensions` by running the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-language-extensions
:::
1. Wait until the `DELETE` operation is complete, by using the [wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--stack-name cfn-workshop-language-extensions
:::
1. Repeat steps (1-2) above to delete the stack `cfn-workshop-language-extensions-solution`.
::::
::::tab{id="LocalDevelopment" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. On the **Stacks** page in the CloudFormation console, select the stack you created in **Part 1:** `cfn-workshop-language-extensions`.
1. In the stack details pane, choose **Delete**. Select **Delete** when prompted.
1. On the **Stacks** page in the CloudFormation console, select the stack you created in **Challenge** section: `cfn-workshop-language-extensions-solution`.
1. In the stack details pane, choose **Delete**. Select **Delete** when prompted.
::::
:::::

---

### Conclusion

Great work! You learned how to incorporate `AWS::LanguageExtensions` in your CloudFormation templates. Please feel free to provide feedback for RFCs in the [Language Discussion GitHub repository](https://github.com/aws-cloudformation/cfn-language-discussion). We welcome your contributions!
