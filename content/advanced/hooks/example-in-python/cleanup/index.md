---
title: "Cleanup"
weight: 495
---

You'll start with deregistering your hook:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type \
    --type-name ExampleCompany::S3::VersioningEnabled \
    --type HOOK \
    --region us-east-1
:::

Next, you'll delete the stack, created or updated for you by the CloudFormation CLI that you've used to submit the hook to the private registry, by first removing its termination protection:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-termination-protection \
    --no-enable-termination-protection \
    --stack-name examplecompany-s3-versioningenabled-role-stack \
    --region us-east-1
:::

Delete the stack mentioned above:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --stack-name examplecompany-s3-versioningenabled-role-stack \
    --region us-east-1

aws cloudformation wait stack-delete-complete \
    --stack-name examplecompany-s3-versioningenabled-role-stack \
    --region us-east-1
:::

Next, before deleting objects from the artifacts bucket created by the `CloudFormationManagedUploadInfrastructure` stack (you've learned about it earlier on this lab), and the stack itself (if you'll choose to do so), you'll need to delete artifacts that you've generated as part of submitting the hook to the registry: this includes the ZIP archive for the hook's code. Start with identifying name of the S3 bucket that the managed upload infrastructure stack created for you:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --query "StackResources[?LogicalResourceId=='ArtifactBucket'].PhysicalResourceId" \
    --region us-east-1 \
    --output text
:::

Make a note of the bucket name returned by the command; for example, `cloudformationmanageduploadinfrast-artifactbucket-[...omitted...]`. Next, list the bucket's content:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 ls s3://cloudformationmanageduploadinfrast-artifactbucket-[...omitted...]
:::

Make a note of the ZIP file for your hook, that should look like this: `examplecompany-s3-versioningenabled-YYYY-MM-DDTHH-MM-SS.zip`. The bucket where this object is stored has versioning enabled, and you'll need to get the object's version ID with this command (make sure to replace the name of the bucket and of the object):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api list-object-versions \
    --bucket cloudformationmanageduploadinfrast-artifactbucket-[...omitted...] \
    --prefix examplecompany-s3-versioningenabled-YYYY-MM-DDTHH-MM-SS.zip \
    --query "Versions[*].VersionId" --output text
:::

Make a note of the version ID, that should look like this: `abcdEXAMPLEabcdEXAMPLEabcdEXAMPLE`; next, delete the object version by making sure to replace the bucket name, the object name, and the version ID:

:::code{language=shell showLineNumbers=false showCopyAction=false}
aws s3api delete-object \
    --bucket cloudformationmanageduploadinfrast-artifactbucket-[...omitted...] \
    --key examplecompany-s3-versioningenabled-YYYY-MM-DDTHH-MM-SS.zip \
    --version-id abcdEXAMPLEabcdEXAMPLEabcdEXAMPLE
:::

If you have performed more than one registry submission for your hook as part of this lab, you might find in the bucket more object(s), whose name start(s) with `examplecompany-s3-versioningenabled-`, and that you would want to remove as well in the same way as shown above.

::alert[If you're currently using your AWS account to create CloudFormation extensions, you might find other objects in the S3 buckets managed by the `CloudFormationManagedUploadInfrastructure` stack (the artifact bucket, and the access log bucket as well), that you might choose to retain. If you wish to proceed with deleting this data and managed upload infrastructure, follow steps shown next; otherwise, skip the remaining part of this cleanup.]{type="warning"}

Next, retrieve the name of the access log bucket:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-resources \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --query "StackResources[?LogicalResourceId=='AccessLogsBucket'].PhysicalResourceId" \
    --region us-east-1 \
    --output text
:::

Make a note of the bucket name (example: `cloudformationmanageduploadinfra-accesslogsbucket--[...omitted...]`. List its content (replace the bucket name):

:::code{language=shell showLineNumbers=false showCopyAction=false}
aws s3 ls s3://cloudformationmanageduploadinfra-accesslogsbucket--[...omitted...]
:::

As described on this [page](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html#how-logs-delivered), Amazon S3 periodically collects and consolidates access logs when you enable server access logging for your bucket (that is, in this case, the bucket for artifacts using the logs bucket), and then uploads the logs to the target logging bucket. If you do not see objects in the logs bucket above at this time, there might be a chance, depending on your case, that logs might be delivered whilst you are attempting to delete the logs bucket later on, if you choose to do so. You cannot delete a bucket with objects in it; if this is the case, you'll get an error when deleting the stack that created the logs bucket: if you choose to delete logs in your logs bucket, use the same process you chose to use above for objects in the artifacts bucket, before (re)attempting to delete the bucket (or the stack that creates it; see steps below for more information).

Next, update the `CloudFormationManagedUploadInfrastructure` stack's settings to disable the `DeletionPolicy: Retain` and `UpdateReplacePolicy: Retain` for both `AccessLogsBucket` and `EncryptionKey` resources. First, get the template for the stack, and save it to the `CloudFormationManagedUploadInfrastructure.template` file on your machine:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation get-template \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --query TemplateBody \
    --region us-east-1 \
    --output text > CloudFormationManagedUploadInfrastructure.template
:::

Open the `CloudFormationManagedUploadInfrastructure.template` file with your text editor, and:
- replace all occurrences of `DeletionPolicy: Retain` with `DeletionPolicy: Delete`;
- replace all occurrences of `UpdateReplacePolicy: Retain` with `UpdateReplacePolicy: Delete`.

Save the updated template, and use it to update the stack next:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --template-body file://CloudFormationManagedUploadInfrastructure.template \
    --capabilities CAPABILITY_IAM \
    --region us-east-1

aws cloudformation wait stack-update-complete \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --region us-east-1
:::

Delete the updated template copy on your machine:

:::code{language=shell showLineNumbers=false showCopyAction=true}
rm CloudFormationManagedUploadInfrastructure.template
:::

Remove the termination protection from the stack:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-termination-protection \
    --no-enable-termination-protection \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --region us-east-1
:::

Delete the stack:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --region us-east-1

aws cloudformation wait stack-delete-complete \
    --stack-name CloudFormationManagedUploadInfrastructure \
    --region us-east-1
:::

Almost done! Choose **Next** to continue!
