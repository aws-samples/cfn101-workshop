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
1. Copy the code below, and append it to the `drift-detection-workshop.yaml` file, and save the file:
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=5}
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
:::

1. Familiarise yourself with the example resources in the template:
    1. The DynamoDB [table](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html) has a minimal definition for the `KeySchema` and `AttributeDefinitions` properties in order to be successfully created. You will not be storing data in or retrieving data from the table during the workshop.
    2. The SQS [queue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html) has a `MessageRetentionPeriod` of four days (expressed in seconds). Note that although this value is the [default](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-messageretentionperiod), CloudFormation only evaluates drift against properties that you explicitly declare in the template. If you do not include this property, CloudFormation will not report a change to it on the resource later on.
1. In the next step, you will use the AWS CloudFormation to create a new stack using this template:
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. In the **Cloud9 terminal** navigate to `cfn101-workshop/code/workspace/drift-detection`:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/drift-detection
   :::
   1. Create the stack by using the following AWS CLI command. For example use stack name as `cfn-workshop-drift-detection`
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-drift-detection \
--template-body file://drift-detection-workshop.yaml
   :::
   1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
   :::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/739fafa0-e4d7-11ed-a000-12d9009553ff"
   :::
   1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
   ::::
   ::::tab{id="local" label="Local Development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
   1. From **Create stack**, choose **With new resources (standard)**.
   1. From **Specify template**, choose **Upload a template file**. Choose the `drift-detection-workshop.yaml` template mentioned earlier, and then choose **Next**.
   1. Enter a stack name. For example, specify `cfn-workshop-drift-detection`. Choose **Next**.
   1. In **Configure stack options**, choose **Next**.
   1. Choose **Submit**.
   1. Refresh the stack creation page until you see your stack in the `CREATE_COMPLETE` state.
   ::::
   :::::

### Detecting and repairing drift by modifying the resource

Now you will modify the DynamoDB table directly, outside of CloudFormation.

1. Navigate to the [Amazon DynamoDB Console](https://console.aws.amazon.com/dynamodb/).
1. Under the **Tables** heading on the menu, choose **Update settings**.
1. Choose the **Table1** entry (the table name will be prefixed with the name of your stack).
1. Choose the **Additional settings** tab.
1. In the **Read/write capacity** section, choose **Edit**.
1. Choose the **On-demand** capacity mode, then choose **Save Changes**.

In this step, you will use CloudFormation Drift Detection to identify the changes to the `Table1` resource compared to the original template.
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. Run the following AWS CLI command to **Detect Drift** for your stack `cfn-workshop-drift-detection`.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. CloudFormation returns the following output.
   :::code{language=json showLineNumbers=false showCopyAction=true}
  "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073"
   :::
   1. Verify the status of drift detection operation with the `stack-drift-detection-id` that is returned as part of the output of step 2.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-drift-detection-status \
--stack-drift-detection-id stack-drift-detection-id
   :::
   1. If the `describe-stack-drift-detect-status` command was successfully sent, CloudFormation wll return the information with `"DetectionStatus":"DETECTION_COMPLETE"` and `"StackDriftStatus":"DRIFTED"`.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=4-5}
{
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
    "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073",
    "StackDriftStatus": "DRIFTED",
    "DetectionStatus": "DETECTION_COMPLETE",
    "DriftedStackResourceCount": 1,
    "Timestamp": "2023-05-23T08:52:55.332000+00:00"
}
   :::
   1. Run the following command to describe drifted resources.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. The drift details for `Table1` are shown in the output of `descibe-stack-resource-drifts` under `Property Differences` as highlighted in the below example.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21-34}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
            "LogicalResourceId": "Queue1",
            "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-LhZ9kuNmNV62",
            "ResourceType": "AWS::SQS::Queue",
            "ExpectedProperties": "{\"MessageRetentionPeriod\":345600}",
            "ActualProperties": "{\"MessageRetentionPeriod\":345600}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T08:42:44.951000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/83fd7940-f945-11ed-ab77-12daf0c351ad",
            "LogicalResourceId": "Table1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-173M9QVM1EZKE",
            "ResourceType": "AWS::DynamoDB::Table",
            "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "ActualProperties": "{\"BillingMode\":\"PAY_PER_REQUEST\",\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/ProvisionedThroughput",
                    "ExpectedValue": "{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1}",
                    "ActualValue": "null",
                    "DifferenceType": "REMOVE"
                },
                {
                    "PropertyPath": "/BillingMode",
                    "ExpectedValue": "PROVISIONED",
                    "ActualValue": "PAY_PER_REQUEST",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T09:31:32.470000+00:00"
        }
    ]
}
   :::
   ::::
   ::::tab{id="local" label="Local Development"}
    1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your stacks.
    1. Choose your stack created in the earlier steps (for example, `cfn-workshop-drift-detection`).
    1. From **Stack actions**, choose **Detect Drift**.
    1. Drift detection takes a few moments to complete. Navigate to the **Stack info** tab, and refresh the page until the **Drift status** field shows `DRIFTED`.
    1. From **Stack actions**, choose **View drift results**.
    1. The drift status page displays, showing that `Table1` has been modified and `Queue1` is still in sync with the template.
    1. From the **Resource drift status** view, select `Table1`; next, choose **View drift details**.
    1. The drift details for `Table1` will show next, giving three differences. The `BillingMode` property has changed per the change you made in the Console, and the `ProvisionedThroughput` values have also been updated by DynamoDB as part of that change. You can select each property in the **Differences** view to see, highlighted, related template differences.
   ::::
   :::::
You now have the necessary information to correct the configuration drift, and have your desired configuration match your template again. Follow these steps to update your table configuration:

1. Return to the [DynamoDB Console](https://console.aws.amazon.com/dynamodb), then choose **Update settings** as before.
1. Choose the entry for **Table1**, and then navigate to the **Additional settings** tab.
1. Choose **Edit**.
1. Choose **Provisioned** capacity mode.
1. Choose **Off** for **Auto scaling** for both **Read capacity** and **Write capacity**.
1. Enter `1` for both Read and Write capacity **provisioned capacity units**.
1. Choose **Save changes**.

The resource is now in sync with template, restored to its original configuration. If you perform the drift detection on the stack as you did earlier, in the **Stack info** tab you should now see `IN_SYNC` for the **Drift status** field.

### Detecting and repairing drift by updating the template

The template you deployed in the previous section also created an Amazon SQS queue. You will now modify a property of the queue, verify that CloudFormation detects the drift, and then update the template to match the new resource configuration. You will start by modifying the queue.

1. Navigate to the [Amazon SQS Console](https://console.aws.amazon.com/sqs/).
1. If necessary, choose the collapsed menu on the left to expand it, then choose **Queues**.
1. Locate the queue which has a name starting with the name of your stack (e.g. `cfn-workshop-drift-detection`) and choose it.
1. Choose **Edit**.
1. Modify the **Message Retention Period** to be `2` days instead of `4`, then choose **Save** at the bottom of the page.

In this step, you will detect the drift on the Queue resource using CloudFormation.
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. Run the following AWS CLI command to **Detect Drift** for your stack `cfn-workshop-drift-detection`.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. CloudFormation returns the following output.
   :::code{language=json showLineNumbers=false showCopyAction=true}
  "StackDriftDetectionId": "2c320c80-f954-11ed-9e69-0a031a01f375"
   :::
   1. Verify the status of drift detection operation with the `stack-drift-detection-id` that is returned as part of the output of step 2.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-drift-detection-status \
--stack-drift-detection-id stack-drift-detection-id
   :::
   1. If the `describe-stack-drift-detect-status` command was successfully sent, CloudFormation wll return the information with `"DetectionStatus":"DETECTION_COMPLETE"` and `"StackDriftStatus":"DRIFTED"`.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=4-5}
{
    "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/2c320c80-f954-11ed-9e69-0a031a01f375",
    "StackDriftDetectionId": "35768f30-f947-11ed-9dc9-0eb469d3b073",
    "StackDriftStatus": "DRIFTED",
    "DetectionStatus": "DETECTION_COMPLETE",
    "DriftedStackResourceCount": 1,
    "Timestamp": "2023-05-23T08:52:55.332000+00:00"
}
   :::
   1. Run the following command to describe drifted resources.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. The drift details for `Queue1` are shown in the output of `descibe-stack-resource-drifts` under `Property Differences` as highlighted in the below example.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=10-17}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
            "LogicalResourceId": "Queue1",
            "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-9vq6DP77LiCe",
            "ResourceType": "AWS::SQS::Queue",
            "ExpectedProperties": "{\"MessageRetentionPeriod\":345600}",
            "ActualProperties": "{\"MessageRetentionPeriod\":172800}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/MessageRetentionPeriod",
                    "ExpectedValue": "345600",
                    "ActualValue": "172800",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T10:25:44.111000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
            "LogicalResourceId": "Table1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-1VFN7I198DR33",
            "ResourceType": "AWS::DynamoDB::Table",
            "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "ActualProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T10:25:44.761000+00:00"
        }
    ]
}
   :::
   ::::
   ::::tab{id="local" label="Local Development"}
    1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your stacks.
    1. Choose your stack created in the earlier steps (for example, `drift-detection-workshop`).
    1. From **Stack actions**, choose **Detect Drift**.
    1. Wait a few seconds for drift detection to complete. Refresh the stack info page until the **Drift status** field shows `DRIFTED`.
    1. From **Stack actions**, choose **View drift results**.
    1. The drift status page displays, showing that `Queue1` has been modified.
    1. Select `Queue1`, and then choose **View drift details**.
    1. The drift details for `Queue1` show, giving one difference. The `MessageRetentionPeriod` property has changed per the change you made in the Console.
   ::::
   :::::
You will now update the template to match the new state of the resource and bring the stack back into sync.

1. In your text editor, open the template file `drift-detection-workshop.yaml` for the workshop.
1. Modify `Queue1`'s `MessageRetentionPeriod` to match the value shown in the **Actual** column of the drift details page you saw in the previous step. In your template, set the value for `MessageRetentionPeriod` to `172800`, that is the number of seconds in `2` days.
1. Save the template file.
1. It’s now time to update your stack! Follow steps below:
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. In the **Cloud9 terminal** ensure your working directory is `cfn101-workshop/code/workspace/drift-detection`:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/drift-detection
   :::
   1. Update the stack `cfn-workshop-drift-detection` by using the following AWS CLI command.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection \
--template-body file://drift-detection-workshop.yaml
   :::
   1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
   :::code{language=json showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/739fafa0-e4d7-11ed-a000-12d9009553ff"
   :::
   1. Wait for the `UPDATE` operation to complete by running the following AWS CLI command.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation wait stack-update-complete \
--stack-name cfn-workshop-drift-detection
   :::
   1. Run the following AWS CLI command to **Detect Drift** for your stack `cfn-workshop-drift-detection`.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection
   :::
   1. Run the following command to describe drifted resources.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation describe-stack-resource-drifts \
--stack-name cfn-workshop-drift-detection
   :::
   1. You should now see that the drift status is `IN_SYNC`, showing that the template and resource match.
   :::code{language=json showLineNumbers=true showCopyAction=false highlightLines=11,22}
    {
        "StackResourceDrifts": [
            {
                "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
                "LogicalResourceId": "Queue1",
                "PhysicalResourceId": "https://sqs.us-east-1.amazonaws.com/123456789012/cfn-workshop-drift-detection-Queue1-9vq6DP77LiCe",
                "ResourceType": "AWS::SQS::Queue",
                "ExpectedProperties": "{\"MessageRetentionPeriod\":172800}",
                "ActualProperties": "{\"MessageRetentionPeriod\":172800}",
                "PropertyDifferences": [],
                "StackResourceDriftStatus": "IN_SYNC",
                "Timestamp": "2023-05-23T10:54:21.628000+00:00"
            },
            {
                "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection/6a9d0720-f94c-11ed-8f4f-0e06081e3865",
                "LogicalResourceId": "Table1",
                "PhysicalResourceId": "cfn-workshop-drift-detection-Table1-1VFN7I198DR33",
                "ResourceType": "AWS::DynamoDB::Table",
                "ExpectedProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"WriteCapacityUnits\":1,\"ReadCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeType\":\"S\",\"AttributeName\":\"Album\"},{\"AttributeType\":\"S\",\"AttributeName\":\"Artist\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
                "ActualProperties": "{\"BillingMode\":\"PROVISIONED\",\"ProvisionedThroughput\":{\"ReadCapacityUnits\":1,\"WriteCapacityUnits\":1},\"AttributeDefinitions\":[{\"AttributeName\":\"Album\",\"AttributeType\":\"S\"},{\"AttributeName\":\"Artist\",\"AttributeType\":\"S\"}],\"KeySchema\":[{\"KeyType\":\"HASH\",\"AttributeName\":\"Album\"},{\"KeyType\":\"RANGE\",\"AttributeName\":\"Artist\"}]}",
                "PropertyDifferences": [],
                "StackResourceDriftStatus": "IN_SYNC",
                "Timestamp": "2023-05-23T10:54:22.168000+00:00"
            }
        ]
    }
   :::
    ::::
    ::::tab{id="local" label="Local Development"}
   1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
   1. Choose your stack as before.
   1. Choose **Update**.
   1. Choose **Replace current template**, then choose **Upload a template file**.
   1. Use **Choose file** to select your updated template file.
   1. Choose **Next**.
   1. On the stack details page, choose **Next**.
   1. On the stack options page, choose **Next**.
   1. Choose **Submit**.
   1. Wait for the stack update to complete. Refresh the page to load the current state.
   1. Choose the **Stack info** tab.
   1. From **Stack actions**, choose **Detect Drift**.
   1. Wait a few seconds for drift detection to complete.
   1. You should now see that the drift status is `IN_SYNC`, showing that the template and resource match.
   ::::
   :::::

Congratulations! You have learned how to repair stack drift by updating the template to match the new state of a resource.

### Challenge

In this exercise, you will use the knowledge gained from the earlier parts of this lab, along with the knowledge gained from the previous lab on [Resource Importing](/intermediate/operations/resource-importing.html), to solve an issue where a resource has been updated outside your CloudFormation stack’s purview and its configuration drifted, but you are unable to update the CloudFormation stack to match without causing an [interruption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html) to the resource. You should remove the resource from the stack, and then import it with the updated properties.

To begin, follow the steps below:

1. Open the `drift-detection-challenge.yaml` file in your favourite editor.
1. Add the content below to the `drift-detection-challenge.yaml` template and save the file. This template will launch an [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instance using the latest Amazon Linux 2 AMI, and configure it to run a script on first boot, which prints `Hello World`.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=5}
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
:::
:::alert{type="info"}
This `UserData` script will only run the first time the instance boots. You can [create a configuration](https://aws.amazon.com/premiumsupport/knowledge-center/execute-user-data-ec2/) which will run a script on every boot, but in order to keep the template complexity low for this workshop, this template just shows simple content.
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** ensure your working directory is `cfn101-workshop/code/workspace/drift-detection`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/drift-detection
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. Wait for the `CREATE` operation to complete by using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. Run the AWS CLI command to get the **Physical ID** for `Instance1`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. CloudFormation returns the following output. Take note of the **Physical ID** for `Instance1` as highlighted in the below example
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=19}
{
    "StackResources": [
        {
            "StackName": "cfn-workshop-drift-detection-challenge",
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "2023-05-23T12:27:57.391000+00:00",
            "ResourceStatus": "CREATE_COMPLETE",
            "DriftInformation": {
                "StackResourceDriftStatus": "NOT_CHECKED"
            }
        },
        {
            "StackName": "cfn-workshop-drift-detection-challenge",
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-1234567890abcdef0",
            "ResourceType": "AWS::EC2::Instance",
            "Timestamp": "2023-05-23T12:28:09.726000+00:00",
            "ResourceStatus": "CREATE_COMPLETE",
            "DriftInformation": {
                "StackResourceDriftStatus": "NOT_CHECKED"
            }
        }
    ]
}
:::
::::
::::tab{id="local" label="Local Development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With new resources (standard)**.
1. From **Specify template**, choose **Upload a template file**, upload the `drift-detection-challenge.yaml` file and choose **Next**.
1. Enter a stack name, for example `cfn-workshop-drift-detection-challenge` and choose **Next**.
1. In **Configure Stack Options**, choose **Next**.
1. In the next page, choose **Submit**.
1. Once the stack is created, select the `cfn-workshop-drift-detection-challenge` stack and choose **Resources**. Take a note of the **Physical ID** for `Instance1`, for example `i-1234567890abcdef0`.
::::
:::::

You will now modify this resource in a similar way to the first lab to introduce drift. This modification causes an interruption, as the `UserData` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-userdata) you will change requires the instance to be stopped first. You will change the message printed to read: `Hello Universe`.

1. Navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/).
1. Locate the **Instances** section, and select the instance with the ID recorded above.
1. From **Instance state**, choose **Stop instance**, then choose **Stop**.
1. Wait for the instance state to change to `Stopped`. Refresh the page if necessary.
1. Once the Instance state is `Stopped`, select the instance again if necessary, then from **Actions** choose **Instance settings**, then choose **Edit user data**.
1. In **New user data**, modify the script to change Hello World to Hello Universe as below:
:::code{language=shell showLineNumbers=false showCopyAction=true}
#!/usr/bin/env bash
echo Hello Universe
:::
1. Choose **Save**.
1. Select the instance again, then from **Instance state**, choose **Start instance**.
1. Wait for the instance state to change to `Running`. Refresh the page if necessary.

In this step, you will use CloudFormation Drift Detection to identity the changes to the `Instance1` resource compared to the original template.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's try to identify the changes to the `Instance1`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. Verify the **Drift Results** by using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resource-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. The drift details for `Instance1` are shown in the output of `descibe-stack-resource-drifts` under `Property Differences` as highlighted in the below example.
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=21-28}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "ExpectedProperties": "{}",
            "ActualProperties": "{}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T12:52:07.616000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-0113f35b272b0f04e",
            "ResourceType": "AWS::EC2::Instance",
            "ExpectedProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "ActualProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFVuaXZlcnNl\"}",
            "PropertyDifferences": [
                {
                    "PropertyPath": "/UserData",
                    "ExpectedValue": "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==",
                    "ActualValue": "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFVuaXZlcnNl",
                    "DifferenceType": "NOT_EQUAL"
                }
            ],
            "StackResourceDriftStatus": "MODIFIED",
            "Timestamp": "2023-05-23T12:52:08.421000+00:00"
        }
    ]
}
:::
::::
::::tab{id="local" label="Local Development"}
1. Navigate to the [CloudFormation Console](https://console.aws.amazon.com/cloudformation/). If necessary, choose the **Stacks** menu item to see your Stacks.
1. Choose your stack created in the earlier steps (for example, `drift-detection-challenge`).
1. From **Stack actions**, choose **Detect Drift**.
1. Drift detection takes a few moments to complete. Refresh the stack info page until the **Drift status** field shows `Drifted`.
1. From **Stack actions**, choose **View drift results**.
1. The drift status page displays, showing that `Instance1` has been modified.
1. Select `Instance1`, then choose **View drift details**.
1. The drift details show that the `UserData` property has been modified. The `UserData` property is stored using Base64 encoding, so the exact change you made is not obvious in the display.
::::
:::::
:::alert{type="info"}
You can use a tool to decode the Base64 text and see the shell script it represents. For example, on Linux you can use the `base64` command line tool to process it as follows. Note that some implementations, for example macOS, use `-D` instead of `-d` as the option to the `base64` command.
:::

For example, when you run the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==" | base64 -d
:::

you should see the following output:
:::code{language=shell showLineNumbers=false showCopyAction=false}
#!/usr/bin/env bash
echo Hello World
:::

:::alert{type="warning"}
Be wary of using third-party websites to encode or decode your base64 text for UserData, especially if it contains or could contain sensitive information.
:::

Your task now is to update the stack with the new state of the resource, without causing a further interruption.

:::expand{header="Need a hint?"}
* You should detach the resource from the stack, then re-import it again with the `UserData` corrected. You do not need to convert the `UserData` to Base64.
* Refer to the [Resource Importing](/intermediate/operations/resource-importing.html) lab for more guidance.
:::
::::::expand{header="Want to see the solution?"}
1. Update the `drift-detection-challenge.yaml` template to add a `DeletionPolicy` attribute with a value of `Retain` to the `Instance1` resource. Save the file.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=12}
Resources:
  Instance1:
    DeletionPolicy: Retain
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello World
:::
1. Update the stack with the updated `drift-detection-challenge.yaml` template. This tells CloudFormation that when the resource is removed from the template, it should not delete it but just stop managing it.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. Once the stack update is complete, edit the template file again to remove the whole resource declaration (you can also choose to comment it out, using the `#` character at the start of each relevant line), and save the file.
1. Update the stack with the updated template file. CloudFormation will remove the instance from the stack without terminating it.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. Edit the template file to restore the resource, and update the UserData to match the change made previously.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=19}
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
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Create a text file to describe the resources for an IMPORT operation.
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch resources-import.txt
:::
1. Copy the code below and replace the `resources-import.txt` For the [**Identifier Value**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html#resource-import-overview), specify the instance's **Physical ID**, that you noted earlier as part of this challenge.
:::code{language=json showLineNumbers=false showCopyAction=true}
[
  {
    "ResourceType":"AWS::EC2::Instance",
    "LogicalResourceId":"Instance1",
    "ResourceIdentifier": {
      "InstanceId":"i-12345abcd6789"
    }
  }
]
:::
1. Update the `cfn-workshop-drift-detection-challenge` Stack to Import resources by using the following code.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-change-set \
--stack-name cfn-workshop-drift-detection-challenge \
--change-set-name drift-challenge --change-set-type IMPORT \
--resources-to-import file://resources-import.txt \
--template-body file://drift-detection-challenge.yaml
:::
1. Execute the change set by using the following code.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation execute-change-set \
--stack-name cfn-workshop-drift-detection-challenge \
--change-set-name drift-challenge
:::
1. Wait until the `IMPORT` operation is complete by using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-import-complete \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. Verify the drift detection on the stack `cfn-workshop-drift-detection-challenge`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation detect-stack-drift \
--stack-name cfn-workshop-drift-detection-challenge
:::
1. The drift details for `Instance1` are shown in the output of `descibe-stack-resource-drifts` to confirm the instance is now in sync with the stack.
:::code{language=json showLineNumbers=true showCopyAction=false highlightLines=11,22}
{
    "StackResourceDrifts": [
        {
            "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Bucket1",
            "PhysicalResourceId": "cfn-workshop-drift-detection-challenge-bucket1-1svpxjottevmx",
            "ResourceType": "AWS::S3::Bucket",
            "ExpectedProperties": "{}",
            "ActualProperties": "{}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T17:29:29.338000+00:00"
        },
        {
            "StackId": "arn:aws:cloudformation:us-east-1:402198065244:stack/cfn-workshop-drift-detection-challenge/30dbaeb0-f965-11ed-a54c-0ea8a8f21e33",
            "LogicalResourceId": "Instance1",
            "PhysicalResourceId": "i-0113f35b272b0f04e",
            "ResourceType": "AWS::EC2::Instance",
            "ExpectedProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "ActualProperties": "{\"ImageId\":\"ami-0d52ddcdf3a885741\",\"InstanceType\":\"t2.micro\",\"UserData\":\"IyEvdXNyL2Jpbi9lbnYgYmFzaAplY2hvIEhlbGxvIFdvcmxkCg==\"}",
            "PropertyDifferences": [],
            "StackResourceDriftStatus": "IN_SYNC",
            "Timestamp": "2023-05-23T17:29:30.015000+00:00"
        }
    ]
}
:::
::::
::::tab{id="local" label="Local Development"}
1. Select the stack in the CloudFormation console, then from **Stack actions** choose **Import resources in to stack**.
1. Choose **Next**.
1. Upload the template file.
1. Enter the physical ID of the instance and choose **Next**.
1. In **Specify stack options**, choose **Next**.
1. Choose **Import resources**.
1. Once the stack operation is complete and the resource is imported, you can run drift detection on the stack to confirm the instance is now in sync with the stack template.
::::
:::::
You can find the template for the solution in `code/solutions/drift-detection/drift-detection-workshop.yaml`.

Well done! You have now learned how to repair drift without impact by deleting and re-importing a resource.
::::::

### Cleanup

Follow steps shown next to clean up the resources you created in this workshop.
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Delete the S3 bucket by using the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=false}
aws s3 rb s3://drift-detection-challenge-AWS_ACCOUNT_ID --force
:::
1. Delete the `cfn-workshoop-drift-detection-workshop` stack.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-drift-detection-workshop
:::
1. For the `cfn-workshop-drift-detection-challenge` stack, edit the template file to change the `DeletionPolicy` to `Delete`.
:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=10 highlightLines=12}
Resources:
  Instance1:
    DeletionPolicy: Delete
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      UserData: !Base64 |
        #!/usr/bin/env bash
        echo Hello Universe
:::
1. Use the AWS CLI to update the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name cfn-workshop-drift-detection-challenge \
--template-body file://drift-detection-challenge.yaml
:::
1. Once the updating of the stack is complete, go ahead and delete it.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-name cfn-workshop-drift-detection-challenge
:::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the CloudFormation Console.
1. Choose the stack created in the first lab, for example `drift-detection-workshop`.
1. Choose **Delete**, then choose the **Delete**.
1. For the `drift-detection-challenge` stack, edit the template file to change the `DeletionPolicy` to `Delete`.
1. Update the stack by selecting it, then choosing **Upload**, then **Replace current template** and uploading the updated file. Choose **Next**, then choose **Next**, then choose **Next**, and then choose **Submit**. Wait for the stack update to complete.
1. Select the `drift-detection-challenge` stack and choose **Delete**, then choose **Delete**.
::::
:::::

---

### Conclusion

In this lab, you learned how to detect drift on CloudFormation stacks to find resources which had been modified outside of CloudFormation, and see details of the changes. You learned how to verify a resource had been modified correctly back to match the template, as well as how to update the stack to match a resource’s new desired state. Finally, you learned how to correct drift by deleting and re-importing the affected resource.
