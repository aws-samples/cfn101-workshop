---
title: 'Troubleshooting provisioning errors'
date: 2022-01-04T19:00:24Z
weight: 500
---

### Overview
As you iterate on the development of your CloudFormation template, you can test provisioning of resources described in your template by creating a CloudFormation [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html). If you specify incorrect property values for resource configurations in the template, by default the stack will roll back to the last-known stable state, and all stack resources will be rolled back. 

Let's take an example where you create a stack off of a template, in which you describe 10 resources. In this example, 9 resources are described as successfully created, and the creation of the tenth resource fails: by default, the stack will roll back, including the 9 resources that were successfully provisioned.

To speed up development cycles, you can choose to [preserve](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html) the state of resources that have been successfully provisioned as part of stack create and update operations, and of [change set](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) operations. When you choose to use this functionality, the stack rollback is paused to preserve the state of successfully provisioned resources, then you can start troubleshooting and fixing your configurations, and resume provisioning operations when you are ready.

### Topics Covered
By the end of this lab, you will be able to:

* Understand how to troubleshoot provisioning errors, whilst preserving the state resources successfully deployed
* Navigate to the [AWS resource and property types reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) to discover resource properties, and return values for a given resource

### Start Lab
You will use an example CloudFormation template, that contains an incorrect resource configuration, to create a new stack. You will choose to *preserve successfully provisioned resources* as part of *stack failure options* to preserve the state of an example `ExampleDeadLetterQueue` [Amazon SQS](https://aws.amazon.com/sqs/) queue resource, that will be successfully provisioned as part of the stack creation operation.

The creation operation for your stack will fail because another SQS queue described in your template, `ExampleSourceQueue`, has a configuration error. You will troubleshoot and fix the error in the template, and then you will choose to resume the stack creation operation with the template you updated.

To get started, follow steps shown next:
1. Change directory to the `code/workspace/troubleshooting-provisioning-errors` directory.
2. Open the `example_sqs_queues.yaml` CloudFormation template in your favorite text editor.
3. Familiarize with the configuration for sample SQS queues in the template; your intents, in this example, are to:
    1. create a *source* queue and a [*dead-letter* queue](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) (DLQ): you choose to have your `ExampleSourceQueue` target your `ExampleDeadLetterQueue` for messages that cannot be successfully processed.  In the template, you reference the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) for  `ExampleDeadLetterQueue` in the [redrive policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-redrive) for `ExampleSourceQueue`: your DLQ will then be created first, so that your *source* queue can then reference its ARN;
    2. describe both queues as [First-In-First-Out](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-fifoqueue) (FIFO) queues in this example. When you describe a *source* queue and a *dead-letter* [queue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-redrive), both queues must be of the same type: either *standard* or *FIFO* (the latter is the example for this lab). You note that the example template contains different configuration values for the `FifoQueue` property of your 2 queues, for which you instead expect to have a value of `true` for both. Moreover, when you describe a FIFO queue, its name must contain a `.fifo` suffix: whilst `ExampleSourceQueue` contains the `.fifo` suffix in its `QueueName`, it is configured as a standard queue (i.e., with `FifoQueue` set to `false`), thus resulting in an error.

You will use the `example_sqs_queues.yaml` template, that contains the error mentioned earlier, to test the stack rollback pause functionality: you will then fix the error, and complete the stack creation next:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and [choose a Region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) you wish to use.
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Prepare template**, choose **Template is ready**.
4. From **Template source**, choose **Upload a template file**. Choose the `example_sqs_queues.yaml` template mentioned earlier, and then choose **Next**.
5. Specify a stack name; for example, choose `troubleshoot-provisioning-errors-workshop`. On the same page, choose to accept the default value for the `QueueNamePrefix` parameter, and choose **Next**.
6. In **Stack failure options**, choose **Preserve successfully provisioned resources**. Choose **Next**.
7. Choose **Create stack** in the next page.
8. Refresh the stack creation page until you see your stack in the `CREATE_FAILED` status.

The stack creation has failed, because of the error mentioned earlier. Choose the name of your stack from the list (for example, `troubleshoot-provisioning-errors-workshop`): in the **Resources** tab, note your `ExampleDeadLetterQueue` resource in the `CREATE_COMPLETE` status, and your `ExampleSourceQueue` resource in `CREATE_FAILED` status, along with a relevant error in the **Status reason** column.

In the same stack view page, you will also see options from which you can choose next steps to take, as shown in the following picture:

![stack-rollback-paused.png](troubleshooting-provisioning-errors/stack-rollback-paused.png)

Your goal is to troubleshoot and fix the error in the template, and to choose to resume provisioning, so you can then create the `ExampleSourceQueue` resource. As part of this process, you preserve the state of your `ExampleDeadLetterQueue` that has been created successfully earlier.  Next steps:

1. with the `example_sqs_queues.yaml` template opened in your editor, change `FifoQueue: false` into `FifoQueue: true` for `ExampleSourceQueue`. When done, save your changes.
2. In the **Stack rollback paused** view shown in the picture earlier, choose **Update**.
3. In **Prepare template**, choose **Replace current template**, and choose to upload the template you just updated.
4. Choose **Next** in the **Parameters** page.
5. In the **Configure stack options** page, locate the **Stack failure options** section: the **Preserve successfully provisioned resources** option you chose at stack creation should still be selected. Scroll down on the page, and choose **Next**.
6. Next, choose **Update stack**.

Refresh the page until you see your stack in the `UPDATE_COMPLETE` status. In the **Resources** tab for your stack, your `ExampleSourceQueue` resource should now be in the `CREATE_COMPLETE` status.

{{% notice note %}}
Immutable update types (that is, when you [change the value for a property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html) that requires a replacement), are not supported. For more information, see [Conditions to pause stack rollback](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-conditions).
{{% /notice %}}

Congratulations! You have learned how to troubleshoot provisioning errors with the pause disable rollback functionality of CloudFormation!

{{% notice note %}}
In this lab, you have used the AWS CloudFormation Console to learn this functionality: for information on how to use it in the [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), see [Preserve successfully provisioned resources (AWS CLI)](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-cli) in the documentation.
{{% /notice %}}

### Challenge
You choose to describe two [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) resources in your  `example_sqs_queues.yaml` template. For each parameter, you choose to store the ARN of a queue you created earlier: for this, you reference the value you need by using the `Fn::GetAtt` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html) to get the [return value](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-return-values) of the relevant SQS resource attribute you need. You also choose to validate, in each parameter, that you are retrieving an SQS ARN by validating its format against an example regular expression pattern defined in `AllowedPattern` for each parameter. Steps:

* first, copy and paste the example configuration shown next by appending it to your  `example_sqs_queues.yaml` template:

```yaml
  ExampleDeadLetterQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the ExampleDeadLetterQueue ARN value
      Name: workshop-example-dead-letter-queue
      Type: String
      Value: !GetAtt ExampleDeadLetterQueue.Arn

  ExampleSourceQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the ExampleSourceQueue ARN value
      Name: workshop-example-source-queue
      Type: String
      Value: !GetAtt ExampleSourceQueue.QueueName
```

* Save your changes to the file. Next, [update your stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html) by using the AWS CloudFormation Console. When you do so, choose **Replace current template** in **Prepare template**, and upload the template you just updated. In the **Configure stack options** page, the **Preserve successfully provisioned resources** option should still be selected.
* The stack update operation will fail: when you look into the **Resources** tab for your stack, you should see that one of the two new resources has been created successfully, and the other new one should be in a `CREATE_FAILED` status instead.
* Troubleshoot and fix the error in the snippet you pasted into your template.
* Resume the stack update: verify your stack will be in the `UPDATE_COMPLETE` status, and the resource that was previously in the `CREATE_FAILED` status will be in a `CREATE_COMPLETE` status.

{{%expand "Need a hint?" %}}
 * Inspect the error in the `Events` pane for your stack in the AWS CloudFormation Console.
 * Navigate to this SQS resource documentation [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-return-values), and determine which one of the available return values you need to get, with `Fn::GetAtt`, the SQS queue ARN. Use this information to validate if the relevant configuration in the snippet you pasted earlier is the one you expect.
{{% /expand %}}

{{%expand "Want to see the solution?" %}}
* Update your template: change `Value: !GetAtt 'ExampleSourceQueue.QueueName'` into `Value: !GetAtt 'ExampleSourceQueue.Arn'` for the `ExampleSourceQueueParameter` resource.
* [Update your stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html) by choosing to use the updated template.
* Note: the template with the full solution is available in the `code/solutions/troubleshooting-provisioning-errors` directory.
{{% /expand %}}

### Cleanup
Choose to follow cleanup steps shown next to clean up resources you created with this lab:
1. Choose the stack you have created on this lab, for example `troubleshoot-provisioning-errors-workshop`.
2. Choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.

---
### Conclusion
Great work! You learned how to troubleshoot provisioning errors, and how to locate resource property reference information in the AWS documentation with examples for SQS queues you created.
