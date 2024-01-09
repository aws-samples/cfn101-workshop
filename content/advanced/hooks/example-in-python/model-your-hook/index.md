---
title: "Model your hook"
weight: 430
---

So far, you've used the CloudFormation CLI to start the structure of a new project for your hook. The security team of an example company now gives you the functional requirements for the example control you'll build:

- your hook will need to be invoked when users, in the current AWS account and AWS region, create or update S3 buckets using CloudFormation. That is, when users in the account describe resources of the `AWS::S3::Bucket` [type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html) in CloudFormation templates they author, and use such templates to create or update CloudFormation stacks to, in turn, create or update S3 buckets;
- if a non-compliant S3 bucket resource is found, treat this as an error, and signal to CloudFormation that the bucket cannot be created or updated;
- the hook should also have a configuration for the account administrator to use, to ignore buckets with a given name should edge cases require an S3 bucket not to be using the versioning feature.

Next, you'll use the requirements above to model your hook using the schema file in JSON that you've read about in the previous page on this lab. To get started, open the `examplecompany-s3-versioningenabled.json` file, and replace its content with the following:

:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "typeName": "ExampleCompany::S3::VersioningEnabled",
    "description": "Example hook to validate that versioning is enabled for Amazon S3 buckets.",
    "sourceUrl": "https://catalog.workshops.aws/cfn101/en-US/advanced/hooks",
    "documentationUrl": "https://catalog.workshops.aws/cfn101/en-US/advanced/hooks",
    "typeConfiguration": {
        "properties": {
            "IgnoreS3BucketNames": {
                "description": "Comma-delimited string of Amazon S3 bucket names to exclude from versioning validation setting checks. Don't add space characters. Leave the value for this property empty (\"\") if you plan on not using it. Otherwise, make sure you specify value(s) conforming to S3 bucket naming rules (https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html). If you plan to use this property, specify values as in following examples: \"mybucket\", or \"my-bucket-1,my-bucket-2\". Do not add a trailing comma(s).",
                "default": "",
                "pattern": "^([a-z0-9][a-z0-9//.//-]*[a-z0-9]){0,1}$|^([a-z0-9][a-z0-9//.//-]*[a-z0-9]){1}(,[a-z0-9][a-z0-9//.//-]*[a-z0-9])*$",
                "type": "string"
            }
        },
        "additionalProperties": false
    },
    "required": [],
    "handlers": {
        "preCreate": {
            "targetNames": [
                "AWS::S3::Bucket"
            ],
            "permissions": []
        },
        "preUpdate": {
            "targetNames": [
                "AWS::S3::Bucket"
            ],
            "permissions": []
        }
    },
    "additionalProperties": false
}
:::

Save the updated file. As you can see, you're modeling the `IgnoreS3BucketNames` input configuration property to allow for edge-case exceptions as per the requirements, and you're targeting `AWS::S3::Bucket` resources to be examined by your hook before you create (`preCreate` handler), or update (`preUpdate` handler) a CloudFormation stack. In the schema above, you could also have added a configuration for a `preDelete` handler (which is another available invocation point for Hooks): in this case, you choose not to use this additional control as per requirements above, that are only relevant to when resources are being created or mutated, but not deleted.

::alert[With this example hook, you only plan to inspect S3 buckets' configuration values coming from the CloudFormation template when your hook is invoked. This information will be exposed to the hook automatically, and you don't need to make any API calls to AWS service(s) from your hook to retrieve bucket configuration values: this is why you are passing empty lists to the `permissions` properties in the schema above. If you would have needed to make API calls to AWS services from your hook's handler(s), you would have also needed to indicate which IAM permission(s) (for example: `s3:ListBuckets`) you required.]{type="info"}

For more information on the schema of a hook, and on modeling options, see [Modeling AWS CloudFormation Hooks](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/hooks-model.html).

Now that you've updated the schema that models your hook, it's time to refresh the documentation for your hook in the `docs/` directory and, as applicable, the content of the `hook-role.yaml` template file. Run the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn generate
:::

It's now time to write code for your hook! Choose **Next** to continue!
