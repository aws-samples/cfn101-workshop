---
title: "Lab 09: Deployment using the CLI"
date: 2019-11-25T14:55:21Z
weight: 100
---

## Overview

So far, you have used the console to deploy CloudFormation templates. It is also possible to use the AWS CLI and AWS SDKs to deploy CloudFormation templates. In this section, you will learn how to use the AWS CLI to work with CloudFormation templates.
This section will cover three key commands, used to package, validate and deploy CloudFormation templates.

## Deploying a template using the CLI

The `aws cloudformation deploy` command is used to deploy CloudFormation templates using the CLI.
When used, it requires the a template to be passed to it. This can be either a file in S3, or locally.

You can use the `--parameter-overrides` option to specify parameters in the template. This can be either a json file, or a string containing 'key=value' pairs.

Let's deploy a CloudFormation template using the CLI.

```bash
aws cloudformation deploy \
    --template-file code/60-package-and-deploy/01-lab09-deploy.yaml \
    --stack-name cfn101-lab09-deploy \
    --parameter-overrides "EnvType=Prod" \
    --capabilities CAPABILITY_IAM
```
## Validating a template

Sometimes a CloudFormation template deployment will fail due to syntax errors in the template.
`validate-template` checks a CloudFormation template to ensure it is valid JSON or YAML. This is useful to speed up development time. 

Let's validate a template.

```bash
aws cloudformation validate-template \
    --template-body file://code/60-package-and-deploy/02-lab09-bad-template.yaml
```

Notice what happens! Try to fix the errors, then validate the template again.

## Packaging a template

Cloudformation components often reference external files in S3. An example of this the `AWS::Lambda::Function` resource. The Component requires the code for the function to be in S#. What if the external files are on your local machine?

`aws cloudformation package` is a useful command that solves this problem. When given a template that references local resources, it will upload the resources to an S3 bucket. An updated template is returned. The local file references in the template are updated to reference the uploaded assets in S3.

This command will be used in the next section when deploying nested stacks.



