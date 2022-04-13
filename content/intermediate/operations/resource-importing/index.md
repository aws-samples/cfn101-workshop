---
title: "Resource Importing"
weight: 400
---

### Overview

You use [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) to programmatically manage your infrastructure you describe with code. If you have created, in your AWS account, a resource with the [AWS Management Console](https://aws.amazon.com/console/) or the [AWS Command Line Interface](https://aws.amazon.com/cli/) (CLI) for example, you can choose to [import](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html) your resource into a CloudFormation stack, so you can manage the resource’s lifecycle with CloudFormation.

You can also use the import functionality if you want to [move your resources between stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/refactor-stacks.html), so you can organize your stacks and resources by [lifecycle and ownership](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html#organizingstacks). For example, you choose to reorganize resources such as [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) security groups into one stack - or stacks - you dedicate to your security group resources.

::alert[For more information on supported resources for import operations, see [Resources that support import and drift detection operations](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-supported-resources.html).]{type="info"}


### Topics Covered

By the end of this lab, you will be able to:

* Learn how to import a resource into your stack.
* Learn and practice important considerations for a number of resource import use cases.



### Start Lab

* Change directory to `code/workspace/resource-importing`.
* Open the `resource-importing.yaml` file.
* Update the content of the template as you follow along steps on this lab.

### Lab Part 1

In this lab, you will first create an [Amazon Simple Notification Service](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) (Amazon SNS) topic with the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and you will then import the topic in a new CloudFormation stack you will create. Next, you will create a second topic with the Amazon SNS Console, and you will import it as well into your existing stack.

To get started, follow steps shown next:

1. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and choose **Topics**. Next, choose **Create topic**.
2. Choose `Standard` for the topic **Type**.
3. Specify a **Name** for your topic, such as `Topic1`.
4. When ready, choose **Create topic**.
5. When your topic is successfully created, take a note of its [**Amazon Resource Name (ARN)**](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) under the **Details** section for `Topic1`: you will use this ARN value later in this lab. For reference, an example ARN pattern for an Amazon SNS topic is `arn\:aws\:sns\:us-east-1:123456789012\:MyTopic`.

Let’s now use the resource import functionality to import your newly created topic into a new stack you will create. For this, you will use a CloudFormation template where you describe your existing topic with the `AWS::SNS::Topic` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html) as follows:

* You will specify, for the `TopicName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#cfn-sns-topic-topicname), the name of your existing topic, that is `Topic1`. Choose to pass this value with a template [parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html), that you will call `Topic1Name`. You will then reference the value for this parameter with the `Ref` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html).
* Each resource you import must have a `DeletionPolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) described for it: specify this attribute for your topic, and specify `Retain` for the attribute value. When you use a `Retain` value for the `DeletionPolicy` attribute, you indicate to retain the resource when you remove it from the stack, or when you delete the stack.
* Copy the code below, append it to the `resource-importing.yaml` file, and save the file:

```yaml
Parameters:
  Topic1Name:
    Type: String
    Default: Topic1
    Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
Resources:
  SNSTopic1:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref Topic1Name
```


::alert[All resources you import must have a [DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) attribute set in your template for the import operation to succeed. For more information, see [Considerations during an import operation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations).]{type="info"}

In this next step, you will use the AWS CloudFormation Console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html) using the `resource-importing.yaml` template:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With existing resources (import resources)**.
3. Read the **Import overview**, and choose **Next**.
4. From **Specify template**, choose **Upload a template file**. Upload the `resource-importing.yaml` template, and choose **Next**.
5. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the value for the topic ARN you noted after you created `Topic1`.
6. Enter a **Stack name**. For example, specify `resource-importing`. Make sure you specify `Topic1` for the `Topic1Name` parameter value.
7. In the next page, choose **Import resources**.

Your stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.

Congratulations! You imported a resource, that you created earlier with the Amazon SNS Console, into a new stack! For information on how to import existing resources into a new stack using the [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), see [Creating a stack from existing resources using AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html#resource-import-new-stack-cli).

### Lab Part 2

In this lab, you will learn how to import a resource into an existing stack. To get started, follow steps below:

1. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/) to create a second topic. Follow steps you used on lab part 1, and specify **Topic2** for the name of your new topic.
2. When your topic is successfully created, take a note of its [**Amazon Resource Name (ARN)**](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) under the **Details** section for `Topic2`; you will use this information later on in this lab (example ARN pattern: `arn\:aws\:sns\:us-east-1:123456789012\:MyTopic`).
3. Copy the example below, and **append it to the `Parameters` section** of the `resource-importing.yaml` template, that you used for the previous lab:

```yaml
Topic2Name:
  Type: String
  Default: Topic2
  Description: Name of the second Amazon SNS topic you created with the Amazon SNS console.
```

4. Next, copy the example below, and **append it to the `Resources` section** of the `resource-importing.yaml` template. Save the template file when done.

```yaml
SNSTopic2:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic2Name
```

5. The `resource-importing.yaml` template you just updated will now include 2 parameters (`Topic1Name` and `Topic2Name`), and 2 resources (`SNSTopic1` and `SNSTopic2`). Let’s import the new topic into the existing stack!
6. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
7. Select the stack named `resource-importing` and, from **Stack actions**, choose **Import resources into stack**.
8. Read the **Import Overview** and choose **Next**.
9. From **Specify template**, choose **Upload a template file**. Upload the `resource-importing.yaml` template you updated with this lab part, and choose **Next**.
10. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the topic ARN value you noted after you created `Topic2`.
11. For parameters, make sure you specify `Topic1` for `Topic1Name`, and `Topic2` for `Topic2Name`. Choose **Next**.
12. In the next page, choose **Import resources**.

Your stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.

Congratulations! You have learned how to import a resource into an existing stack! For more information, see also [Import an existing resource into a stack using the AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html#resource-import-existing-stack-cli).


### Lab Part 3

In this part of the lab, you will learn how to [move resources between stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/refactor-stacks.html). You will remove the `SNSTopic1` resource from the `resource-importing` stack, and you will import it into a new one; note that since you specified `Retain` for the `DeletionPolicy` attribute of `SNSTopic1`, the `SNSTopic1` resource will not be deleted when you will update the stack. Let's get started:


1. Remove the code below from the **Parameters** section of the `resource-importing.yaml` template you used for lab part 2:

```yaml
Topic1Name:
  Type: String
  Default: Topic1
  Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
```

2. Remove the code below from the **Resources** section of the `resource-importing.yaml` template, and save the template file.

```yaml
SNSTopic1:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic1Name
```

3. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
4. Select the stack named `resource-importing` and choose **Update**.
5. Choose **Replace current template** and upload the `resource-importing.yaml` template. Choose **Next**.
6. In the parameters section, choose to accept the parameter value for `Topic2Name` as `Topic2`. Choose **Next**.
7. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
8. Choose **Update stack** in the next page.
9. To confirm the removal of `SNSTopic1` resource from the stack, select the `resource-importing` stack and choose **Resources**. You should see only one resource: `SNSTopic2`.


Choose to import the `SNSTopic1` resource into a new stack:

1. Make sure you are in the `code/workspace/resource-importing` directory.
2. Open the `moving-resources.yaml` template file with your favorite text editor.
3. Append the example below to the `moving-resources.yaml` template, and save it.

```yaml
Parameters:
  Topic1Name:
    Type: String
    Default: Topic1
    Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
Resources:
  SNSTopic1:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref Topic1Name
```

4. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
5. From **Create stack**, choose **With existing resources (import resources)**.
6. Read the **Import Overview** and choose **Next**.
7. From **Specify template**, choose **Upload a template file**. Upload the `moving-resources.yaml` template and choose **Next.**
8. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the topic ARN value you noted after you created `Topic1`.
9. Enter a **Stack name**. For example, specify `moving-resources`. Make sure you specify `Topic1` for the `Topic1Name` parameter.
10. Choose **Import Resources** in the next page.

The stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.

Congratulations! You have learned how to move resources between stacks.


::alert[To revert an import operation for a given resource, first set the `DeletionPolicy` to `Retain` for the resource in your template, and then update the stack to apply the change. Next, remove the resource from the template, and update the stack again: in doing so, you will remove the resource from your stack, but you retain the resource.]{type="info"}

### **Best Practices while importing a resource**

1. To fetch the properties of an existing resource, use the AWS Management Console page for the relevant AWS service, or use a _Describe_ API call to describe the resource and fetch properties you want to include in the resource definition. For example, use the `aws ec2 describe-instances` [CLI command](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html) to describe your Amazon EC2 instance you want to import, using the instance ID as shown in the following example:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ec2 describe-instances --instance-ids i-1234567890abcdef0
:::

::alert[Make sure you verify that resource properties you define in a template match the actual configuration of the resource, to avoid unexpected changes.]{type="info"}

2. When you describe in your template a resource you wish to import, make sure you specify all required properties for your resource. For example, [AssumeRolePolicyDocument](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html#cfn-iam-role-assumerolepolicydocument) is a required property for the [AWS::IAM::Role](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html) resource type.
3. Once a resource import is successful, run [Drift Detection](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html) to verify resource properties in the template match the actual configuration of the resource.

For more information, see [Considerations during an import operation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations).

### Challenge

In this exercise, you will need to use the knowledge gained from lab parts 1, 2, and 3 to complete the provided task. You are tasked with solving the following issue: one of the resources in a CloudFormation template, an EC2 instance, has a property value that was modified outside of CloudFormation as a result of a human error. You will troubleshoot and solve this issue, so that you can continue maintaining your desired resource configuration with CloudFormation.

Let's start with an example template that describes an EC2 instance and an Amazon S3 bucket.

To begin, follow the steps below:

1. Make sure you are in the directory: `code/workspace/resource-importing`.
2. Open the `resource-import-challenge.yaml` file.
3. Add the example below to the `resource-import-challenge.yaml` template, and save the file.

```yaml
Parameters:
  LatestAmiId:
    Description: Fetching the latest AMI ID for Amazon Linux
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
  InstanceType:
    Description: Select the type of the EC2 instance.
    Type: String
    AllowedValues:
      - t2.nano
      - t2.micro
      - t2.small
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
  Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: InstanceImport
```

4. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
5. From **Create stack**, choose **With new resources (standard)**.
6. From **Specify template**, choose **Upload a template file**. Upload the `resource-import-challenge.yaml` template and choose **Next**.
7. Enter a **Stack name**. For example, specify `resource-import-challenge`. Specify `t2.nano` for `InstanceType`. Choose **Next.**
8. In **Configure Stack Options**, choose **Next**.
9. In the next page, choose **Create Stack**.
10. After the stack is created, select the `resource-import-challenge` stack, and choose **Resources**. Take a note of the **Physical ID** for `Instance`, that uses this format: `i-12345abcd6789`.

Let’s now reproduce the human error by changing the instance type outside the management purview of your stack. Choose to [Change the instance type of existing EBS-backed instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html#change-instance-type-of-ebs-backed-instance) by following the steps below:

1. Navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/).
2. Locate the **Instances** section, select the instance with the name `InstanceImport`, and choose **Instance state**, **Stop instance**.
3. For the same instance, once you see the instance has reached the **Stopped** state, choose **Actions**, **Instance settings**, **Change instance type.**
4. Choose `t2.micro`, and then choose **Apply**.
5. Select again the `InstanceImport` instance, and choose **Instance state**, **Start instance**.


You initially created an Amazon EC2 instance with your stack. To reproduce the human error, you updated the instance out of band (not using CloudFormation), instead of using the [instance type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) property in your template, and updating your stack next.

::alert[When you change the instance type, this causes [some interruptions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-some-interrupt), such as the instance will stop and start again. For more information on resizing instances, see [Change the instance type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html).]{type="info"}

Your task is to reconcile the instance type value, that in your stack is currently set to `t2.nano`, with the new, actual instance configuration setting - `t2.micro` - made out of band, without making additional changes to the `InstanceType` property when you update the stack.

::expand[* Think about a way to use concepts you learned in Lab part 3.]{header="Need a hint?"}

:::expand{header="Want to see the solution?"}
1. Update the `resource-import-challenge.yaml` template: add a `DeletionPolicy` attribute, with a value of `Retain`, to the `Instance` resource. Save the file.

2. Update the stack by using the updated `resource-import-challenge.yaml` template without changing parameter values.
3. Once you updated the stack, and the `DeletionPolicy` attribute is set to `Retain` for your instance, remove the instance resource definition and relevant parameters in the `Parameters` section from the template: in this example, remove the `Parameters` section itself, as you do not have any more parameters to describe. To do so, remove the two following code blocks from the `resource-import-challenge.yaml` template:

```yaml
Parameters:
  LatestAmiId:
    Description: Fetching the latest AMI ID for Amazon Linux
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
  InstanceType:
    Description: Select the type of the EC2 instance.
    Type: String
    AllowedValues:
      - t2.nano
      - t2.micro
      - t2.small
```

```yaml
  Instance:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: InstanceImport
```

4. Save the template file. Update the stack again with the updated `resource-import-challenge.yaml` template, which now has no parameters section, and no instance resource definition. This action will remove the instance from the stack, but will not delete it because you previously described and applied the `DeletionPolicy` attribute set to `Retain`.
5. After this stack update, add the two removed code blocks from Step 3 back to the `resource-import-challenge.yaml` template, and save it.
6. Select the stack named `resource-import-challenge` and, from **Stack actions**, choose **Import resources into stack**.
7. Read the **Import Overview** and choose **Next**.
8. From **Specify template**, choose **Upload a template file**. Upload your updated `resource-import-challenge.yaml` template, and choose **Next**.
9. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the instance's **Physical ID**, that you noted earlier as part of this challenge.
10. Select `t2.micro` for the instance type parameter: here you are matching the actual instance type configuration setting, that is `t2.micro`.
11. In the next page, choose **Import resources**.
:::



You can find the template for the solution in the `code/solutions/resource-importing/resource-import-challenge-solution.yaml` example template.

Great work! You have now learned how to match the CloudFormation stack configuration with the actual configuration on the resource when there is an out-of-band change.

**Resource importing use cases**

1. You previously created an AWS resource (for example, an Amazon S3 bucket) with e.g., the AWS Management Console or the AWS CLI, and you would like to manage your resource using CloudFormation.
2. You want to reorganize resources by lifecycle and ownership into single stacks for easier management (for example, security group resources, etc.).
3. You want to nest an existing stack within an existing one. For more information, see [Nesting an existing stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-nested-stacks.html).
4. You want to match the CloudFormation configuration for a resource which was updated out of band.

### Cleanup

Choose to follow cleanup steps shown next to clean up resources you created with this lab:

1. Make sure you are in the directory: `code/workspace/resource-importing`
2. Update the `resource-importing.yaml` template file to remove the `DeletionPolicy: Retain` line from the `SNSTopic2` resource definition, and save the template.
3. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
4. Select the stack named `resource-importing` and choose **Update**.
5. Choose **Replace current template** and upload the `resource-importing.yaml` template. Choose **Next**.
6. In the parameters section, choose to accept the existing parameter value. Choose **Next**.
7. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
8. Choose **Update stack** in the next page.
9. After your stack update is complete, select the `resource-importing` stack and choose **Delete**.
10. Repeat steps 2-9 above for the stack: `moving-resources`, by updating the `moving-resources.yaml` template to remove the `DeletionPolicy: Retain` line from the `SNSTopic1` resource definition, updating the stack, and deleting it after successful update. Choose to accept the existing parameter value when you update the stack.
11. Repeat steps (2-9) above for stack: `resource-import-challenge` by updating the `resource-import-challenge.yaml` template to remove the `DeletionPolicy: Retain` line from the `Instance` resource definition, updating the stack, and deleting it after successful update.  Choose to accept existing parameter values when you update the stack.

### Conclusion

Great job! You have now learned how to import resources, as well as use cases and considerations to make when you import resources.
