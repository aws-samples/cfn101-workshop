---
title: "Package and deploy"
weight: 600
---

_Lab Duration: ~15 minutes_

---

### Overview

In the [Basics](/basics) part of this workshop, you have deployed single YAML templates via CloudFormation console.
That was pretty easy to do so. However, in some cases, CloudFormation templates refer to other files, or artifacts.

For example Lambda source code or ZIP file, or nested CloudFormation Template files may be such “artifacts”. As you
learn in [Nested Stacks Lab](/intermediate/templates/nested-stacks), these files have to be available in S3 before
you can deploy the main CloudFormation template.

Deploying more complex stacks is a multi-stage process, but fortunately AWS-CLI provides a method for deploying
CloudFormation templates that refer to other files.

This section will cover three key commands, used to package, validate and deploy CloudFormation templates with the AWS CLI.


### Topics Covered

By the end of this lab, you will be able to:
* Identify when packaging a template is required
* Package a template using `aws cloudformation package` command
* Validate a CloudFormation template using `aws cloudformation validate-template` command
* Deploy a template using the ` aws cloudformation deploy` command

### Start Lab

Have a look at the sample project at `code/workspace/package-and-deploy` directory.

The project consists of:

* A CloudFormation template to spin up the infrastructure.
* One Lambda function.
* Requirements file to install your function dependencies.

:::code{language=shell showLineNumbers=false showCopyAction=false}
cfn101-workshop/code/workspace/package-and-deploy
├── infrastructure.template
└── lambda/
    ├── lambda_function.py
    └── requirements.txt
:::

#### Reference local files in CloudFormation template

Traditionally you would have to zip up and upload all the lambda sources to S3 first and then in the template refer to these S3 locations. This can be quite cumbersome.

However, with [aws cloudformation package](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/package.html) you can refer to the local files directly. That’s much more convenient!

If you look at `infrastructure.template` snippet, you can see the reference in the `Code` property to the local directory, line [9].

:::code{language=yaml showLineNumbers=true showCopyAction=false lineNumberStart=19}
PythonFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: cfn-workshop-python-function
    Description: Python Function to return specific TimeZone time
    Runtime: python3.8
    Role: !GetAtt LambdaBasicExecutionRole.Arn
    Handler: lambda_function.handler
    Code: lambda/ # <<< This is a local directory
:::

#### Package and Upload the artifacts

The `aws cloudformation package` performs the following actions:

1. ZIPs up the local files.
1. Uploads them to a designated S3 bucket.
1. Generates a new template where the local paths are replaced with the S3 URIs.

##### 1. Create S3 bucket

Decide on the AWS region where you will be deploying your Cloudformation template. The S3 bucket has to be in the same region as Lambda, to allow Lambda access to packaged artifacts.

::alert[Make sure to replace the name of the bucket after `s3://` with a unique name!]{type="info"}

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 mb s3://example-bucket-name --region us-east-1
:::

##### 2. Install function dependencies

Our function depends on an external library [pytz](https://pypi.org/project/pytz/). You need to install it to a local
directory with [pip](https://pypi.org/project/pip/), so it can be packaged with your function code.

From within a `code/workspace/package-and-deploy` directory run:

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install pytz --target lambda
:::

If you have `python 3` installed you may have to use `pip3` instead of `pip` for the above command.

You should see the `pytz` package inside the `lambda/` folder.

##### 3. Run the `package` command

From within a `code/workspace/package-and-deploy` directory run:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation package \
--template-file infrastructure.template \
--s3-bucket example-bucket-name \
--s3-prefix cfn-workshop-package-deploy \
--output-template-file infrastructure-packaged.template
:::

Let's have a closer look at the individual `package` options you have used in the command above.

* `--template-file` - This is a path where your CloudFormation template is located.
* `--s3-bucket` - The name of the S3 bucket where the artifacts will be uploaded to.
* `--s3-prefix` - The prefix name is a path name (folder name) for the S3 bucket.
* `--output-template-file` - The path to the file where the command writes the output AWS CloudFormation template.

##### 4. Examine the packaged files

Let's have a look at the newly generated file `infrastructure-packaged.template`.

You can notice that the `Code` property has been updated with two new attributes, `S3Bucket` and `S3Key`, lines [12-14].

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=16 highlightLines=12-14}
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
      S3Key: cfn-workshop-package-deploy/1234567890
:::

For completeness let’s also look what’s in the uploaded files. From the listing above we know the bucket and object name to download.

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 cp s3://example-bucket-name/cfn-workshop-package-deploy/1234567890 .
:::

We know that `package` will generate ZIP files, so even there is no `.zip` extension you can still `unzip` it.

:::::tabs{variant="container"}
::::tab{id="shell" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=false}
unzip -l ce6c47b6c84d94bd207cea18e7d93458

Archive:  ce6c47b6c84d94bd207cea18e7d93458
  Length      Date    Time    Name
---------  ---------- -----   ----
       12  02-12-2020 17:21   requirements.txt
      455  02-12-2020 17:18   lambda_function.py
     4745  02-13-2020 14:36   pytz/tzfile.py
:::
::::
::::tab{id="powershell" label="Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=false}
rename-item ce6c47b6c84d94bd207cea18e7d93458 packagedLambda.zip

Expand-Archive -LiteralPath packagedLambda.zip -DestinationPath packagedLambda

ls packagedLambda

Directory: C:\Users\username\cfn101-workshop\code\workspace\package-and-deploy\tmp
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        10/29/2021   4:25 PM                pytz
d-----        10/29/2021   4:25 PM                pytz-2021.3.dist-info
-a----        10/29/2021  11:19 AM            475 lambda_function.py
-a----        10/29/2021  11:19 AM             14 requirements.txt
:::
::::
:::::

### Validating a template

Sometimes a CloudFormation template deployment will fail due to syntax errors in the template.

[`aws cloudformation validate-template`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/validate-template.html)
checks a CloudFormation template to ensure it is valid JSON or YAML. This is useful to speed up development time.

Let's validate our packaged template. From within a `code/workspace/package-and-deploy` directory run:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation validate-template \
--template-body file://infrastructure-packaged.template
:::

If successful, CloudFormation will send you a response with a list of parameters, template description and capabilities.

:::code{language=json showLineNumbers=false showCopyAction=false}
{
    "Parameters": [],
    "Description": "AWS CloudFormation workshop - Package and deploy.",
    "Capabilities": [
        "CAPABILITY_IAM"
    ],
    "CapabilitiesReason": "The following resource(s) require capabilities: [AWS::IAM::Role]"
}
:::

### Deploying the "packaged" template

The [`aws cloudformation deploy`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html)
command is used to deploy CloudFormation templates using the CLI.

Let's deploy packaged template.

From within a `code/workspace/package-and-deploy` directory run:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deploy \
--template-file infrastructure-packaged.template \
--stack-name cfn-workshop-package-deploy-lambda \
--region eu-west-1 \
--capabilities CAPABILITY_IAM
:::

::alert[Note that we used the packaged template `infrastructure-packaged.template` that refers to the artifacts in S3. Not the original one with local paths!]{type="info"}

You can also set `--parameter-overrides` option to specify parameters in the template.
This can be string containing `'key=value'` pairs or a via a [supplied json file](https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-parameters.html#cli-usage-parameters-json).

##### Capabilities

You may recall when using the console, you are required to acknowledge that deploying this template may create resource
that can affect permissions in your account. This is to ensure you don't accidentally change the permissions unintentionally.

When using the CLI, you are also required to acknowledge this stack might create resources that can affect IAM permissions.
This is done using the `--capabilities` flag, as demonstrated in the previous example. Read more about the possible capabilities
in the [`aws cloudformation deploy` documentation](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html)

#### Test the Lambda

To test the Lambda function, we will use [aws lambda invoke](https://docs.aws.amazon.com/cli/latest/reference/lambda/invoke.html) command.

The Lambda function will determinate current UTC date and time. Then it will convert the UTC time to the Timezone specified in the payload option.

From your terminal run:

:::::tabs{variant="container"}
::::tab{id="sh" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke \
--function-name cfn-workshop-python-function \
--payload "{\"time_zone\": \"Europe/London\"}" \
--cli-binary-format raw-in-base64-out \
response.json
:::
::::
::::tab{id="cmd" label="CMD"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke ^
--function-name cfn-workshop-python-function ^
--payload "{\"time_zone\": \"Europe/London\"}" ^
--cli-binary-format raw-in-base64-out ^
response.json
:::
::::
::::tab{id="powershell" label="Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=true}
aws lambda invoke `
    --function-name cfn-workshop-python-function `
    --payload "{\`"time_zone\`": \`"Europe/London\`"}" `
    --cli-binary-format raw-in-base64-out `
    response.json
:::
::::
:::::

Lambda will be triggered, and the response form Lambda will be saved in `response.json` file.

You can check the result of the file by running command below:

:::::tabs{variant="container"}
::::tab{id="sh" label="Cloud9/Unix/Linux"}
:::code{language=shell showLineNumbers=false showCopyAction=true}
cat response.json
:::
::::
::::tab{id="cmd" label="CMD/Powershell"}
:::code{language=powershell showLineNumbers=false showCopyAction=true}
more response.json
:::
::::
:::::

---
### Cleanup

Choose to follow cleanup steps shown next to clean up resources you created with this lab:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Delete the S3 bucket by using the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 rb s3://example-bucket-name --force
:::
1. Delete the stack by using the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
 --stack-name cfn-workshop-package-deploy-lambda
:::
1. Wait for the Stack deletion to complete by using the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--stack-name cfn-workshop-package-deploy-lambda
:::
::::
::::tab{id="LocalDevelopment" label="LocalDevelopment"}
1. Navigate to the [AWS S3 Console](https://s3.console.aws.amazon.com/s3/).
1. Select the S3 bucket that you have created during this lab, Choose **Empty**.
1. Follow the instructions on the console to confirm the deletion of objects in the buckets.
1. Now switch back to S3 Console, Select the S3 bucket that you have created during this lab, Choose **Delete**
1. Follow the instructions on the console to confirm the deletion of the S3 bucket.
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Select the stack named `cfn-workshop-package-deploy-lambda` and choose **Delete**.
1. In the pop-up window choose **Delete**.
1. You can click the refresh button a few times until you see in the status **DELETE_COMPLETE**.
::::
:::::

---

### Conclusion
Congratulations, you have successfully packaged and deployed CloudFormation template using the command line.

* The `package` command simplifies deployment of templates that use features such as nested stacks, or refer to other local assets.
* The `validate` command can speed up development of templates by catching errors more quickly.
* The `deploy` command allows you to deploy CloudFormation templates.
