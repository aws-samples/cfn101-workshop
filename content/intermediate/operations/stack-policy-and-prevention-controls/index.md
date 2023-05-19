---
title: "Stack policy and prevention controls"
weight: 300
---

### Overview

When you describe your infrastructure with code using [AWS CloudFormation](https://aws.amazon.com/cloudformation/), you have the choice of implementing policies to prevent unintentional operations. For example, you can choose to use CloudFormation features that include [Stack Policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html), [Termination Protection](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html), [DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html), and [UpdateReplacePolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html) to prevent accidental stack terminations, updates and deletions of resources you describe in your stack.

### Topics Covered

By the end of this lab, you will be able to:

* Learn how to set a [Stack Policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) on a CloudFormation stack to determine which update actions you can perform on resources you manage with your stack.
* Learn how to prevent stack deletion by enabling [Termination Protection](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html).
* Learn how to use the [DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) attribute to retain - or backup, in some cases - resources that you describe in your stack when you remove resources from the stack, or when you delete the stack.

### Start Lab

* Change directory to `code/workspace/stack-policy-and-prevention-controls`.
* Open the `stack-policy-lab.yaml` file.
* Update the content of the template as you follow along steps on this lab.

### **Lab Part 1 - Stack Policy and Termination Protection**

[Stack policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) is a JSON-formatted document you set up on a stack to define and control update operations for your stack resources. [Termination Protection](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html) is a stack option that you enable on the stack to protect your stack from deletion.

In this lab, you will first create an [Amazon Simple Notification Service](https://aws.amazon.com/sns/) (Amazon SNS) [topic](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) in a stack: you will set up a stack policy to deny updates to the topic, and enable termination protection for your stack. Next, you will update the stack you created to update the topic, and test the stack policy you configured for the stack resource. Later, you will delete the stack to test the termination protection setting you enabled.

To get started, follow steps shown next:

* Copy the code below, append it to the `stack-policy-lab.yaml` file, and save the file:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
Parameters:
  SNSTopicTagValue:
    Description: Tag value for your Amazon SNS topic
    Type: String
    Default: Topic-Tag-1
    MinLength: 1
    MaxLength: 256

Resources:
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: Topic-1
      Tags:
        - Key: TagSNS
          Value: !Ref SNSTopicTagValue
:::

In this next step, you will use the AWS CloudFormation to create a stack using the `stack-policy-lab.yaml` template file. Follow steps shown next:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Create a stack by following these steps:
1. In the **Cloud9 terminal** navigate to `code/workspace/stack-policy-and-prevention-controls`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/stack-policy-and-prevention-controls
:::
1. Create a new JSON file for the stack policy.
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch policy-body.json
:::
1. Open this file in Cloud9 editor and paste in the following JSON code:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:Modify",
      "Resource" : "LogicalResourceId/SNSTopic"
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
1. The template requires you to provide a value for the `SNSTopicTagValue` input parameter. For example use `Topic-Tag-1`
1. Let's create the stack from the template using the following command (the example uses `us-east-1` for the AWS region, change this value as needed):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--region us-east-1 \
--stack-name cfn-workshop-stack-policy \
--template-body file://stack-policy-lab.yaml \
--stack-policy-body file://policy-body.json \
--parameters ParameterKey=SNSTopicTagValue,ParameterValue=Topic-Tag-1 \
--enable-termination-protection
:::
1. CloudFormation returns the following output:
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-stack-policy/330b0120-1771-11e4-af37-50ba1b98bea6"
:::
1. Wait until the `cfn-workshop-stack-policy` stack is created, by using the CloudFormation console or the [stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) wait command of the AWS CLI
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-stack-policy
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With new resources (standard)**.
1. From **Specify template**, choose **Upload a template file**. Upload the `stack-policy-lab.yaml` template, and choose **Next**.
1. Enter a Stack name. For example, specify `cfn-workshop-stack-policy`. In the parameters section, choose to accept the parameter value for `SNSTopicTagValue` as `Topic-Tag-1`. Choose **Next**.
1. In **Configure Stack Options** page; under **Stack policy**, choose **Enter stack policy** and paste the following code for the stack policy. Under **Stack creation options**, choose **Activated** for **Termination protection**, and choose **Next**.
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:Modify",
      "Resource" : "LogicalResourceId/SNSTopic"
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
1. In the next page, choose **Submit**.
::::
:::::

::alert[When you apply a stack policy to a stack, all the resources in that stack are protected by default. Hence, you will need to specify an explicit `Allow` statement in your stack policy to allow updates to all other resources.]

The stack policy you configured above for your `cfn-workshop-stack-policy` stack denies updates to the resource whose [Logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) is `SNSTopic`.

Let’s now test the stack policy you applied, by updating the stack you created!

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Run the following command in the terminal to update the value of `SNSTopicTagValue` from `Topic-Tag-1` to `Topic-Tag-2`
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-stack-policy \
--use-previous-template \
--parameters ParameterKey=SNSTopicTagValue,ParameterValue=Topic-Tag-2
:::
CloudFormation returns the following output:
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId" : "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-stack-policy/330b0120-1771-11e4-af37-50ba1b98bea6"
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Select the stack named `cfn-workshop-stack-policy`, and choose **Update**.
1. In the next page, choose to accept **Use current template**. Choose **Next**.
1. In the parameters section, update the value of `SNSTopicTagValue` from `Topic-Tag-1` to `Topic-Tag-2`. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
1. Choose **Submit** on the next page.
::::
:::::

The stack update will fail. When looking in the **Events** pane for your stack in [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), you will see the `Action denied by stack policy` error, for the resource whose [Logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) is `SNSTopic`.

Let’s now test the termination protection feature, that you enabled on your `cfn-workshop-stack-policy` stack:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Select the stack named `cfn-workshop-stack-policy`, and choose **Delete**.

You will observe a message window informing you that **Termination protection** is enabled on the stack, and you will need to disable it before deleting the stack. Choose **Cancel**.

Congratulations! You have now learned how to define update operations for resources in a CloudFormation stack, and prevent the stack from deletion.

### **Lab Part 2 - DeletionPolicy**

[DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) is a CloudFormation resource attribute you configure for resources in your stack to preserve - or backup, in some cases - such resources when you e.g., remove the resource from the stack, or when you delete the stack. By default, CloudFormation will delete the resource on stack deletion if no `DeletionPolicy` is configured for the resource, or if its value is set to `Delete`.

In this lab, you will first create a CloudFormation stack with an Amazon SNS topic resource, and set the `DeletionPolicy` attribute value to `Retain` to preserve the resource. You will then delete the stack, and check if the resource still exists.

To get started, follow steps shown next:

* Make sure you are in the `code/workspace/stack-policy-and-prevention-controls` directory.
* Copy the code below, append it to the `deletion-policy-lab.yaml` file, and save the file:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=11}
Resources:
  SNSTopic:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: Topic-2
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Run the following command in the terminal to **Create Stack**:
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-stack-policy-deletion \
--template-body file://deletion-policy-lab.yaml
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With new resources (standard)**.
1. From **Specify template**, choose **Upload a template file**. Upload the `deletion-policy-lab.yaml` template, and choose **Next**.
1. Enter a Stack name. For example, specify `cfn-workshop-stack-policy-deletion`. Choose **Next**.
1. Choose to accept default values on the **Configure stack options page**; scroll to the bottom of the page, and choose **Next**.
1. In the next page, choose **Submit**.
::::
:::::
When you use a `Retain` value for the `DeletionPolicy` attribute, you indicate to retain the resource when you remove it from the stack, or when you delete the stack.

After the stack is created, let’s now test the `DeletionPolicy` you set on the resource:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `cfn-workshop-deletion-policy`, and choose **Delete**. Next, choose **Delete** to confirm.

In the stack events pane, you will observe the resource whose Logical ID is `SNSTopic` skipped the deletion. To confirm the resource was retained, follow the steps below:

1. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and choose **Topics**.
2. You will observe the topic `Topic-2` you created in the stack is still present, and was not deleted during stack deletion.

Congratulations! You have now learned how to define a `DeletionPolicy` resource attribute on a resource to preserve it during stack deletion. For more information, see [`DeletionPolicy` attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) and [`DeletionPolicy` options](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html#aws-attribute-deletionpolicy-options).

::alert[On stack updates, you can choose to use the `UpdateReplacePolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatereplacepolicy.html) to retain - or, in some cases, backup - a given resource when the resource is replaced during the stack update.]

### Challenge

You have learned how to create a stack policy to deny updates to a resource based on a [Logical Resource ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields). In this exercise, you are tasked with creating a stack policy that applies to resources of a specific type: your task is to create a stack policy to deny all update actions to the `AWS::RDS::DBInstance` resource type.

:::expand{header="Need a hint?"}
- Make use of the [Condition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html#stack-policy-reference) key to define `ResourceType`.
- How do you specify, in `Action`, your intent of including all update actions?
- Which value should you specify for `Resource`?
:::

::::expand{header="Want to see the solution?"}
Create a stack policy that, for `"Effect" : "Deny"`, contains `Action`, `Resource`, and `Condition` blocks specified as shown next:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*",
      "Condition" : {
        "StringEquals" : {
          "ResourceType" : ["AWS::RDS::DBInstance"]
        }
      }
    },
    {
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : "Update:*",
      "Resource" : "*"
    }
  ]
}
:::
::::

Great work! You have now learned how to create a stack policy to deny updates for a given resource type.

### Cleanup
Choose to follow steps shown next to clean up resources you created with this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `cfn-workshop-stack-policy` and choose **Delete**.
3. In the message window, select **Edit termination protection**, and select **Deactivated** for **Termination protection**. Choose **Save**.
4. Select the stack named `cfn-workshop-stack-policy` and choose **Delete**, and then choose **Delete** to confirm.
5. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and choose **Topics**. Next, select the topic `Topic-2`, and choose **Delete**. In the message pane, enter `delete me`, and choose **Delete** to confirm.

___

### Conclusion
Congratulations! You have learned how to prevent unintentional updates, protect a stack from deletion, and preserve resources in case of an unintentional stack deletion.
