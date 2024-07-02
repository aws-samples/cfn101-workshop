---
title: "Write contract tests"
weight: 460
---

Contract tests help you test your hook locally, thus speeding up the development lifecycle. Moreover, if you plan to make your hook available as a public extension, it is required for it to pass contract tests.

While you're not required to pass contract tests for a privately-registered hook -like the one you're working on- it is recommended to strive to write and pass contract tests anyway: not only this helps you with development velocity, but also it helps maintaining a higher quality bar.

To get started, first create the following files in an `inputs/` directory you'll also create at the root level of your hook's project; make sure you run the following commands from the `example-hook/` directory:

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir inputs/
touch inputs/inputs_1_pre_create.json
touch inputs/inputs_1_pre_update.json
touch inputs/inputs_1_invalid.json
touch inputs/inputs_2_pre_create.json
touch inputs/inputs_2_pre_update.json
touch inputs/inputs_2_invalid.json
:::

As you can see above, for this hook you chose to use two series of contract tests, denoted by `inputs_1_` and `inputs_2_` file prefixes. Each series will have different permutations of inputs that you'll pass to your hook, to validate that it will work as you expect across different scenarios.

You'll cover 2 test cases (recall the requirements you were given, as you read through): a bucket with a generic name (or with no specified name) being tested, and a bucket with a specific name that will cause it to be ignored from being validated. In the first case, the bucket is expected to pass validation on pre-create and pre-update if versioning is enabled for it in its configuration; in the second case, the bucket is expected to pass validation if its name is one of the ignored buckets in the hook's configuration (regardless of its versioning configuration). In both test cases, the hook is supposed to fail when an invalid configuration is provided as the input.

Now that you've learned the testing logic you'll use in contract tests for this hook, open each of the JSON files above, and add content shown next for each one of them:

- `inputs/inputs_1_pre_create.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "VersioningConfiguration": {
                "Status": "Enabled"
            }
        }
    }
}
:::

- `inputs/inputs_1_pre_update.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "VersioningConfiguration": {
                "Status": "Enabled"
            }
        }
    }
}
:::

- `inputs/inputs_1_invalid.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "VersioningConfiguration": {
                "Status": "Suspended"
            }
        }
    }
}
:::

- `inputs/inputs_2_pre_create.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "BucketName": "example-ignored-bucket",
            "VersioningConfiguration": {
                "Status": "Suspended"
            }
        }
    }
}
:::

- `inputs/inputs_2_pre_update.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "BucketName": "example-ignored-bucket",
            "VersioningConfiguration": {
                "Status": "Suspended"
            }
        }
    }
}
:::

- `inputs/inputs_2_invalid.json`:
:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "AWS::S3::Bucket": {
        "resourceProperties": {
            "BucketName": "example-non-ignored-bucket"
        }
    }
}
:::

::alert[In the examples above, you're specifying input configuration for the `AWS::S3::Bucket` resource type for each input file: this is because you're expected to test each target resource type that you declare in the hook's schema. If you are targeting additional resource type(s) in your hook's schema, you're required to add configuration(s) for such resource type(s) as well in each contract test input file; otherwise, contract tests will fail.]{type="warning"}

Now that you have written contract test inputs, you'll need to work on 2 additional steps:

- simulate locally the hook's type configuration; that is, how to pass the list of ignored buckets to the hook when you'll run it, and
- learn how to run contract test, so that your hook can consume the inputs above locally.

Let's start with setting up the type configuration locally: you'll need to create a `.cfn-cli/` directory in your home directory, and then add a file in it, called `typeConfiguration.json`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir ~/.cfn-cli/
touch ~/.cfn-cli/typeConfiguration.json
:::

Next, open the `~/.cfn-cli/typeConfiguration.json` file, and add the following content to it:

:::code{language=json showLineNumbers=false showCopyAction=true}
{
    "CloudFormationConfiguration": {
        "HookConfiguration": {
            "TargetStacks": "ALL",
            "FailureMode": "FAIL",
            "Properties": {
                "IgnoreS3BucketNames": "example-ignored-bucket,example-ignored-bucket1"
            }
        }
    }
}
:::

Save the file; as you can see, you're adding configuration directives that include the `IgnoreS3BucketNames` property with a comma-delimited string of buckets to ignore. For more information on developing hooks, including type configuration properties, see [AWS CloudFormation Hooks development overview](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/hooks-development-overview.html).

Now that you have set up contract test inputs and the type configuration for the hook, you'll run contract tests to pass this information to the hook and consume it from your hook's business logic. You'll need 2 terminal consoles: in the first one, you'll package up the hook and run the contract tests via the `cfn test` command; in the second one, you'll use the SAM CLI (that you've installed as part of prerequisites) to simulate a local endpoint running your hook. Let's get started:

- in a terminal window, make sure you're inside the `example-hook/` directory, and run the following command to package up the hook:

    :::code{language=shell showLineNumbers=false showCopyAction=true}
    cfn submit --dry-run
    :::

- open a new terminal window, and make sure you're inside the `example-hook/` directory (you might need to change to the `cfn101-workshop/code/workspace/hooks/example-hook/` directory first, as you opened a new terminal). Next, run the following command from the `example-hook/` directory to run a local endpoint for your hook - note that after you run the command, it will not return back to the shell (this is the expected behavior):

    :::code{language=shell showLineNumbers=false showCopyAction=true}
    sam local start-lambda
    :::

- go back to the terminal window where you packaged up the hook, make sure you're inside the `example-hook/` directory, and run the following command to run the contract tests:

    :::code{language=shell showLineNumbers=false showCopyAction=true}
    cfn test --enforce-timeout 120
    :::

You should see 2 test cases running; at the end, both should succeed.

For more information on command options available for contract tests, see [test](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-cli-test.html) in the CloudFormation Command Line Interface (CLI) User Guide.

Congratulations! You ran contract tests for your hook! In the next page, you'll submit your hook to the private registry in one AWS region; choose **Next** to continue!
