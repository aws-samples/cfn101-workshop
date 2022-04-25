---
title: "Understanding change sets"
weight: 200
---

### Overview
When you update an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack, you update one or more resources in that stack to a desired new state. Due to factors that include resource dependencies, [update behaviors of stack resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html), or user error, there could be differences between the desired state and the actual, new state of a given resource.

You choose to update your stacks either [directly](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html), or with [change sets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html): the latter gives you a preview of proposed changes before you apply them, and helps prevent unexpected resource configurations or replacements.

You can create change sets by either modifying template parameter values, or by providing an updated template where you described your changes. You can also choose to create multiple change sets for the same stack, before executing the change set that best suits your requirements.

### Topics Covered
In this lab, you’ll learn:

* how to create change sets
* how to read change sets to understand what your stack will look like after the update
* how CloudFormation decides which resources need replacement, and how static and dynamic evaluations work

### Start Lab
Using a sample template, you will create a CloudFormation stack. You will then create two different change sets for this stack: one by editing the template, and another one by modifying a parameter value.

Let’s get started!

1. Change directory to: `code/workspace/understanding-changesets`.
2. Open the `bucket.yaml` CloudFormation template in your favorite text editor, and familiarize yourself with the sample template content.
3. Create a stack by following these steps:
    1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
    2. From **Create stack**, choose **With new resources (standard)**.
    3. From **Prepare template**, choose **Template is ready**.
    4. From **Template source**, choose **Upload a template file**. Choose the `bucket.yaml` template file, and then choose **Next**.
    5. Specify a stack name, for example `changesets-workshop`.
    6. Make sure to provide a unique value for the `BucketName` parameter. For more information, see [Bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html). Choose **Next**.
    7. In the next page, choose to leave all options to default values, and choose **Next**.
    8. In the review page, choose **Create Stack**.
    9. Refresh the stack creation page until you see your stack in the `CREATE_COMPLETE` status.

### Lab part 1
In this part of the lab, you will specify a property, for a given resource type, that requires [no interruption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-no-interrupt) on stack updates. You will then create a change set to preview the changes, and inspect the output of the change set operation.

Open the `bucket.yaml` CloudFormation template in your favorite text editor, and add `VersioningConfiguration` as shown below. Save the file.

```yaml
MyS3Bucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Ref BucketName
    VersioningConfiguration:
      Status: Enabled
```

Next, create your first change set:

1. In the CloudFormation console, select the `changesets-workshop` stack, and from **Stack actions**, choose **Create change set for current stack**.
2. From **Prepare template**, choose **Replace current template**. For **Template source**, choose **Upload a template file**, then select your updated `bucket.yaml` template, and choose **Next**.
3. Choose **Next** again in both the **Specify stack details** and **Configure stack options** pages, and then choose **Create change set**.
4. Specify a name for the change set, for example: `bucket-versioning-update`, as well as a description, for example: `Enable bucket versioning for MyS3Bucket.`, and choose **Create change set**.
5. Refresh the page until the status of the change set is `CREATE_COMPLETE`.
6. At the bottom of the page, you should see a summary of expected changes. Navigate to the **JSON changes** tab for more information, which should look similar to this:

```json
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Modify",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": "False",
      "moduleInfo": null,
      "details": [
        {
          "target": {
            "name": "VersioningConfiguration",
            "requiresRecreation": "Never",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Static",
          "changeSource": "DirectModification"
        }
      ],
      "changeSetId": null,
      "scope": [
        "Properties"
      ]
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
```

In the `resourceChange` structure, you can see the logical ID of the resource, the action CloudFormation will take, the Physical ID of the resource, the type of resource, and whether CloudFormation will replace the resource or not. In the `Details` structure, CloudFormation labels this change as a direct modification that will never require the bucket to be recreated (replaced) because updating the [Versioning configuration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-versioningconfiguration) property requires no interruption.

If you execute this change set, CloudFormation will then not replace your bucket, based on the configuration you provided; let's hold off on executing the change set, and create another change set.

### Lab part 2
You will now modify the value for a property, `BucketName`, that requires a [replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) on stack updates. You will then create a change set to preview your changes, and inspect the output of the change set operation.

Let’s get started!

1. In the CloudFormation console, select the `changesets-workshop` stack, and from **Stack actions**, choose **Create change set for current stack**.
2. From **Prepare template**, choose **Use current template** and choose **Next**.
3. Change the value for `BucketName` parameter by specifying a new unique bucket [name](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html), and follow the rest of the process as before to finish creating the change set.

Here’s what the **JSON changes** for this change set should look like:


```json
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Modify",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": "True",
      "moduleInfo": null,
      "details": [
        {
          "target": {
            "name": "BucketName",
            "requiresRecreation": "Always",
            "attribute": "Properties"
          },
          "causingEntity": null,
          "evaluation": "Dynamic",
          "changeSource": "DirectModification"
        },
        {
          "target": {
            "name": "BucketName",
            "requiresRecreation": "Always",
            "attribute": "Properties"
          },
          "causingEntity": "BucketName",
          "evaluation": "Static",
          "changeSource": "ParameterReference"
        }
      ],
      "changeSetId": null,
      "scope": [
        "Properties"
      ]
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
```

You can see there are two key differences from the previous example. First, the value for the `replacement` property under the `resourceChange` structure is set to `True`; second, you see two evaluations, `Static` and `Dynamic`, under the `details` structure. Let's talk about these aspects in more detail.

The value for `replacement` is `True` because you updated the `BucketName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-bucketname) that requires a replacement. CloudFormation will create a new resource (a new bucket in this case), and then delete the old one. If there are multiple changes you make on a given resource, and each change has a different value for the `requiresRecreation` field, CloudFormation replaces the resource when a recreation is required. In other words, if only one of the many changes requires a replacement, CloudFormation replaces the resources, and therefore sets the `replacement` field to `True`.

The value in the `replacement` field is indicated by the `requiresRecreation` field in the `target` structure. If the `requiresRecreation` field is `Never`, the `replacement` field is `False`. If the `requiresRecreation` field is `Always` and the `evaluation` field is `Static`, `replacement` is `True`. However, if the `requiresRecreation` field is `Always` and the `evaluation` field is `Dynamic`, `replacement` is `Conditionally`.

To understand why there are two different evaluations for the same resource in the above example, let’s see what each of these means.

A `Static` evaluation means that CloudFormation can determine the value before executing the change set because it already has all the information it needs to evaluate the changes.

In some cases, CloudFormation can determine a value only after you execute a change set. CloudFormation labels those changes as `Dynamic` evaluations. In other words, if you reference an updated resource that is conditionally replaced, CloudFormation can't determine whether the reference to the updated resource will change. For example, if your template includes a reference to a resource that is conditionally replaced, the value of the reference (the physical ID of the resource) might change, depending on whether the resource will be recreated. If the resource is recreated, it will have a new physical ID, so all references to that resource will also be updated.  In the above example, you are referencing an updated parameter which results in a `Dynamic` evaluation.

Now, let's focus on static evaluation-related data for your changes.  In the above example, the static evaluation shows that the change is a result of a modified parameter reference value, `ParameterReference`: the exact parameter that was changed is indicated by the `causingEntity` field, that is `BucketName` in this case.

### Challenge
Open, in your favorite text editor, the template file named `changeset-challenge.yaml`, that you can find in the `code/workspace/understanding-changesets` directory. This file is a modified version of the `bucket.yaml` template you used earlier: note the logical ID of the Amazon S3 bucket resource, that is `NewS3Bucket` instead of `MyS3Bucket`. Note that there is also a new resource described in the template: an [Amazon Simple Queue Service](https://aws.amazon.com/sqs/) (SQS) [queue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html), with the `MySqsQueue` logical ID.

What do you think will happen if you create a new change set for the `changesets-workshop` stack using the `changeset-challenge.yaml` file? How many resources will be added? Will any resource be removed? Will you be able to get the physical ID of the queue from the **JSON changes** of the change set?

Create a change set with this file, and see if you were able to correctly determine the proposed changes.

::expand[* When you change the logical ID of a resource in your template, and you update your stack with your updated template, CloudFormation tries to replace the resource.]{header="Need a hint?"}
:::expand{header="Want to see the solution?"}
* In addition to adding the new `MySqsQueue` queue resource, CloudFormation will try to create a new bucket with the `NewS3Bucket` logical ID, and delete `MyS3Bucket`. Physical IDs of new resources are not available until they are created. Here’s what the **JSON changes** should look like:

```json
[
  {
    "resourceChange": {
      "logicalResourceId": "MyS3Bucket",
      "action": "Remove",
      "physicalResourceId": "understanding-changesets-123",
      "resourceType": "AWS::S3::Bucket",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "NewS3Bucket",
      "action": "Add",
      "physicalResourceId": null,
      "resourceType": "AWS::S3::Bucket",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  },
  {
    "resourceChange": {
      "logicalResourceId": "MySqsQueue",
      "action": "Add",
      "physicalResourceId": null,
      "resourceType": "AWS::SQS::Queue",
      "replacement": null,
      "moduleInfo": null,
      "details": [],
      "changeSetId": null,
      "scope": []
    },
    "hookInvocationCount": null,
    "type": "Resource"
  }
]
```
:::
### Cleanup

To clean up resources you created with this lab:

1. From the CloudFormation console, select the stack named `changesets-workshop`.
2. Choose **Delete**, and then **Delete Stack** to delete your stack and change sets you created for it.

---

### Conclusion
Nicely done!

You learned how to create change sets, how to read a change set output, and how CloudFormation decides which resources need to be replaced based on resource configuration changes you make.
