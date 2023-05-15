---
title: "Troubleshooting provisioning errors"
weight: 500
---

_Lab Duration: ~25 minutes_

---

### Overview
As you iterate on the development of your CloudFormation template, you can test provisioning of resources described in your template by creating a CloudFormation [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacks.html). If you specify incorrect property values for resource configurations in the template, by default the stack will roll back to the last-known stable state, and all stack resources will be rolled back.

Let's take an example where you create a stack off of a template, in which you describe 10 resources. In this example, 9 resources are described as successfully created, and the creation of the tenth resource fails: by default, the stack will roll back, including the 9 resources that were successfully provisioned.

To speed up development cycles, you can choose to [preserve](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html) the state of resources that have been successfully provisioned as part of stack create and update operations, and of [change set](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) operations. When you choose to use this functionality, the stack rollback is paused to preserve the state of successfully provisioned resources; then, you can start troubleshooting and fixing your configurations, and resume provisioning operations when you are ready.

### Topics Covered
By the end of this lab, you will be able to:

* Understand how to troubleshoot provisioning errors, whilst preserving the state of successfully deployed resources
* Navigate to the [AWS resource and property types reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) to discover resource properties, and return values for a given resource

### Start Lab
An example CloudFormation template contains an incorrect resource configuration. To correct this, you will choose to *preserve successfully provisioned resources* as part of *stack failure options* to preserve the state of an example `DeadLetterQueue` [Amazon SQS](https://aws.amazon.com/sqs/) queue resource, to be successfully provisioned.

The creation operation for the stack will fail because another SQS queue is described in the template, and has a configuration error. Once you troubleshoot and fix the error in the template, you can resume the stack creation operation with the updated template.

To get started, follow steps shown next:
1. Change directory to the `code/workspace/troubleshooting-provisioning-errors` directory.
2. Open the `sqs-queues.yaml` CloudFormation template in your favorite text editor.
3. Familiarize yourself with the configuration of the sample SQS queues in the template; your intents, in this example, are to:
    1. create a *source* queue and a [*dead-letter* queue](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html) (DLQ): have your `SourceQueue` target your `DeadLetterQueue` for messages that cannot be successfully processed. In the template, reference the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) for `DeadLetterQueue` in the [redrive policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-redrive) for `SourceQueue`: your DLQ will then be created first, so that your *source* queue can then reference its ARN;
    2. describe both queues as [First-In-First-Out](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-fifoqueue) (FIFO) queues in this example. When you describe a *source* queue and a *dead-letter* [queue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-redrive), both queues must be of the same type: either *standard* or *FIFO* (the latter is the example for this lab). Note, that the example template contains different configuration for the two `FifoQueue` property values, instead of the expected value of `true` for both. Moreover, when you describe a FIFO queue, its name must contain a `.fifo` suffix: whilst `SourceQueue` contains the `.fifo` suffix in its `QueueName`, it is configured as a standard queue (i.e., with `FifoQueue` set to `false`), thus resulting in an error.

Use the `sqs-queues.yaml` template, that contains the error mentioned earlier, to test the stack rollback pause functionality, then fix the error, and complete the stack creation:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/troubleshooting-provisioning-errors`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/troubleshooting-provisioning-errors
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-troubleshooting-provisioning-errors --template-body file://sqs-queues.yaml --disable-rollback
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-troubleshooting-provisioning-errors/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_FAILED**.
::::

::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and [choose a Region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) you wish to use.
1. From **Create stack**, choose **With new resources (standard)**.
1. From **Prepare template**, choose **Template is ready**.
1. From **Template source**, choose Upload a template file. Choose the `sqs-queues.yaml` template mentioned earlier, and then choose Next.
1. Specify a stack name: for example, `cfn-workshop-troubleshooting-provisioning-errors`. On the same page, accept the default value for the `QueueNamePrefix` parameter, and choose **Next**.
1. In **Stack failure options**, select **Preserve successfully provisioned resources**. Choose **Next**.
1. Choose **Submit** in the next page.
1. Refresh the stack creation page until you see your stack in the `CREATE_FAILED` status.
::::
:::::

The stack creation has failed, because of the error mentioned earlier. Select the name of your stack from the list (for example, `cfn-workshop-troubleshooting-provisioning-errors`): in the **Resources** tab, note that the `DeadLetterQueue` resource is in the `CREATE_COMPLETE` status, and the `SourceQueue` resource is in `CREATE_FAILED` status, along with a relevant error in the **Status reason** column.

In the same stack view page, you will also see options from which you can choose next steps to take, as shown in the following picture:

![stack-rollback-paused.png](/static/basics/operations/troubleshooting-provisioning-errors/stack-rollback-paused.png)

Your goal is to troubleshoot and fix the error in the template, and resume provisioning, to create the `SourceQueue` resource. As part of this process, preserve the state of your `DeadLetterQueue` that has been created successfully earlier. Next steps:

 With the `sqs-queues.yaml` template opened in your editor, find `SourceQueue` resource, and change `FifoQueue: false` into `FifoQueue: true`. When done, save your changes.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/troubleshooting-provisioning-errors`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/troubleshooting-provisioning-errors
:::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name cfn-workshop-troubleshooting-provisioning-errors --template-body file://sqs-queues.yaml --disable-rollback
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-troubleshooting-provisioning-errors/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the **Stack rollback paused** view shown in the picture earlier, choose **Update**.
1. In **Prepare template**, choose **Replace current template**, and choose to upload the template you just updated.
1. Choose **Next** in the **Parameters** page.
1. In the **Configure stack options** page, locate the **Stack failure options** section: the **Preserve successfully provisioned resources** option you chose at stack creation should still be selected. Scroll down on the page, and choose **Next**.
1. Next, choose **Submit**.
::::
:::::

Refresh the page until you see your stack in the `UPDATE_COMPLETE` status. In the **Resources** tab for your stack, your `SourceQueue` resource should now be in the `CREATE_COMPLETE` status.

::alert[Immutable update types (that is, when you [change the value for a property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html) that requires a replacement), are not supported. For more information, see [Conditions to pause stack rollback](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-conditions).]{type="info"}

Congratulations! You have learned how to troubleshoot provisioning errors with the pause disable rollback functionality of CloudFormation!

::alert[In this lab, you have used the AWS CloudFormation Console to learn this functionality: for information on how to use it in the [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), see [Preserve successfully provisioned resources (AWS CLI)](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-failure-options.html#stack-failure-options-cli) in the documentation.]{type="info"}

### Challenge
You choose to describe two [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) resources in your `sqs-queues.yaml` template. For each parameter, you choose to store the ARN of a queue you created earlier: for this, you reference the value you need by using the `Fn::GetAtt` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html) to get the [return value](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-return-values) of the relevant SQS resource attribute you need. You also choose to validate that you are specifying an SQS ARN as the parameter value, by validating its format against an example regular expression pattern defined in `AllowedPattern` for each parameter. Steps:

* first, copy and paste the example configuration shown next by appending it to your `sqs-queues.yaml` template:

```yaml
  DeadLetterQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the DeadLetterQueue ARN value
      Name: workshop-example-dead-letter-queue
      Type: String
      Value: !GetAtt DeadLetterQueue.Arn

  SourceQueueParameter:
    Type: AWS::SSM::Parameter
    Properties:
      AllowedPattern: ^arn:aws([-a-z0-9-]*[a-z0-9])*:sqs:[a-z0-9-]+:[0-9]{12}:[a-zA-Z0-9_-]{1,80}(\.fifo){0,1}$
      Description: Parameter for the SourceQueue ARN value
      Name: workshop-example-source-queue
      Type: String
      Value: !GetAtt SourceQueue.QueueName
```

* Save your changes to the file. Next,

[update your stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html) by using the AWS CloudFormation Console using the same procedure you followed in previous step to update stack. When you do so, choose **Replace current template** in **Prepare template**, and upload the template you just updated. In the **Configure stack options** page, the **Preserve successfully provisioned resources** option should still be selected.
* The stack update operation will fail: when you look into the **Resources** tab for your stack, you should see that one of the two new resources has been created successfully, and the other new one should be in a `CREATE_FAILED` status instead.
* Troubleshoot and fix the error in the snippet you pasted into your template.
* Resume the stack update: verify your stack will be in the `UPDATE_COMPLETE` status, and the resource that was previously in the `CREATE_FAILED` status will be in a `CREATE_COMPLETE` status.

:::expand{header="Need a hint?"}
* Inspect the error in the `Events` pane for your stack in the AWS CloudFormation Console.
 * Navigate to this SQS resource documentation [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-return-values), and determine which one of the available return values you need to get, with `Fn::GetAtt`, the SQS queue ARN. Use this information to validate if the relevant configuration in the snippet you pasted earlier is the one you expect.
:::

::::::expand{header="Want to see the solution?"}
* Update your template: change `Value: !GetAtt 'SourceQueue.QueueName'` into `Value: !GetAtt 'SourceQueue.Arn'` for the `SourceQueueParameter` resource.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/troubleshooting-provisioning-errors`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/troubleshooting-provisioning-errors
  :::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-troubleshooting-provisioning-errors --template-body file://sqs-queues.yaml --disable-rollback
  :::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-troubleshooting-provisioning-errors/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Click on the stack name, for example **cfn-workshop-troubleshooting-provisioning-errors**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `sqs-queues.yaml ` and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.
::::
:::::
* Note: the template with the full solution is available in the `code/solutions/troubleshooting-provisioning-errors` directory.
::::::

### Cleanup
Choose to follow cleanup steps shown next to clean up resources you created with this lab:
1. Choose the stack you have created on this lab, for example `cfn-workshop-troubleshooting-provisioning-errors`.
2. In the top right corner, select **Delete**.
3. In the pop-up window, select **Delete**.
4. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---
### Conclusion
Great work! You learned how to troubleshoot provisioning errors, and how to locate resource property reference information in the AWS documentation with examples for SQS queues you created.
