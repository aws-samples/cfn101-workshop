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

```yaml
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
```

In this next step, you will use the AWS CloudFormation Console to create a stack using the `stack-policy-lab.yaml` template file. Follow steps shown next:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Specify template**, choose **Upload a template file**. Upload the `stack-policy-lab.yaml` template, and choose **Next**.
4. Enter a Stack name. For example, specify `stack-policy-lab`. In the parameters section, choose to accept the parameter value for `SNSTopicTagValue` as `Topic-Tag-1`. Choose **Next**.
5. In **Configure Stack Options** page; under **Stack policy**, choose **Enter stack policy** and paste the following code for the stack policy. Under **Stack creation options**, choose **Enabled** for **Termination protection**, and choose **Next**.

```json
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
```

6. In the next page, choose **Create stack**.

::alert[When you apply a stack policy to a stack, all the resources in that stack are protected by default. Hence, you will need to specify an explicit `Allow` statement in your stack policy to allow updates to all other resources.]

The stack policy you configured above for your `stack-policy-lab` stack denies updates to the resource whose [Logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) is `SNSTopic`.

Let’s now test the stack policy you applied, by updating the stack you created!


1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `stack-policy-lab`, and choose **Update**.
3. In the next page, choose to accept **Use current template**. Choose **Next**.
4. In the parameters section, update the value of `SNSTopicTagValue` from `Topic-Tag-1` to `Topic-Tag-2`. Choose **Next**.
5. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
6. Choose **Update stack** in the next page.

The stack update will fail. When looking in the **Events** pane for your stack, you will see the `Action denied by stack policy` error, for the resource whose [Logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) is `SNSTopic`.

Let’s now test the termination protection feature, that you enabled on your `stack-policy-lab` stack:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `stack-policy-lab`, and choose **Delete**.

You will observe a message window informing you that **Termination protection** is enabled on the stack, and you will need to disable it before deleting the stack.

Congratulations! You have now learned how to define update operations for resources in a CloudFormation stack, and prevent the stack from deletion. For information on how to apply a stack policy using the [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), see [Setting a stack policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html#protect-stack-resources-protecting). To enable or disable termination protection using the AWS Command Line Interface, use the [update-termination-protection](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/update-termination-protection.html) command.


### **Lab Part 2 - DeletionPolicy**

[DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) is a CloudFormation resource attribute you configure for resources in your stack to preserve - or backup, in some cases - such resources when you e.g., remove the resource from the stack, or when you delete the stack. By default, CloudFormation will delete the resource on stack deletion if no `DeletionPolicy` is configured for the resource, or if its value is set to `Delete`.

In this lab, you will first create a CloudFormation stack with an Amazon SNS topic resource, and set the `DeletionPolicy` attribute value to `Retain` to preserve the resource. You will then delete the stack, and check if the resource still exists.

To get started, follow steps shown next:

* Make sure you are in the `code/workspace/stack-policy-and-prevention-controls` directory.
* Copy the code below, append it to the `deletion-policy-lab.yaml` file, and save the file:

```yaml
Resources:
  SNSTopic:
    DeletionPolicy: Retain
    Type: AWS::SNS::Topic
    Properties:
      TopicName: Topic-2
```

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Specify template**, choose **Upload a template file**. Upload the `deletion-policy-lab.yaml` template, and choose **Next**.
4. Enter a Stack name. For example, specify `deletion-policy-lab`. Choose **Next**.
5. Choose to accept default values on the **Configure stack options page**; scroll to the bottom of the page, and choose **Next**.
6. In the next page, choose **Create stack**.

When you use a `Retain` value for the `DeletionPolicy` attribute, you indicate to retain the resource when you remove it from the stack, or when you delete the stack.

After the stack is created, let’s now test the `DeletionPolicy` you set on the resource:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `deletion-policy-lab`, and choose **Delete**. Next, choose **Delete stack** to confirm.

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

:::expand{header="Want to see the solution?"}

Create a stack policy that, for `"Effect" : "Deny"`, contains `Action`, `Resource`, and `Condition` blocks specified as shown next:

```json
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
```

:::

Great work! You have now learned how to create a stack policy to deny updates for a given resource type.

### Cleanup

Choose to follow steps shown next to clean up resources you created with this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Select the stack named `stack-policy-lab` and choose **Delete**.
3. In the message window, select **Edit termination protection**, and select **Disabled** for **Termination protection**. Choose **Save**.
4. Select the stack named `stack-policy-lab` and choose **Delete**, and then choose **Delete stack** to confirm.
5. Navigate to the [Amazon SNS Console](https://console.aws.amazon.com/sns/), and choose **Topics**. Next, select the topic `Topic-2`, and choose **Delete**. In the message pane, enter `delete me`, and choose **Delete** to confirm.

* * *

### Conclusion

Congratulations! You have learned how to prevent unintentional updates, protect a stack from deletion, and preserve resources in case of an unintentional stack deletion.
