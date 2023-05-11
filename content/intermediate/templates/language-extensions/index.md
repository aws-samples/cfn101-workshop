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

In this lab, you will be exploring how you can leverage these language extensions to augment your developer experience.


### Topics Covered

By the end of this lab, you will be able to:

* Understand how to incorporate the `AWS::LanguageExtensions` transform in your CloudFormation templates.
* Use language extensions in your CloudFormation template.

### Start Lab

### Prerequisites

You can use the default VPC that comes with your AWS account.


### Part 1

In part 1 of this lab, you will use an example CloudFormation template, `language-extensions.yaml`, to create a stack in the `us-east-1` region. To get started, follow steps shown next:

1. Change directory to the `code/workspace/language-extensions` directory.
2. Open the `language-extensions.yaml` CloudFormation template in the text editor of your choice.
3. Familiarize with the configuration of resources in the template. This template creates an [Amazon Elastic Compute Cloud (Amazon EC2)](https://aws.amazon.com/ec2/) instance tagged as a `Dev` environment resource. Note that, up to this point, the template does not specify a `DeletionPolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) for the EC2 instance.

By default, CloudFormation uses `Delete` as the default value for the `DeletionPolicy` attribute for resources; exceptions to this are `AWS::RDS::DBCluster` resources, and `AWS::RDS::DBInstance` resources that don't specify the `DBClusterIdentifier` property. If you use the template above for the creation of a stack, upon deletion of the stack itself the EC2 instance will be terminated. One of the common use cases is to retain the resources that are created in production, whilst having the flexibility to discard and recreate test resources, as needed, for development activities: with the `AWS::LanguageExtensions` transform in your template, you can reference the `DeletionPolicy` value you need from a parameter. The language extension you'll use adds the functionality of referencing a value for resource attributes like `DeletionPolicy` and `UpdateReplacePolicy` that natively accept a string value and not a parameter reference.

In this example, your intent is to specify `DeletionPolicy` as `Delete` for your instance in the `Dev` environment; follow steps shown next:


1. Open the `language-extensions.yaml` template. Add the `AWS::LanguageExtensions` transform line by copying and pasting the content below _underneath_ the `AWSTemplateFormatVersion: "2010-09-09"` line:

```yaml
Transform: AWS::LanguageExtensions
```

2. Add a parameter, called for example `DeletionPolicyParameter`, by copying and pasting the content below _underneath_ the existing `Parameters` section:

```yaml
  DeletionPolicyParameter:
    Type: String
    AllowedValues: [Delete, Retain]
    Default: Delete
```

3. Underneath the `Resources` section, modify the EC2 instance resource configuration: add `DeletionPolicy` at the same level as `Type`, and reference the `DeletionPolicyParameter` you added earlier, as shown next:

```yaml
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
```


Save the template file, and proceed to the next steps.

You will now create a new stack, using the template you modified, in the `us-east-1` region.

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From the left navigation panel, select the **Stacks** tab. From the right side of the page, choose **Create Stack**, and then choose **With new resources (standard).**
3. From **Prerequisite**-**Prepare template**, choose **Template is ready**.
4. Under **Specify template**, select **Template source**, and choose **Upload a template file**. Select **Choose file**, and supply the `language-extensions.yaml` template you updated earlier, and then choose **Next**.
5. In the **Specify Stack details** page:
    1. Specify a **Stack** name. For example, choose  `language-extensions`.
    2. Under **Parameters**, choose to accept the value for `DeletionPolicyParameter` as `Delete`, which is set as the default value in the template; keep the value for `LatestAmiId` as it is. Choose **Next**.
6. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
7. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
8. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.


Congratulations! You have learned how to use intrinsic function references for the `DeletionPolicy`attribute; you can also use them with the `UpdateReplacePolicy` attribute as well. In the next part, you will learn how to use another language extension: `Fn::ToJsonString`.

### Part 2

Now that you have your EC2 instance running, you choose to monitor it by creating an [Amazon CloudWatch dashboard](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html) that provides customized views of the metrics and alarms for your AWS resources. You can add metrics such as `CPUUtilization`, `DiskReadOps`, et cetera to a dashboard as a [widget](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-and-work-with-widgets.html).

A dashboard body is a string in JSON format: for more information, see [Dashboard Body Structure and Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html). When you describe a CloudWatch dashboard with CloudFormation, you specify a JSON string that contains keys and values, such as:

```yaml
"{\"start\":\"-PT6H\",\"periodOverride\":\"inherit\",[...]}
```


To make it easier to write and consume a dashboard (for example, to avoid escaping inner quotes like  `\"`), and to avoid maintaining a single-line string you can use the `Fn::ToJsonString` language extension to specify a JSON object, which is easier to compose and to maintain. With this language extension, you can specify the structure of CloudWatch dashboard as a JSON object instead, thus simplifying the task.

`Fn::ToJsonString` allows developers to convert a template block in the form of an object or array into an escaped JSON string. You can then use a newly-converted JSON string as a set of input values to string-type properties for resources that include the CloudWatch dashboard resource type. This simplifies the code in your template, and enhances its readability.

In this part 2 of the lab, you will update the `language-extensions` stack you created earlier, and add a CloudWatch dashboard with the `CPUUtilization` metric for your EC2 instance.

For simplicity, in this exercise you’ll add the dashboard to your existing template, so you can focus on the language extension you’ll use. Normally, you would create a separate template for your dashboards, for considerations on best practices that include organizing your stacks by [lifecycle and ownership](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html#organizingstacks): you would want to, for example, create a separate template to decouple the lifecycle of your CloudWatch dashboard from the lifecycle of your EC2 instance.

You will now update the `language-extensions.yaml` template to add a CloudWatch dashboard with CPU utilization data of the EC2 instance you created in part 1. To do so, follow steps shown next:

1. Open the `language-extensions.yaml` template. Underneath `Resources` section, add `Dashboard`:

```yaml
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
```


In the above snippet, note that the `CPUUtilization` metric is reflected underneath the  `properties` section through the `metrics` field. Note also the references to your EC2 instance with `!Ref`, that in this case will return the instance ID, and the reference to the current region with `!Ref AWS::Region`, where you’ll use the `AWS::Region` CloudFormation pseudo parameter to resolve the name of the region where you are creating the stack and the EC2 instance (in this lab, `us-east-1`).

Save the template file, and proceed to the next steps.

You will now update your existing stack that you created in Part 1. To do so, follow steps shown next:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From the left navigation panel, select the **Stacks** tab. Select the `language-extensions` stack you created earlier.
3. From the top-right menu, choose **Update**.
4. Under **Prerequisite - Prepare template,** select **Replace current template** and choose **Upload a template file**. Select **Choose file**, and supply the `language-extensions.yaml` template you updated earlier, and then choose **Next**.
5. On **Specify Stack details** page, leave the configuration as it is. Choose **Next**.
6. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
7. On **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section.
8. Choose **Submit**. Refresh the stack creation page until you see the stack in the `UPDATE_COMPLETE` status.
9. Navigate to the [CloudWatch console](https://console.aws.amazon.com/cloudwatch/). From the right navigation panel, choose **Dashboards**. You should see the dashboard you just created.


Congratulations! You have learned how to use `Fn::ToJsonString` to transform JSON objects into escaped JSON strings as inputs to resource properties.

### Challenge

In this exercise, you’ll use the knowledge gained from earlier parts of this lab. Your task is to create an [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) bucket with its deletion policy set to a parameterized value of `Delete`, and create a CloudWatch dashboard that reflects the number of objects in the bucket. Use the `language-extensions-challenge.yaml` template, and add content to it.

Refer to the [CloudWatch Dashboard structure](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html) mentioned in Part 2 of the lab as you describe the dashboard in your CloudFormation template. For the `metrics` field underneath `properties`, use `[[AWS/S3, NumberOfObjects, StorageType, AllStorageTypes, BucketName, !Ref S3Bucket]]` to denote the `NumberOfObjects` metrics in an S3 bucket for your CloudWatch widget. Please note that [S3 storage metrics are reported once per day](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cloudwatch-monitoring.html) at no additional cost, so you may not see them when you are running the lab.


:::expand{header="Need a hint?"}
* Recall using the language extension in Part 1 of the lab to use a parameter for the deletion policy.
* Don’t forget to reference the deletion policy parameter in your S3 bucket resource.
* Additionally, recall how you added a CloudWatch dashboard earlier, add use the `NumberOfObjects` metrics for the relevant field.
:::

:::expand{header="Want to see the solution?"}
* Add the `Transform: AWS::LanguageExtensions` line to the template like you did in Part 1 of the lab.
* Edit the `Parameters` section to add the `DeletionPolicyParameter` like you did in Part 1 of the lab.
* Underneath the `Resources` section for the `S3Bucket` resource, add the `DeletionPolicy` attribute with a reference to the parameter.
* Underneath the `Resources` section, add the `Dashboard` resource.
* You can find the full language-extensions-solution in the template `language-extensions-solution.yaml` in the `code/solutions/language-extensions` directory.
* Use the updated template, and create a new `language-extensions-solution` stack to create the S3 bucket and the dashboard.
:::

### Clean up

You will now tear down the resources you created:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. On the **Stacks** page in the CloudFormation console, select the stack you created in **Part 1:** `language-extensions`.
3. In the stack details pane, choose **Delete**.  Select **Delete stack** when prompted.
4. On the **Stacks** page in the CloudFormation console, select the stack you created in **Challenge** section: `language-extensions-solution`.
5. In the stack details pane, choose **Delete**.  Select **Delete stack** when prompted.

### Conclusion

Great work! You learned how to incorporate `AWS::LanguageExtensions` in your CloudFormation template. Please feel free to leave us your feedback at our [Language Discussion GitHub repository](https://github.com/aws-cloudformation/cfn-language-discussion). We welcome your contributions to RFCs!
