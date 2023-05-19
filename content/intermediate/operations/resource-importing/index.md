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
* Navigate to `code/workspace/resource-importing` directory.
* Open the `resource-importing.yaml` file.
* Update the content of the template as you follow along steps on this lab.

### Lab Part 1

In this lab, you will first create an [Amazon Simple Notification Service](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) (Amazon SNS) topic with the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and you will then import the topic in a new CloudFormation stack you will create. Next, you will create a second topic with the Amazon SNS Console, and you will import it as well into your existing stack.

To get started, follow steps shown next:

1. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and choose **Topics**. Next, choose **Create topic**.
2. Choose `Standard` for the topic **Type**.
3. Specify a **Name** for your topic, such as `Topic1`.
4. When ready, choose **Create topic**.
5. When your topic is successfully created, take a note of its [**Amazon Resource Name (ARN)**](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) under the **Details** section for `Topic1`: you will use this ARN value later in this lab. For reference, an example ARN pattern for an Amazon SNS topic is `arn:aws:sns:us-east-1:123456789012:MyTopic`.

Let’s now use the resource import functionality to import your newly created topic into a new stack you will create. For this, you will use a CloudFormation template where you describe your existing topic with the `AWS::SNS::Topic` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html) as follows:

* You will specify, for the `TopicName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#cfn-sns-topic-topicname), the name of your existing topic, that is `Topic1`. Choose to pass this value with a template [parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html), that you will call `Topic1Name`. You will then reference the value for this parameter with the `Ref` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html).
* Each resource you import must have a `DeletionPolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) described for it: specify this attribute for your topic, and specify `Retain` for the attribute value. When you use a `Retain` value for the `DeletionPolicy` attribute, you indicate to retain the resource when you remove it from the stack, or when you delete the stack.
* Copy the code below, append it to the `resource-importing.yaml` file, and save the file:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::


::alert[All resources you import must have a [DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) attribute set in your template for the import operation to succeed. For more information, see [Considerations during an import operation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-considerations).]{type="info"}

In this next step, you will use the AWS CloudFormation to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-new-stack.html) using the `resource-importing.yaml` template:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Create a text file to describe the resources for an `IMPORT` operation.
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch resources-import.txt
:::
1. Copy and Paste the below code to the `resources-import` text file, Save it. For the [**ResourceIdentifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), update the value for the topic ARN you noted after you created `Topic1`.
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic1",
    "ResourceIdentifier": {
      "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic1"
    }
  }
]
:::
1. Let's create a change set of type `IMPORT` to import the resources from the template by using the following AWS CLI command. The template requires you to provide a value for `Topic1Name` input parameter. For Example, Specify a name for the stack `cfn-workshop-resource-importing` and for the change set `cfn-workshop-resource-import-change-set` and provide the parameter value for `Topic1Name` to `Topic1`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1
:::
1. Review the change set to make sure the correct resources are imported.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. Execute the change set to import the resources.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. Wait until the `IMPORT` operation is complete, by using the [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-importing
:::
1. Verify import complete by using the [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
:::
1. If the `describe-stacks` command was successfully sent, CloudFormation will return the stack information with `"StackStatus": "IMPORT_COMPLETE"` on line 17.
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "StackName": "cfn-workshop-resource-importing",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/3f86b48d-a0bf-434b-96de-2ec316a04134",
      "Description": "AWS CloudFormation workshop - Resource Importing.",
      "Parameters": [
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T01:00:50.284000+00:00",
      "LastUpdatedTime": "2023-05-17T01:05:31.414000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
          "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With existing resources (import resources)**.
1. Read the **What you'll need** information, and choose **Next**.
1. From **Specify template**, choose **Upload a template file**. Upload the `resource-importing.yaml` template, and choose **Next**.
1. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the value for the topic ARN you noted after you created `Topic1`, choose **Next**
1. Enter a **Stack name**. For example, specify `cfn-workshop-resource-importing`. Make sure you specify `Topic1` for the `Topic1Name` parameter value, and choose **Next**
1. In the next page, choose **Import resources**.

Your stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.

For more information, see also [Import an existing resource into a stack using the AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html#resource-import-existing-stack-cli).
::::
:::::

Congratulations! You imported a resource, that you created earlier with the Amazon SNS Console, into a new stack!

### Lab Part 2

In this lab, you will learn how to import a resource into an existing stack. To get started, follow steps below:

1. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/) to create a second topic. Follow steps you used on lab part 1, and specify **Topic2** for the name of your new topic.
1. When your topic is successfully created, take a note of its [**Amazon Resource Name (ARN)**](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) under the **Details** section for `Topic2`; you will use this information later on in this lab (example ARN pattern: `arn:aws:sns:us-east-1:123456789012:MyTopic`).
1. Copy the example below, and **append it to the `Parameters` section** of the `resource-importing.yaml` template, that you used for the previous lab:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=17}
Topic2Name:
  Type: String
  Default: Topic2
  Description: Name of the second Amazon SNS topic you created with the Amazon SNS console.
:::
1. Next, copy the example below, and **append it to the `Resources` section** of the `resource-importing.yaml` template. Save the template file when done.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=29}
SNSTopic2:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic2Name
:::
1. The `resource-importing.yaml` template you just updated will now include 2 parameters (`Topic1Name` and `Topic2Name`), and 2 resources (`SNSTopic1` and `SNSTopic2`). Let’s import the new topic into the existing stack!
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. Copy the below code and update it to the `resource-import` text file. For the [**ResourceIdentifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), update the value for the topic ARN you noted after you created `Topic2`.
   :::code{language=json showLineNumbers=false showCopyAction=true}
   [
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic2",
    "ResourceIdentifier": {
    "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic2"
    }
  }
]
   :::
   1. Let's create a change set of type `IMPORT` to import the resources from the template by using the following AWS CLI command. Specify the  parameter values for `Topic1Name` to `Topic1` and  for `Topic2Name` to `Topic2` as described below.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1 ParameterKey=Topic2Name,ParameterValue=Topic2
   :::
   1. Review the change set to make sure the correct resources are imported.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
   :::
   1. Execute the change set to import the resources.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
   :::
   1. Wait until the `IMPORT` operation is complete, by using the [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) AWS CLI command.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-importing
   :::
   1. Verify import complete by using the [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) AWS CLI command.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
   :::
   1. If the `describe-stacks` command was successfully sent, CloudFormation will return the stack information with `"StackStatus": "IMPORT_COMPLETE"` on line 21.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21}
   {
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "StackName": "cfn-workshop-resource-importing",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/b45266b6-01c9-4c23-99d6-d65731fc575c",
      "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
      "Parameters": [
        {
          "ParameterKey": "Topic2Name",
          "ParameterValue": "Topic2"
        },
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T01:00:50.284000+00:00",
      "LastUpdatedTime": "2023-05-17T01:35:38.408000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
          "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
   :::
   ::::
   ::::tab{id="local" label="Local development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
   1. Select the stack named `cfn-workshop-resource-importing` and, from **Stack actions**, choose **Import resources into stack**.
   1. Read the **What you'll need** information and choose **Next**.
   1. From **Specify template**, choose **Upload a template file**. Upload the `resource-importing.yaml` template you updated with this lab part, and choose **Next**.
   1. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the topic ARN value you noted after you created `Topic2`, and choose **Next**.
   1. For parameters, make sure you specify `Topic1` for `Topic1Name`, and `Topic2` for `Topic2Name`. Choose **Next**.
   1. In the next page, choose **Import resources**.
   Your stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.
   ::::
   :::::

Congratulations! You have learned how to import a resource into an existing stack! For more information, see also [Import an existing resource into a stack using the AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html#resource-import-existing-stack-cli).

### Lab Part 3

In this part of the lab, you will learn how to [move resources between stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/refactor-stacks.html). You will remove the `SNSTopic1` resource from the `cfn-workshop-resource-importing` stack, and you will import it into a new one; note that since you specified `Retain` for the `DeletionPolicy` attribute of `SNSTopic1`, the `SNSTopic1` resource will not be deleted when you will update the stack. Let's get started:

1. Remove the code below from the **Parameters** section of the `resource-importing.yaml` template you used for lab part 2:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=12}
Topic1Name:
  Type: String
  Default: Topic1
  Description: Name of the first Amazon SNS topic you created with the Amazon SNS console.
:::
2. Remove the code below from the **Resources** section of the `resource-importing.yaml` template, and save the template file.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=23}
SNSTopic1:
  DeletionPolicy: Retain
  Type: AWS::SNS::Topic
  Properties:
    TopicName: !Ref Topic1Name
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's create the change set of type `UPDATE` to remove the resource `SNSTopic1` from the stack by using the following AWS CLI command. Provide a name for the stack as `cfn-workshop-resource-importing` and for the change set name use `cfn-workshop-resource-import-change-set`, Specify the parameter values for `Topic2Name` to `Topic2`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set \
--change-set-type UPDATE \
--template-body file://resource-importing.yaml \
--parameters ParameterKey=Topic2Name,ParameterValue=Topic2
:::
1. Review the change set to make sure the correct resources are removed.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. Execute the change set to import the resources.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-importing \
--change-set-name cfn-workshop-resource-import-change-set
:::
1. Wait until the `UPDATE` operation is complete, by using the [wait stack-update-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-update-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-resource-importing
:::
1. Verify update complete by using the [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-resource-importing
:::
1. If the `describe-stacks` command was successfully sent, CloudFormation will return the stack information with `"StackStatus": "UPDATE_COMPLETE"` on line 17.
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
   "StackName": "cfn-workshop-resource-importing",
   "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-resource-import-change-set/11e65a07-b12b-4430-ba7a-d06edf53d2d5",
   "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
   "Parameters": [
     {
       "ParameterKey": "Topic2Name",
       "ParameterValue": "Topic2"
     }
   ],
   "CreationTime": "2023-05-17T01:00:50.284000+00:00",
   "LastUpdatedTime": "2023-05-17T02:00:46.392000+00:00",
   "RollbackConfiguration": {},
   "StackStatus": "UPDATE_COMPLETE",
   "DisableRollback": false,
   "NotificationARNs": [],
   "Tags": [],
   "EnableTerminationProtection": false,
   "DriftInformation": {
     "StackDriftStatus": "NOT_CHECKED"
   }
    }
  ]
}
:::
1. Verify update complete by using the [describe-stack-resources](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resources.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources --stack-name cfn-workshop-resource-importing
:::
1. If the `describe-stack-resources` command was successfully sent, CloudFormation will return the stack resource information with only `SNSTopic2`.
:::code{language=json showLineNumbers=true showCopyAction=false}
{
  "StackResources": [
    {
      "StackName": "cfn-workshop-resource-importing",
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-importing/43d74040-f44e-11ed-9921-0a4da8431f6d",
      "LogicalResourceId": "SNSTopic2",
      "PhysicalResourceId": "arn:aws:sns:us-east-1:123456789012:Topic2a.fifo",
      "ResourceType": "AWS::SNS::Topic",
      "Timestamp": "2023-05-17T01:35:50.535000+00:00",
      "ResourceStatus": "UPDATE_COMPLETE",
      "DriftInformation": {
        "StackResourceDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Select the stack named `cfn-workshop-resource-importing` and choose **Update**.
1. Choose **Replace current template** and upload the `resource-importing.yaml` template. Choose **Next**.
1. In the parameters section, choose to accept the parameter value for `Topic2Name` as `Topic2`. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
1. Choose **Submit** in the next page.
1. To confirm the removal of `SNSTopic1` resource from the stack, select the `cfn-workshop-resource-importing` stack and choose **Resources**. You should see only one resource: `SNSTopic2`.
::::
:::::
Choose to import the `SNSTopic1` resource into a new stack:
1. Make sure you are in the `code/workspace/resource-importing` directory.
2. Open the `moving-resources.yaml` template file with your favorite text editor.
3. Append the example below to the `moving-resources.yaml` template, and save it.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Copy the code below and replace it to the `resources-import.txt` file.
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::SNS::Topic",
    "LogicalResourceId":"SNSTopic1",
    "ResourceIdentifier": {
      "TopicArn":"arn:aws:sns:us-east-1:123456789012:Topic1"
    }
  }
]
:::
1. For the [**ResourceIdentifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), update the value for the topic ARN you noted after you created `Topic1` from **Lab1**.
1. Let's create a change set of type `IMPORT` to import the resources from the template by using the following AWS CLI command. Provide `cfn-workshop-moving-resources` as name of the stack and for the change set use `moving-resource-change-set`, Specify `Topic1` as parameter value for `Topic1Name`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set \
--change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://moving-resources.yaml \
--parameters ParameterKey=Topic1Name,ParameterValue=Topic1
:::
1. Review the change set to make sure the correct resources are imported.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set
:::
1. Execute the change set to import the resources.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-moving-resources \
--change-set-name cfn-workshop-moving-resources-change-set
:::
1. Wait until the `IMPORT` operation is complete, by using the [wait stack-import-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-import-complete.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-moving-resources
:::
1. Verify import complete by using the [describe-stacks](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stacks --stack-name cfn-workshop-moving-resources
:::
1. If the `describe-stacks` command was successfully sent, CloudFormation will return the stack information with `"StackStatus": "IMPORT_COMPLETE"` on line 17.
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=17}
{
  "Stacks": [
    {
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-moving-resources/70f207d0-f459-11ed-9c39-123ae332d1a1",
      "StackName": "cfn-workshop-moving-resources",
      "ChangeSetId": "arn:aws:cloudformation:us-east-1:123456789012:changeSet/cfn-workshop-moving-resources-change-set/695b51cd-6d16-49e8-99f7-7b93a932f1fe",
      "Description": "AWS CloudFormation workshop - Resource Importing (uksb-1q9p31idr).",
      "Parameters": [
        {
          "ParameterKey": "Topic1Name",
          "ParameterValue": "Topic1"
        }
      ],
      "CreationTime": "2023-05-17T02:20:50.451000+00:00",
      "LastUpdatedTime": "2023-05-17T02:21:03.424000+00:00",
      "RollbackConfiguration": {},
      "StackStatus": "IMPORT_COMPLETE",
      "DisableRollback": false,
      "NotificationARNs": [],
      "Tags": [],
      "EnableTerminationProtection": false,
      "DriftInformation": {
        "StackDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
1. Verify update complete by using the [describe-stack-resources](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resources.html) AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources --stack-name cfn-workshop-moving-resources
:::
1. If the `describe-stack-resources` command was successfully sent, CloudFormation will return the stack resource information with `SNSTopic1`.
:::code{language=json showLineNumbers=true showCopyAction=false}
{
  "StackResources": [
    {
      "StackName": "cfn-workshop-moving-resources",
      "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-moving-resources/70f207d0-f459-11ed-9c39-123ae332d1a1",
      "LogicalResourceId": "SNSTopic1",
      "PhysicalResourceId": "arn:aws:sns:us-east-1:123456789012:Topic1.fifo",
      "ResourceType": "AWS::SNS::Topic",
      "Timestamp": "2023-05-17T02:21:15.205000+00:00",
      "ResourceStatus": "UPDATE_COMPLETE",
      "DriftInformation": {
        "StackResourceDriftStatus": "NOT_CHECKED"
      }
    }
  ]
}
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With existing resources (import resources)**.
1. Read the **Import Overview** and choose **Next**.
1. From **Specify template**, choose **Upload a template file**. Upload the `moving-resources.yaml` template and choose **Next.**
1. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the topic ARN value you noted after you created `Topic1`, and choose **Next**
1. Enter a **Stack name**. For example, specify `cfn-workshop-moving-resources`. Make sure you specify `Topic1` for the `Topic1Name` parameter.
1. Choose **Import Resources** in the next page.

The stack status will show `IMPORT_COMPLETE` once your Amazon SNS topic is successfully imported into your stack.
::::
:::::

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

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
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
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's **Create Stack** by using the code below. For example, Specify **Stack Name** as `cfn-workshop-resource-import-challenge` and `t2.nano` for `InstanceType` parameter.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.nano
:::
1. Wait until the stack status to `CREATE_COMPLETE` by using the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-resource-import-challenge
:::
::::
::::tab{id="LocalDevelopment" label="LocalDevelopment"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With new resources (standard)**.
1. From **Specify template**, choose **Upload a template file**. Upload the `resource-import-challenge.yaml` template and choose **Next**.
1. Enter a **Stack name**. For example, specify `cfn-workshop-resource-import-challenge`. Specify `t2.nano` for `InstanceType`. Choose **Next.**
1. In **Configure Stack Options**, choose **Next**.
1. In the next page, choose **Submit**.
::::
:::::
After the stack is created, select the `cfn-workshop-resource-import-challenge` stack, and choose **Resources**. Take a note of the **Physical ID** for `Instance`, that uses this format: `i-12345abcd6789`.

Let’s now reproduce the human error by changing the instance type outside the management purview of your stack. Choose to [Change the instance type of existing EBS-backed instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html#change-instance-type-of-ebs-backed-instance) by following the steps below:

1. Navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/).
1. Locate the **Instances** section, select the instance with the name `InstanceImport`, and choose **Instance state**, **Stop instance**.
1. For the same instance, once you see the instance has reached the **Stopped** state, choose **Actions**, **Instance settings**, **Change instance type.**
1. Choose `t2.micro`, and then choose **Apply**.
1. Select again the `InstanceImport` instance, and choose **Instance state**, **Start instance**.

You initially created an Amazon EC2 instance with your stack. To reproduce the human error, you updated the instance out of band (not using CloudFormation), instead of using the [instance type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) property in your template, and updating your stack next.

:::alert{type="info"}
When you change the instance type, this causes [some interruptions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-some-interrupt), such as the instance will stop and start again. For more information on resizing instances, see [Change the instance type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html).
:::
Your task is to reconcile the instance type value, that in your stack is currently set to `t2.nano`, with the new, actual instance configuration setting - `t2.micro` - made out of band, without making additional changes to the `InstanceType` property when you update the stack.

:::expand{header="Need a hint?"}
Think about a way to use concepts you learned in Lab part 3.
:::

:::expand{header="Want to see the solution?"}
1. Update the `resource-import-challenge.yaml` template: add a `DeletionPolicy` attribute, with a value of `Retain`, to the `Instance` resource. Save the file.
1. Update the stack by using the updated `resource-import-challenge.yaml` template without changing parameter values.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.nano
:::
1. Once you updated the stack, and the `DeletionPolicy` attribute is set to `Retain` for your instance, remove the instance resource definition and relevant parameters in the `Parameters` section from the template: in this example, remove the `Parameters` section itself, as you do not have any more parameters to describe. To do so, remove the two following code blocks from the `resource-import-challenge.yaml` template:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11 highlightLines=11-15,17-23}
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
:::
    :::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=30 highlightLines=31}
    Instance:
      DeletionPolicy: Retain
      Type: AWS::EC2::Instance
      Properties:
        ImageId: !Ref LatestAmiId
        InstanceType: !Ref InstanceType
        Tags:
          - Key: Name
            Value: InstanceImport
    :::
1. Save the template file. Update the stack again with the updated `resource-import-challenge.yaml` template, which now has no parameters section, and no instance resource definition. This action will remove the instance from the stack, but will not delete it because you previously described and applied the `DeletionPolicy` attribute set to `Retain`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml
:::
1. After this stack update, add the two removed code blocks from Step 3 back to the `resource-import-challenge.yaml` template, and save it.
1. Let's **Import the Resources to  the Stack**
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. Copy the code below and replace the `resources-import.txt` For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the instance's **Physical ID**, that you noted earlier as part of this challenge.
   :::code{language=json showLineNumbers=false showCopyAction=true}
   [
  {
    "ResourceType":"AWS::EC2::Instance",
    "LogicalResourceId":"Instance",
    "ResourceIdentifier": {
      "InstanceId":"i-12345abcd6789"
    }
  }
]
   :::
   1. Update the `cfn-workshop-resource-import-challenge` Stack to **Import resources** by using the following code. Specify `t2.micro` for the `InstanceType` parameter.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-change-set \
--stack-name cfn-workshop-resource-import-challenge \
--change-set-name import-challenge --change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.micro
   :::
   1. Execute the change set by using the following code
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation execute-change-set \
--stack-name cfn-workshop-resource-import-challenge \
--change-set-name import-challenge
   :::
   1. Wait until the `IMPORT` operation is complete by using the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-resource-import-challenge
   :::
   ::::
   ::::tab{id="LocalDevelopment" label="Local development"}
   1. Select the stack named `cfn-workshop-resource-import-challenge` and, from **Stack actions**, choose **Import resources into stack**.
   1. Read the **What you'll need** information and choose **Next**.
   1. From **Specify template**, choose **Upload a template file**. Upload your updated `resource-import-challenge.yaml` template, and choose **Next**.
   1. For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the instance's **Physical ID**, that you noted earlier as part of this challenge, and choose **Next**
   1. Select `t2.micro` for the instance type parameter: here you are matching the actual instance type configuration setting, that is `t2.micro`, and choose **Next**
   1. In the next page, choose **Import resources**.
   ::::
   :::::

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
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. Update the **Stack** by using the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-resource-importing \
--template-body file://resource-importing.yaml
   :::
   1. Wait until the `UPDATE` operation is complete by using the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-resource-importing
   :::
   1. Wait until the `UPDATE` operation is complete by using the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-resource-importing
   :::
   1. Delete the stack by running the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation delete-stack \
 --stack-name cfn-workshop-resource-importing
   :::
   1. Repeat steps (1-3) above for the stack: `cfn-workshop-moving-resources`, by updating the `moving-resources.yaml` template to remove the `DeletionPolicy: Retain` line from the `SNSTopic1` resource definition, updating the stack, and deleting it after successful update. Choose to accept the existing parameter value when you update the stack.
   1. Update the `resource-import-challenge.yaml` template to remove the `DeletionPolicy: Retain` line from the `Instance` resource definition. Now update the stack by running the following AWS CLI command
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-resource-import-challenge \
--template-body file://resource-import-challenge.yaml \
--parameters ParameterKey=InstanceType,ParameterValue=t2.micro
   :::
   1. Repeat steps (2-3) above for stack: `cfn-workshop-resource-import-challenge` to delete the stack.
   ::::
   ::::tab{id="LocalDevelopment" label="Local development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
   1. Select the stack named `cfn-workshop-resource-importing` and choose **Update**.
   1. Choose **Replace current template** and **upload a template file**. Upload the `resource-importing.yaml` template. Choose **Next**.
   1. In the parameters section, choose to accept the existing parameter value. Choose **Next**.
   1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
   1. Choose **Submit** in the next page.
   1. After your stack update is complete, select the `cfn-workshop-resource-importing` stack and choose **Delete**.
   1. Repeat steps (2-9) above for the stack: `cfn-workshop-moving-resources`, by updating the `moving-resources.yaml` template to remove the `DeletionPolicy: Retain` line from the `SNSTopic1` resource definition, updating the stack, and deleting it after successful update. Choose to accept the existing parameter value when you update the stack.
   1. Repeat steps (2-9) above for stack: `cfn-workshop-resource-import-challenge` by updating the `resource-import-challenge.yaml` template to remove the `DeletionPolicy: Retain` line from the `Instance` resource definition, updating the stack, and deleting it after successful update.  Choose to accept existing parameter values when you update the stack.
   ::::
   :::::

---

### Conclusion

Great job! You have now learned how to import resources, as well as use cases and considerations to make when you import resources.
