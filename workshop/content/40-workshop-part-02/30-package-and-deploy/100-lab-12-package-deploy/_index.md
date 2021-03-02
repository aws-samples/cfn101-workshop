---
title: "Lab 12: Package and Deploy"
date: 2019-11-25T14:55:21Z
weight: 100
---

### Overview

In the [Part 01](/30-workshop-part-01.html) of this workshop, you have deployed single YAML templates via CloudFormation console. That was pretty easy to do so. However, in some cases, CloudFormation templates refer to other files, or artifacts.

For example Lambda source code or ZIP file, or nested CloudFormation Template files may be such “artifacts”. As you learn in [Nested Stacks Lab](/10-nested-stacks/100-lab-10-nested-stacks), these files have to be available in S3 before you can deploy the main CloudFormation template.

Deploying more complex stacks is a multi-stage process, but fortunately AWS-CLI provides a method for deploying CloudFormation templates that refer to other files.

This section will cover three key commands, used to package, validate and deploy CloudFormation templates with the AWS CLI.


### Topics Covered

By the end of this lab, you will be able to:
* Identify when packaging a template is required
* Package a template using `aws cloudformation package` command
* Validate a CloudFormation template using `aws cloudformation validate-template` command
* Deploy a template using the ` aws cloudformation deploy` command

### Start Lab

Have a look at the sample project at `code/60-package-and-deploy/` directory.

The project consists of:

* A CloudFormation template to spin up the infrastructure.
* One Lambda function.
* Requirements file to install your function dependencies.

```
cfn101-workshop/code/60-package-and-deploy$ tree -F .
├── infrastructure.template
└── lambda/
    ├── lambda_function.py
    └── requirements.txt
```


#### Reference local files in CloudFormation template

Traditionally you would have to zip up and upload all the lambda sources to S3 first and then in the template refer to these S3 locations. This can be quite cumbersome.

However, with [aws cloudformation package](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html) you can refer to the local files directly. That’s much more convenient!

If you look at `infrastructure.template` snippet, you can see the reference in the `Code` property to the local directory.

```yaml {hl_lines=[9]}
PythonFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: cfn-workshop-python-function
    Description: Python Function to return specific TimeZone time
    Runtime: python3.8
    Role: !GetAtt LambdaBasicExecutionRole.Arn
    Handler: lambda_function.handler
    Code: lambda/                                 # <<< This is a local directory
    TracingConfig:
      Mode: Active
```

#### Package and Upload the artifacts

The `aws cloudformation package` does follow actions:

1. ZIPs up the local files.
1. Uploads them to a designated S3 bucket.
1. Generates a new template where the local paths are replaced with the S3 URIs.

##### 1. Create S3 bucket

Decide on the AWS region where you will be deploying your Cloudformation template. The S3 bucket has to be in the same region as Lambda, to allow Lambda access to packaged artifacts.

{{% notice note %}}
Make sure to replace the name of the bucket after `s3://` with a unique name!
{{% /notice %}}

```
aws s3 mb s3://example-bucket-name --region eu-west-1
```

##### 2. Install function dependencies

Our function depends on an external library [pytz](https://pypi.org/project/pytz/). You need to install it to a local directory with [pip](https://pypi.org/project/pip/), so it can be packaged with your function code.

From within a `code/60-package-and-deploy` directory run:

```
pip install pytz --target lambda
```

You should see the `pytz` package inside the `lambda/` folder.

##### 3. Run the `package` command

From within a `code/60-package-and-deploy` directory run:

```shell script
aws cloudformation package \
--template-file infrastructure.template \
--s3-bucket example-bucket-name \
--s3-prefix lambda-function \
--output-template-file infrastructure-packaged.template
```

Let's have a closer look at the individual `package` options you have used in the command above.

* `--template-file` - This is a path where your CloudFormation template is located.
* `--s3-bucket` - The name of the S3 bucket where the artifacts will be uploaded to.
* `--s3-prefix` - The prefix name is a path name (folder name) for the S3 bucket.
* `--output-template-file` - The path to the file where the command writes the output AWS CloudFormation template.

##### 4. Examine the packaged files

Let's have a look at the newly generated file `infrastructure-packaged.template`.

You can notice that the `Code` property has been updated with two new attributes, `S3Bucket` and `S3Key`.

```yaml {hl_lines=[12,13,14]}
  PythonFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: cfn-workshop-python-function
      Description: Python Function to return specific TimeZone time
      Runtime: python3.8
      Role:
        Fn::GetAtt:
        - LambdaBasicExecutionRole
        - Arn
      Handler: lambda_function.handler
      Code:
        S3Bucket: example-bucket-name
        S3Key: lambda-function/7e87fc97a46c3533bbaee7b5b3e215ee
      TracingConfig:
        Mode: Active
```

For completeness let’s also look what’s in the uploaded files. From the listing above we know the bucket and object name to download.

```
aws s3 cp s3://example-bucket-name/lambda-function/ce6c47b6c84d94bd207cea18e7d93458 .
```

We know that `package` will ZIP files, so even there is no `.zip` extension you can still `unzip` it.

```shell script
unzip -l ce6c47b6c84d94bd207cea18e7d93458

Archive:  ce6c47b6c84d94bd207cea18e7d93458
  Length      Date    Time    Name
---------  ---------- -----   ----
       12  02-12-2020 17:21   requirements.txt
      455  02-12-2020 17:18   lambda_function.py
     4745  02-13-2020 14:36   pytz/tzfile.py
...
```

### Validating a template

Sometimes a CloudFormation template deployment will fail due to syntax errors in the template.

[`aws cloudformation validate-template`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/validate-template.html) checks a CloudFormation template to ensure it is valid JSON or YAML. This is useful to speed up development time.

Let's validate our packaged template. From within a `code/60-package-and-deploy` directory run:

```bash
aws cloudformation validate-template \
  --template-body file://infrastructure-packaged.template
```

If successful, CloudFormation will send you a response with a list of parameters, template description and capabilities.

```json
{
    "Parameters": [],
    "Description": "CFN 201 Workshop - Lab 12 Helper Scripts. ()",
    "Capabilities": [
        "CAPABILITY_IAM"
    ],
    "CapabilitiesReason": "The following resource(s) require capabilities: [AWS::IAM::Role]"
}
```

### Deploying the "packaged" template

The [`aws cloudformation deploy`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html) command is used to deploy CloudFormation templates using the CLI.

Let's deploy packaged template.

From within a `code/60-package-and-deploy` directory run:

```bash
aws cloudformation deploy \
--template-file infrastructure-packaged.template \
--stack-name cfn-workshop-lambda \
--region eu-west-1 \
--capabilities CAPABILITY_IAM
```

{{% notice note %}}
Note that we used the packaged template `infrastructure-packaged.template` that refers to the artifacts in S3. Not the original one with local paths!
{{% /notice %}}

You can also set `--parameter-overrides` option to specify parameters in the template.
This can be string containing `'key=value'` pairs or a via a [supplied json file](https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-parameters.html#cli-usage-parameters-json).

##### Capabilities

You may recall when using the console, you are required to acknowledge that deploying this template may create resource that can affect permissions in your account. This is to ensure you don't accidentally change the permissions unintentionally.

When using the CLI, you are also required to acknowledge this stack might create resources that can affect IAM permissions. This is done using the `--capabilities` flag, as demonstrated in the previous example.
Read more about the possible capabilities in the [`aws cloudformation deploy` documentation](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html)

#### Test the Lambda

To test the Lambda function, we will use [aws lambda invoke](https://docs.aws.amazon.com/cli/latest/reference/lambda/invoke.html) command.

The Lambda function will determinate current UTC date and time. Then it will convert the UTC time to the Timezone specified in the payload option.

From your terminal run:

```shell script
aws lambda invoke \
--function-name cfn-workshop-python-function \
--payload '{"time_zone": "Europe/London"}' \
--cli-binary-format raw-in-base64-out \
response.json
```

Lambda will be triggered, and the response form Lambda will be saved in `response.json` file.

You can check the result of the file by running command below:

```shell script
echo "$(<response.json)"
```

You should get a result similar to this:

```shell script
{"message": "Current date/time in TimeZone *Europe/London* is: 2020-02-13 16:22"}
```

---
### Conclusion
Congratulations, you have successfully packaged and deployed CloudFormation template using the command line.

* The `package` command simplifies deployment of templates that use features such as nested stacks, or refer to other local assets.
* The `validate` command can speed up development of templates by catching errors more quickly.
* The `package` command allows you to deploy CloudFormation templates.
