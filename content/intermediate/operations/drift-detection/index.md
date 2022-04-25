---
title: "Drift Detection"
weight: 500
---

### Overview

When you choose to use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) to provision your resources, you maintain your resources’ configurations with CloudFormation over time, as needed. If, subsequently, you choose to manage such resources outside the purview of CloudFormation (for example, with the [AWS Management Console](https://aws.amazon.com/console/), the [AWS Command Line Interface](https://aws.amazon.com/cli/) (AWS CLI), [AWS SDKs](https://aws.amazon.com/getting-started/tools-sdks/), or with [AWS APIs](https://docs.aws.amazon.com/general/latest/gr/aws-apis.html), your resources’ configuration will drift.)

CloudFormation offers [Drift Detection](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html), that gives you information on the difference between the current configuration of a resource and the configuration you declared in the template you used to create or update the resource. The results of drift detection show you the affected resources and the differences between the current state and the template. You can then either return the resource to its original configuration, or update your template and your CloudFormation stack to reflect the new, desired state.

### Topics Covered

By the end of this lab, you will be able to:

* Use CloudFormation Drift Detection to detect drift on stack resources.
* Understand how to interpret the Drift Detection results to identify which resource properties have changed.
* Modify a resource to return it to its original configuration.
* Update a template to match the new configuration of a resource.
* Use resource import to update the stack and template to match the new configuration of a resource.

### Start Lab

You will deploy an example AWS CloudFormation template which contains an [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) table and an [Amazon Simple Queue Service (SQS)](https://aws.amazon.com/sqs/) queue as a new stack. You will then perform a number of configuration changes to the provisioned resources, and use Drift Detection to identify them. You will then resolve the drift by correcting the resource configuration or updating the template to reflect the new configuration.

To get started, follow these steps:

1. Change directory to the `code/workspace/drift-detection` directory.
2. Copy the code below, and append it to the `drift-detection-workshop.yaml` file, and save the file:

```yaml
Resources:
  Table1:
    Type: AWS::DynamoDB::Table
    Properties:
      AttributeDefinitions:
        - AttributeName: Album
          AttributeType: S
        - AttributeName: Artist
          AttributeType: S
      BillingMode: PROVISIONED
      KeySchema:
        - AttributeName: Album
          KeyType: HASH
        - AttributeName: Artist
          KeyType: RANGE
      ProvisionedThroughput:
        ReadCapacityUnits: 1
        WriteCapacityUnits: 1

  Queue1:
    Type: AWS::SQS::Queue
    Properties:
      MessageRetentionPeriod: 345600
```

3. Familiarise yourself with the example resources in the template:
    1. The DynamoDB [table](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html) has a minimal definition for the `KeySchema` and `AttributeDefinitions` properties in order to be successfully created. You will not be storing data in or retrieving data from the table during the workshop.
    2. The SQS [queue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html) has a `MessageRetentionPeriod` of four days (expressed in seconds). Note that although this value is the [default](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-messageretentionperiod), CloudFormation only evaluates drift against properties that you explicitly declare in the template. If you do not include this property, CloudFormation will not report a change to it on the resource later on.

In the next step, you will use the AWS CloudFormation Console to create a new stack using this template:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Specify template**, choose **Upload a template file**. Choose the `drift-detection-workshop.yaml` template mentioned earlier, and then choose **Next**.
4. Enter a stack name. For example, specify `drift-detection-workshop`. Choose **Next**.
5. In **Configure stack options**, choose **Next**.
6. Choose **Create stack**.
7. Refresh the stack creation page until you see your stack in the `CREATE_COMPLETE` state.

### Detecting and repairing drift by modifying the resource

Now you will modify the DynamoDB table directly, outside of CloudFormation.

1. Navigate to the [Amazon DynamoDB Console](https://console.aws.amazon.com/dynamodb/).
2. Under the **Tables** heading on the menu, choose **Update settings**.
3. Choose the **Table1** entry (the table name will be prefixed with the name of your stack).
4. Choose the **Additional settings** tab.
5. In the **Read/write capacity** section, choose **Edit**.
6. Choose the **On-demand** capacity mode, then choose **Save Changes**.

In this step, you will use CloudFormation Drift Detection to identify the changes to the `Table1` resource compared to the original template.

1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your stacks.
2. Choose your stack created in the earlier steps (for example, `drift-detection-workshop`).
3. From **Stack actions**, choose **Detect Drift**.
4. Drift detection takes a few moments to complete. Navigate to the **Stack info** tab, and refresh the page until the **Drift status** field shows `DRIFTED`.
5. From **Stack actions**, choose **View drift results**.
6. The drift status page displays, showing that `Table1` has been modified and `Queue1` is still in sync with the template.
7. From the **Resource drift status** view, select `Table1`; next, choose **View drift details**.
8. The drift details for `Table1` will show next, giving three differences. The `BillingMode` property has changed per the change you made in the Console, and the `ProvisionedThroughput` values have also been updated by DynamoDB as part of that change. You can select each property in the **Differences** view to see, highlighted, related template differences.

You now have the necessary information to correct the configuration drift, and have your desired configuration match your template again. Follow these steps to update your table configuration:

1. Return to the [DynamoDB Console](https://console.aws.amazon.com/dynamodb), then choose **Update settings** as before.
2. Choose the entry for **Table1**, and then navigate to the **Additional settings** tab.
3. Choose **Edit**.
4. Choose **Provisioned** capacity mode.
5. Choose **Off** for **Auto scaling** for both **Read capacity** and **Write capacity**.
6. Enter `1` for both Read and Write capacity **provisioned capacity units**.
7. Choose **Save changes**.

The resource is now in sync with template, restored to its original configuration. If you perform the drift detection on the stack as you did earlier, in the **Stack info** tab you should now see `IN_SYNC` for the **Drift status** field.

### Detecting and repairing drift by updating the template

The template you deployed in the previous section also created an Amazon SQS queue. You will now modify a property of the queue, verify that CloudFormation detects the drift, and then update the template to match the new resource configuration. You will start by modifying the queue.


1. Navigate to the [Amazon SQS Console](https://console.aws.amazon.com/sqs/).
2. If necessary, choose the collapsed menu on the left to expand it, then choose **Queues**.
3. Locate the queue which has a name starting with the name of your stack (e.g. `drift-detection-workshop`) and choose it.
4. Choose **Edit**.
5. Modify the **Message Retention Period** to be `2` days instead of `4`, then choose **Save** at the bottom of the page.

In this step, you will detect the drift on the Queue resource using CloudFormation.

1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your stacks.
2. Choose your stack created in the earlier steps (for example, `drift-detection-workshop`).
3. From **Stack actions**, choose **Detect Drift**.
4. Wait a few seconds for drift detection to complete. Refresh the stack info page until the **Drift status** field shows `DRIFTED`.
5. From **Stack actions**, choose **View drift results**.
6. The drift status page displays, showing that `Queue1` has been modified.
7. Select `Queue1`, and then choose **View drift details**.
8. The drift details for `Queue1` show, giving one difference. The `MessageRetentionPeriod` property has changed per the change you made in the Console.

You will now update the template to match the new state of the resource and bring the stack back into sync.

1. In your favourite text editor, open the template file for the workshop.
2. Modify `Queue1`'s `MessageRetentionPeriod` to match the value shown in the **Actual** column of the drift details page you saw in the previous step. In your template, set the value for `MessageRetentionPeriod` to `172800`, that is the number of seconds in `2` days.
3. Save the template file.
4. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
5. Choose your stack as before.
6. Choose **Update**.
7. Choose **Replace current template**, then choose **Upload a template file**.
8. Use **Choose file** to select your updated template file.
9. Choose **Next**.
10. On the stack details page, choose **Next**.
11. On the stack options page, choose **Next**.
12. Choose **Update Stack**.
13. Wait for the stack update to complete. Refresh the page to load the current state.
14. Choose the **Stack info** tab.
15. From **Stack actions**, choose **Detect Drift**.
16. Wait a few seconds for drift detection to complete.
17. You should now see that the drift status is `IN_SYNC`, showing that the template and resource match.

Congratulations! You have learned how to repair stack drift by updating the template to match the new state of a resource.

### Challenge

In this exercise, you will use the knowledge gained from the earlier parts of this lab, along with the knowledge gained from the previous lab on [Resource Importing](/intermediate/operations/resource-importing.html), to solve an issue where a resource has been updated outside your CloudFormation stack’s purview and its configuration drifted, but you are unable to update the CloudFormation stack to match without causing an [interruption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html) to the resource. You should remove the resource from the stack, and then import it with the updated properties.

To begin, follow the steps below:

1. Open the `drift-detection-challenge.yaml` file in your favourite editor.
2. Add the content below to the `drift-detection-challenge.yaml` template and save the file. This template will launch an [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instance using the latest Amazon Linux 2 AMI, and configure it to run a script on first boot, which prints `Hello World`.

```yaml
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

Resources:
  Instance1:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello World

  Bucket1:
    Type: AWS::S3::Bucket
```

::alert[This `UserData` script will only run the first time the instance boots. You can [create a configuration](https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/) which will run a script on every boot, but in order to keep the template complexity low for this workshop, this template just shows simple content.]

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Specify template**, choose **Upload a template file**, upload the `drift-detection-challenge.yaml` file and choose **Next**.
4. Enter a stack name, for example `drift-detection-challenge` and choose **Next**.
5. In **Configure Stack Options**, choose **Next**.
6. In the next page, choose **Create stack**.
7. Once the stack is created, select the `drift-detection-challenge` stack and choose **Resources**. Take a note of the **Physical ID** for `Instance1`, for example `i-1234567890abcdef0`.

You will now modify this resource in a similar way to the first lab to introduce drift. This modification causes an interruption, as the `UserData` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-userdata) you will change requires the instance to be stopped first. You will change the message printed to read: `Hello Universe`.

1. Navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/).
2. Locate the **Instances** section, and select the instance with the ID recorded above.
3. Choose the **Additional settings** tab.
4. From **Instance state**, choose **Stop instance**, then choose **Stop**.
5. Wait for the instance state to change to `Stopped`. Refresh the page if necessary.
6. Once the Instance state is `Stopped`, select the instance again if necessary, then from **Actions** choose **Instance settings**, then choose **Edit user data**.
7. In **New user data**, modify the script to change Hello World to Hello Universe as below:

:::code{language=shell showLineNumbers=false showCopyAction=true}
#!/usr/bin/env bash
echo Hello Universe
:::

8. Choose **Save**.
9. Select the instance again, then from **Instance state**, choose **Start instance**.
10. Wait for the instance state to change to `Running`. Refresh the page if necessary.

In this step, you will use CloudFormation Drift Detection to identity the changes to the `Instance1` resource compared to the original template.

1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your Stacks.
2. Choose your stack created in the earlier steps (for example, `drift-detection-challenge`).
3. From **Stack actions**, choose **Detect Drift**.
4. Drift detection takes a few moments to complete. Refresh the stack info page until the **Drift status** field shows `Drifted`.
5. From **Stack actions**, choose **View drift results**.
6. The drift status page displays, showing that `Instance1` has been modified.
7. Select `Instance1`, then choose **View drift details**.
8. The drift details show that the `UserData` property has been modified. The `UserData` property is stored using Base64 encoding, so the exact change you made is not obvious in the display.

::alert[You can use a tool to decode the Base64 text and see the shell script it represents. For example, on Linux you can use the `base64` command line tool to process it as follows. Note that some implementations, for example macOS, use `-D` instead of `-d` as the option to the `base64` command.]

For example, when you run the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==" | base64 -d
:::

you should see the following output:

:::code{language=shell showLineNumbers=false showCopyAction=false}
#!/usr/bin/env bash
echo Hello World
:::

::alert[Be wary of using third-party websites to encode or decode your base64 text for UserData, especially if it contains or could contain sensitive information.]{type="warning"}

Your task now is to update the stack with the new state of the resource, without causing a further interruption.

:::expand{header="Need a hint?"}

* You should detach the resource from the stack, then re-import it again with the `UserData` corrected. You do not need to convert the `UserData` to Base64.
* Refer to the [Resource Importing](/intermediate/operations/resource-importing.html) lab for more guidance.

:::

:::expand{header="Want to see the solution?"}

1. Update the `drift-detection-challenge.yaml` template to add a `DeletionPolicy` attribute with a value of `Retain` to the `Instance1` resource. Save the file.
2. Update the stack with the updated `drift-detection-challenge.yaml` template. This tells CloudFormation that when the resource is removed from the template, it should not delete it but just stop managing it.
3. Once the stack update is complete, edit the template file again to remove the whole resource declaration (you can also choose to comment it out, using the `#` character at the start of each relevant line), and save the file.
4. Update the stack with the updated template file. CloudFormation will remove the instance from the stack without terminating it.
5. Edit the template file to restore the resource, and update the UserData to match the change made previously.

```yaml
Resources:
  Instance1:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello Universe
```

6. Select the stack in the CloudFormation console, then from **Stack actions** choose **Import resources in to stack**.
7. Choose **Next**.
8. Upload the template file.
9. Enter the physical ID of the instance and choose **Next**.
10. In **Specify stack options**, choose **Next**.
11. Choose **Import resources**.
12. Once the stack operation is complete and the resource is imported, you can run drift detection on the stack to confirm the instance is now in sync with the stack template.

:::

You can find the template for the solution in `code/solutions/drift-detection/drift-detection-workshop.yaml`.

Well done! You have now learned how to repair drift without impact by deleting and re-importing a resource.

### Cleanup

Follow steps shown next to clean up the resources you created in this workshop.

1. Navigate to the CloudFormation Console.
2. Choose the stack created in the first lab, for example `drift-detection-workshop`.
3. Choose **Delete**, then choose the **Delete stack**.
4. For the `drift-detection-challenge` stack, edit the template file to change the `DeletionPolicy` to `Delete`.
5. Update the stack by selecting it, then choosing **Upload**, then **Replace current template** and uploading the updated file. Choose **Next**, then choose **Next**, then choose **Next**, and then choose **Update stack**. Wait for the stack update to complete.
6. Select the `drift-detection-challenge` stack and choose **Delete**, then choose **Delete stack**.

### Conclusion

In this lab, you learned how to detect drift on CloudFormation stacks to find resources which had been modified outside of CloudFormation, and see details of the changes. You learned how to verify a resource had been modified correctly back to match the template, as well as how to update the stack to match a resource’s new desired state. Finally, you learned how to correct drift by deleting and re-importing the affected resource.
