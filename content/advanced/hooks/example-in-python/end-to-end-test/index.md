---
title: "End-to-end test"
weight: 480
---

Are you ready to test the hook you've worked on? For this, you'll prepare a sample CloudFormation template that describes an S3 bucket, and use it for your end-to-end tests.

To get started, change directory to the `cfn101-workshop/code/workspace/hooks` directory; as you were in the `example-hook/` directory earlier, it's easier to just run this command to go to the parent directory, that is the one you need:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd ..
:::

Next, locate the `sample-s3-bucket.template` file; open it, and append the following content at the end of the file:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration:
        Status: Enabled
:::

Next, from the directory where the file above is, use the AWS CLI to create a stack, in the `us-east-1` region, with that template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name example-hook-test \
    --template-body file://sample-s3-bucket.template \
    --region us-east-1
:::

Next, wait for the stack creation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

When done, describe the stack events with this command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-events \
    --stack-name example-hook-test \
    --region us-east-1
:::

You should see a series of events, in JSON format, for your stack. The first block on the top of the output should have an element such as: `"ResourceStatus": "CREATE_COMPLETE"` for `"StackName": "example-hook-test"`, indicating that stack creation was successful. Scroll through the output using the down arrow key on your keyboard; you should see an event like the following excerpt:

:::code{language=json showLineNumbers=false showCopyAction=false}
        {
            "StackId": "[OMITTED]",
            "EventId": "[OMITTED]",
            "StackName": "example-hook-test",
            "LogicalResourceId": "S3Bucket",
            "PhysicalResourceId": "",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "[OMITTED]",
            "ResourceStatus": "CREATE_IN_PROGRESS",
            "HookType": "ExampleCompany::S3::VersioningEnabled",
            "HookStatus": "HOOK_COMPLETE_SUCCEEDED",
            "HookStatusReason": "Hook succeeded with message: Bucket versioning is enabled.",
            "HookInvocationPoint": "PRE_PROVISION",
            "HookFailureMode": "FAIL"
        }
:::

As you can see, the hook has been invoked, and it verified the configuration of your bucket successfully! As you look through the events above this one, moving towards the top of the output, you can see that the bucket creation only started after the hook completed the validation of your bucket successfully. To exit the stack events view, press `q` key on your keyboard.

Delete the stack you just created, and wait for its deletion to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --stack-name example-hook-test \
    --region us-east-1

aws cloudformation wait stack-delete-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

Let's now test that the hook blocks the provisioning (as you configured it to run in `FAIL` mode, per your requirements) when the S3 bucket is not configured to use versioning and the bucket name is not an ignored one. Update the `sample-s3-bucket.template` file, and change the value for `Status` from `Enabled` to `Suspended`:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
        Status: Suspended
:::

Next, use the AWS CLI to create the stack again, with the updated template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name example-hook-test \
    --template-body file://sample-s3-bucket.template \
    --region us-east-1
:::

Next, wait for the operation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

In this case, the behavior you're looking for is that the stack will fail to create, because the hook will return an error. When the previous `wait` command returns back to the shell with a `StackCreateComplete failed` error, describe the stack events with this command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-events \
    --stack-name example-hook-test \
    --region us-east-1
:::

At the top of the output, you should first find an event where the stack is in the `ROLLBACK_COMPLETE` status. This means that the hook failed, as expected, because the S3 bucket was found not to be compliant, and the stack rolled back. To further validate that the hook behavior is the one you expect, scroll through the output, and you should see an event like the following excerpt:

:::code{language=json showLineNumbers=false showCopyAction=false}
        {
            "StackId": "[OMITTED]",
            "EventId": "[OMITTED]",
            "StackName": "example-hook-test",
            "LogicalResourceId": "S3Bucket",
            "PhysicalResourceId": "",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "[OMITTED]",
            "ResourceStatus": "CREATE_IN_PROGRESS",
            "HookType": "ExampleCompany::S3::VersioningEnabled",
            "HookStatus": "HOOK_COMPLETE_FAILED",
            "HookStatusReason": "Hook failed with message: Bucket versioning is not enabled.",
            "HookInvocationPoint": "PRE_PROVISION",
            "HookFailureMode": "FAIL"
        }
:::

Congratulations! You have validated that the hook blocked the creation of a non-compliant bucket.

Delete the stack you just created, and wait for its deletion to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --stack-name example-hook-test \
    --region us-east-1

aws cloudformation wait stack-delete-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

Let's go ahead and test the use case of an excluded bucket. First, let's establish a pattern for an S3 bucket name you'll use for testing, to reduce the possibility that a bucket name is already taken. The pattern you choose for the bucket name is: `example-hook-test-bucket-ACCOUNT_ID-REGION`, where `ACCOUNT_ID` is your AWS account number, and `REGION` is the region you'll choose for creating both the stack and the bucket. For more information on how to view your AWS account ID, see [View your AWS account ID
](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html#ViewYourAWSId); in this lab, you'll use the AWS CLI to get your account ID, by running the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws sts get-caller-identity \
    --query 'Account' \
    --output text
:::

You should get an output that looks like this example: `111122223333`.

Let's compose the name of the bucket that you'll add to the comma-delimited string of ignored bucket names in the hook's configuration! For the AWS region, you'll continue to use `us-east-1`; with the example account ID above, your bucket to exclude would have the following name: `example-hook-test-bucket-111122223333-us-east-1`. Next, you'll update the configuration of the hook; do you recall the `typeConfiguration.json` file you created inside the `example-hook/` directory earlier in this lab? Change directory to `example-hook/`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd example-hook
:::

Open the `typeConfiguration.json` file, and replace its content with the following shown below (you'll add a new bucket to ignore: do not forget to replace `ACCOUNT_ID` for it, with the output you saw when you ran `aws sts get-caller-identity` above):

:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "CloudFormationConfiguration": {
        "HookConfiguration": {
            "TargetStacks": "ALL",
            "FailureMode": "FAIL",
            "Properties": {
                "IgnoreS3BucketNames": "example-ignored-bucket,example-ignored-bucket1,example-hook-test-bucket-ACCOUNT_ID-us-east-1"
            }
        }
    }
}
:::

Next, you'll update the type configuration for your hook (you already used this method to set the configuration for the hook earlier on in this lab). First, get the ARN for your hook like you did before:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation list-types \
  --type HOOK \
  --filters TypeNamePrefix=ExampleCompany::S3::VersioningEnabled \
  --query 'TypeSummaries[?TypeName==`ExampleCompany::S3::VersioningEnabled`].TypeArn' \
  --output text
:::

Take note of the resulting ARN for of your hook, and use it to update the type configuration as follows (do not forget to replace the `THE_ARN_OF_YOUR_HOOK` with the ARN for your hook, and to run the command below from the `example-hook/` directory):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation set-type-configuration \
  --configuration file://typeConfiguration.json \
  --type-arn 'THE_ARN_OF_YOUR_HOOK'
:::

Now that you've updated the configuration for your hook, you'll test it by first updating the template for your test S3 bucket, and by creating a new stack next. Change directory to the `cfn101-workshop/code/workspace/hooks` directory; as you are in the `example-hook/` directory, use the `cd ..` command to go to the parent directory:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd ..
:::

Locate the `sample-s3-bucket.template` file you used earlier. Open this file: add the whole `BucketName` line underneath the `Properties` node, and leave the `Status` as `Suspended` (as you left it as such in the previous test), as follows:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'example-hook-test-bucket-${AWS::AccountId}-${AWS::Region}'
      VersioningConfiguration:
        Status: Suspended
:::

Note that, in your template snippet above, for the account ID and for the region you chose to use the relevant CloudFormation [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html), and you used the `Fn::Sub` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) (shown above in its YAML short form) to compose the resulting string for the bucket name.

Next, use the AWS CLI to create a stack, in the `us-east-1` region, with this template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name example-hook-test \
    --template-body file://sample-s3-bucket.template \
    --region us-east-1
:::

Next, wait for the stack creation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

When done, describe the stack events with this command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-events \
    --stack-name example-hook-test \
    --region us-east-1
:::

In this case, the behavior you're looking for is that the stack creation will succeed, because the hook will ignore the non-compliant bucket when it looks at the bucket's name. Scroll through the output; you should see an event like the following excerpt:

:::code{language=json showLineNumbers=false showCopyAction=false}
        {
            "StackId": "[OMITTED]",
            "EventId": "[OMITTED]",
            "StackName": "example-hook-test",
            "LogicalResourceId": "S3Bucket",
            "PhysicalResourceId": "",
            "ResourceType": "AWS::S3::Bucket",
            "Timestamp": "[OMITTED]",
            "ResourceStatus": "CREATE_IN_PROGRESS",
            "HookType": "ExampleCompany::S3::VersioningEnabled",
            "HookStatus": "HOOK_COMPLETE_SUCCEEDED",
            "HookStatusReason": "Hook succeeded with message: Ignoring versioning configuration.",
            "HookInvocationPoint": "PRE_PROVISION",
            "HookFailureMode": "FAIL"
        }
:::

As the bucket name is in the list of ignored buckets, the validation passed regardless of its versioning configuration. You've validated this aspect as well!

Delete the stack you just created, and wait for its deletion to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --stack-name example-hook-test \
    --region us-east-1

aws cloudformation wait stack-delete-complete \
    --stack-name example-hook-test \
    --region us-east-1
:::

Are you ready for a challenge? Choose **Next** to continue!
