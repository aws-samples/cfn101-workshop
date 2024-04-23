---
title: "Example in Python"
weight: 420
---

### Overview

In this lab, you'll follow steps to build and submit a sample hook, that you'll write in Python, to the AWS CloudFormation registry in your AWS account for a given AWS region as a private extension. You'll also navigate through the example source code implementation logic for the hook, to understand key concepts and best practices.


### Topics Covered

By the end of this lab, you will be able to:

* understand key concepts to develop a hook;
* use the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) to create a new project for a hook, run tests, and submit the hook as a private extension to the CloudFormation registry in your AWS account and for a given region;
* understand how to use the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) to test your hook locally.


### Start Lab

Let's get started! Make believe you are a member of the security team for an example organization. You're tasked with creating a hook to validate that [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) bucket resources that your AWS account users create with CloudFormation, are set up with [versioning configuration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-versioningconfiguration) enabled. For this task, you choose to use CloudFormation Hooks as a proactive validation control: you'll create a hook to enforce versioning being enabled on S3 buckets that your users describe with CloudFormation templates, and that manage with relevant CloudFormation stacks.

Your first step is to use the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) -that you've installed in the prerequisites section- to create a project for your hook. Change directory to the `cfn101-workshop/code/workspace/hooks` directory: use the following commands to create a new directory for your project, and move into it next:

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir example-hook
cd example-hook
:::

Next, use the CloudFormation CLI to create a new project for your hook; you'll be asked a number of questions - for that, you'll follow through next on this lab:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn init
:::

When prompted:

- specify `h`, followed by enter, to indicate your choice of developing a new hook;
- for the name of your hook, choose to specify: `ExampleCompany::S3::VersioningEnabled`, followed by pressing the _enter_ (or _return_ key) on your keyboard;
- follow the directions to choose `python39`, and use the _enter_ (or _return_ key) to continue;
- when asked to use Docker for platform-independent packaging, choose `Y` followed by the _enter_ (or _return_ key).

At this point, you should see a message indicating your project has been initialized. The CloudFormation CLI has created for you a number of files and directories that include, in particular:

- `.rpdk-config`: this is the project's configuration file, that contains a number of information including information on the language name (`"language": "python39",`) and the runtime (`"runtime": "python3.9",`) choices you've made. In the future, as new runtimes are made available, you might want to update both information, and then test and resubmit the hook to the registry.
- `README.md`: this in an automatically-generated file, that you'd want to update as needed for other members of the team to learn about this hook.
- `docs/`: a directory with automatically-generated documentation content. As you develop your hook, you'll want to use the `cfn generate` command to refresh content for this directory, as well as for other parts of the hook you're building.
- `examplecompany-s3-versioningenabled.json`: this is the schema model file, named after your hook: you'll start with updating this file as your next step.
- `hook-role.yaml`: this file is automatically created or regenerated when you run the `cfn generate` command. The CloudFormation CLI creates this file for you based on permissions you specify in the schema; when you use the CloudFormation CLI to submit your hook to the registry, it creates or updates a CloudFormation stack with this template that describes an IAM execution role for your hook.
- `src/`: a directory with files that you'll use to implement the business logic of your hook.
- `template.yml`: an auto-generated file for the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-reference.html#serverless-sam-cli), that you'll use to test your hook locally. Note that this file also contains runtime information (`Runtime: python3.9` for both `TypeFunction` and `TestEntrypoint`), that in the future you might want to update as well as needed (see considerations made above for the `.rpdk-config` file).

Are you ready to get the functional requirements for the hook you'll build? Choose **Next** to continue!
