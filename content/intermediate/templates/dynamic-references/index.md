---
title: "Dynamic References"
weight: 300
---

_Lab Duration: ~30 minutes_

---

### Overview
In this module, you will learn how to use [dynamic references](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html) in your CloudFormation template to reference external values stored in AWS services that include [AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html) (formerly known as SSM) [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html), and [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).

As you describe, in your CloudFormation templates, AWS resources by taking into account [lifecycle and ownership](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html) criteria and best practices, you might also want to reference configuration values stored in a centralized place. Parameter Store provides secure, hierarchical storage for configuration data management.

In other cases, you might be required to reference sensitive information in your AWS CloudFormation templates. [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) helps you to securely encrypt, store, and retrieve credentials for your databases and other services programmatically. You can also choose to use Parameter Store [secure string parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-secure-strings) to store and reference sensitive data.

When you use a dynamic reference, CloudFormation retrieves the value of the specified reference when necessary during stack and [change set](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) operations. However, CloudFormation never stores the actual reference value.

### Topics Covered
By the end of this lab, you will be able to:

* Compose a *dynamic reference string* to access an external value in your CloudFormation template.
* Retrieve a specific version, or the *latest* version of a Parameter Store parameter.
* Retrieve a specific version of a Secrets Manager secret.
* Extract a value for a specific key, from a secret that uses a JSON data format.

### Start Lab

#### Dynamic References for Parameter Store
Consider a scenario where you are required to provide life cycle environments for your development teams. This practice often involves practices that include building and distributing custom [Amazon Machine Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMIs) with the latest operating system updates, hardening requirements, and third-party software agents you require.

After you (or a team in your organization) builds a custom AMI, you can choose to use Parameter Store to store the identifier of the AMI. This makes it easier for you to programmatically point to an AMI you wish to use when you launch EC2 instances, thus reducing the likelihood of configuration mistakes.

In this lab, you will create a Parameter Store parameter to persist an AMI ID: instead of a custom AMI, you will use the latest _Amazon Linux 2023 AMI, 64-bit x86_ available in a region of your choice. You will then reference your parameter in the `ImageId` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid) of an EC2 instance that you describe in a template.

Let’s get started!

:::alert{type="info"}
We recommend using **us-east-1 (N. Virginia)** as the _AWS Region_ for the workshop.
:::

1. Navigate to the _Launch an Instance_ Amazon EC2 [Console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LaunchInstances:), and [choose the Region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) you wish to use. Next, locate the latest *Amazon Linux 2023 AMI, (64-bit x86)*, and note the AMI ID (e.g., `ami-abcd1234`). You will use this value in the next step.

![ec2](/static/intermediate/templates/dynamic-references/ec2-console-ami-picker.png)

2. Create your parameter using the [AWS Command Line Interface](https://aws.amazon.com/cli/) (CLI). When you run the command shown next, please make sure to replace `YOUR_AMI_ID` and `YOUR_REGION` placeholders with values you need. For values, you can specify for the AWS region, see **Code** in the [Regional endpoints](https://docs.aws.amazon.com/general/latest/gr/rande.html#regional-endpoints) table; make sure to use the same region you chose when you selected the AMI to use in the previous step:
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
--name "/golden-images/amazon-linux-2" \
--value YOUR_AMI_ID \
--type "String" \
--region YOUR_REGION
:::

::alert[You can choose to create Parameter Store parameters of the type `String` or `StringList` using CloudFormation. For more details, check the documentation for [AWS::SSM::Parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html).]{type="info"}

3. If the `put-parameter` command was successful, SSM will return `Version` and `Tier`.
:::code{language=json showLineNumbers=false showCopyAction=false}
"Version": 1,
"Tier": "Standard"
:::

4. Follow steps shown next to create a dynamic reference to your parameter in an EC2 instance you describe in a template:

    1. Change directory to `code/workspace/dynamic-references`.
    2. Open the `ec2-instance.yaml` CloudFormation template in your favorite text editor.
    3. Locate the `AWS::EC2::Instance` resource type block in the template; update the template by appending, to properties in the `Properties` section, the `ImageId` property and a dynamic reference to your parameter:
       :::code{language=yaml showLineNumbers=false showCopyAction=true}
       ImageId: '{{resolve:ssm:/golden-images/amazon-linux-2}}'
       :::

With the dynamic reference above, you describe the intent of resolving the `LATEST` version of your `/golden-images/amazon-linux-2` parameter during stack runtime.

::alert[CloudFormation does not support [public parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-finding-public-parameters.html) [in dynamic references](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm). You can choose to use [SSM Parameter Types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types) to retrieve the value for a public parameter.]{type="info"}

5. It’s now time to create your stack! Follow steps below:
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. In the **Cloud9 terminal** navigate to `code/workspace/dynamic-references`:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-ec2 \
--template-body file://ec2-instance.yaml
   :::
   1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-ec2/3fabc340-e74e-11ed-9b33-0a550dedb7a1"
   :::
   1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach the **CREATE_COMPLETE** status. You need to periodically select Refresh to see the latest stack status.
   ::::
   ::::tab{id="local" label="Local development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
   1. In **Prepare template**, select **Template is ready**.
   1. In **Template source**, select **Upload a template file**.
   1. Choose the file `ec2-instance.yaml`.
   1. Enter a Stack name. For example, `cfn-workshop-dynamic-references-ec2`.
   1. Choose to use default values for **Configure stack options**, and choose **Next**.
   1. On the **Review <stack_name>** page for your stack, scroll down to the bottom, and choose **Submit**.
   1. Wait for stack status to reach the **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
   ::::
   :::::
   ::alert[You can also use dynamic references to an SSM parameter to point a specific parameter version. For example, to have CloudFormation resolve version `1` of your parameter, you use: `ImageId: '{{resolve\:ssm:/golden-images/amazon-linux-2:1}}'`. When you lock a dynamic reference to a specific version, this helps to prevent unintentional updates to your resource when you update your stack.]{type="info"}

6. Verify that the ID of the image you used for your EC2 instance matches the image ID you stored in your Parameter Store parameter. First, locate the EC2 Instance ID by navigating to the _Resources_ tab in the CloudFormation Console: look for the Physical ID of your EC2 Instance, and note its value. Next, run the following command (replace the `YOUR_INSTANCE_ID` and `YOUR_REGION` placeholder before you run the command):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ec2 describe-instances \
--instance-ids YOUR_INSTANCE_ID \
--region YOUR_REGION \
--query 'Reservations[0].Instances[0].ImageId'
:::
7. If the `describe-instances` command was successfully sent, EC2 will return `ImageId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"ami-02396cdd13e9a1257"
:::

Congratulations! You learned how to use dynamic references with an example using Parameter Store.

#### Dynamic References for AWS Secrets Manager
[AWS Secrets Manager](https://aws.amazon.com/secrets-manager) helps you secure your credentials, such as database credentials for example, so that you can consume them later programmatically without hard-coding secrets in your code. For example, you create an [AWS Lambda](https://aws.amazon.com/lambda/) function to consume your database connection information, such as hostname and port, for your [Amazon Relational Database Service (RDS)](https://aws.amazon.com/rds/) database instance.

In this lab, you will use Secrets Manager to store database *hostname*, *port*, *username*, and *password*. Next, you will use dynamic references to read *hostname* and *port* information from an `AWS::Lambda::Function` resource you will describe in a template.

Let’s get started! Choose to follow steps shown next:

1. First, you will create an Amazon RDS database, and store connection information as a secret in AWS Secrets Manager:
    1. Make sure you are in the `code/workspace/dynamic-references` directory.
    2. Open the `database.yaml` CloudFormation template in your favorite text editor.
    3. Note the following resources in the template:
       1. The resource of type `AWS::RDS::DBInstance`, with which you describe your Amazon RDS instance.
       :::alert{type="info"}
       For resources of the type `AWS::RDS::DBInstance` that don't specify the `DBClusterIdentifier` property (as in the example for this lab), if a [deletion policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) is not explicitly defined, the deletion policy defaults to `Snapshot`, and CloudFormation creates a snapshot for the resource before deleting it. In this lab, `DeletionPolicy` for the resource is set to `Delete` to skip snapshot creation on delete.
       :::
       1. The resource of type `AWS::SecretsManager::Secret`, where you will store database connection parameters, as JSON key-value pairs, in a secret named `DatabaseConnParams`:
       :::code{language=json showLineNumbers=true showCopyAction=false lineNumberStart=47}
       {
  "RDS_HOSTNAME": "${Database.Endpoint.Address}",
  "RDS_PORT": "${Database.Endpoint.Port}",
  "RDS_USERNAME": "${DBUsername}",
  "RDS_PASSWORD": "${DBPassword}"
}
       :::
2. To deploy the Database stack, follow the steps below:
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. In the **Cloud9 terminal** navigate to `code/workspace/dynamic-references`:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you. Enter your values for the `DBUsername` and `DBPassword` parameters.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-database \
--template-body file://database.yaml \
--parameters ParameterKey=DBUsername,ParameterValue='admin' \
ParameterKey=DBPassword,ParameterValue='wjznf74irj831o9'
   :::
   1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-database/5b6b44f0-e750-11ed-af8c-12a600715c03"
   :::
   1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach the **CREATE_COMPLETE** status. You need to periodically select Refresh to see the latest stack status.
   ::::
   ::::tab{id="local" label="Local development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
   1. In **Prepare template**, select **Template is ready**.
   1. In **Template source**, select **Upload a template file**.
   1. Choose the file `database.yaml`.
   1. Enter a Stack name. For example, `cfn-workshop-dynamic-references-database`.
   1. For `DBUsername`, specify the primary username for the DB instance.
   1. For `DBPassword`, specify the password for the primary user.
   :::alert{type="info"}
   Check the parameter details in the template if the username or password you enter is invalid.
   :::
   1. Choose to use default values for **Configure stack options**, and choose **Next**.
   1. On the **Review <stack_name>** page for your stack, scroll down to the bottom, and choose **Submit**.
   1. Wait for stack status to reach the **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
   ::::
   :::::

3. Next, you will create an AWS Lambda Function, and read a number of database connection parameters as [Environment Variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html) to your Lambda function, by using dynamic references to the Secrets Manager secret you created earlier.
    1. Make sure you are in the `code/workspace/dynamic-references` directory.
    2. Open the `lambda-function.yaml` CloudFormation template in your favorite text editor.
    3. The template describes an `AWS::Lambda::Function` resource type; update the template by appending the `Properties` section with the `Environment` property, with variables using dynamic references to the AWS Secret Manager secret you created earlier:
    :::code{language=yaml showLineNumbers=false showCopyAction=true}
    Environment:
  Variables:
    RDS_HOSTNAME: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'
    RDS_PORT: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_PORT}}'
    :::
4. To Deploy the Lambda stack, follow the steps below:
   :::::tabs{variant="container"}
   ::::tab{id="cloud9" label="Cloud9"}
   1. In the **Cloud9 terminal** navigate to `code/workspace/dynamic-references`:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cd cfn101-workshop/code/workspace/dynamic-references
   :::
   1. Use the AWS CLI to create the stack. The required parameters `--stack-name`, `--template-body` and `--capabilities` have been pre-filled for you.
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws cloudformation create-stack \
--stack-name cfn-workshop-dynamic-references-lambda \
--template-body file://lambda-function.yaml \
--capabilities CAPABILITY_IAM
   :::
   1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
   :::code{language=shell showLineNumbers=false showCopyAction=false}
   "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-dynamic-references-lambda/7e465860-e751-11ed-aa31-0a674dce3c49"
   :::
   1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach the **CREATE_COMPLETE** status. You need to periodically select Refresh to see the latest stack status.
   ::::
   ::::tab{id="local" label="Local development"}
   1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
   1. In **Prepare template**, select **Template is ready**.
   1. In **Template source**, select **Upload a template file**.
   1. Choose the file `lambda-function.yaml`.
   1. Enter a Stack name. For example, `cfn-workshop-dynamic-references-lambda`, and choose **Next**.
   1. Choose to use default values for **Configure stack options**, and choose **Next**.
   1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Submit**.
   1. Wait for stack status to reach the **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
   ::::
   :::::

In the template you just used, database connection parameters are retrieved during stack runtime using a dynamic string. You retrieved the value for a given key, such as `RDS_HOSTNAME`, with: `'{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'`, where `DatabaseConnParams` is the secret ID.

::alert[A secret in AWS Secrets Manager has [*versions*](https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version) holding copies of the encrypted secret value. When you change the secret value, Secrets Manager creates a new version. A secret always has a version with the staging label `AWSCURRENT`, which is the current secret value. If required, you can modify this string specifying a *version-stage* or *version-id* as such: `'{{resolve:secretsmanager:prod-DatabaseConnParams:SecretString:RDS_HOSTNAME:<version-stage>:<version-id>}}'`. When you do not specify a version, CloudFormation defaults to resolving the secret associated with the stage `AWSCURRENT`.]{type="info"}

5. When you invoke the example Lambda function you created, the function fetches `RDS_HOSTNAME` and `RDS_PORT` environment variables, and prints out their values. First, locate the Lambda function name by navigating to the _Resources_ tab in the CloudFormation Console: look for the Physical ID of your Lambda function, and note its value. Next, verify you are passing database connection parameters to your Lambda function by invoking it with the following command (replace `YOUR_FUNCTION_NAME` with your Lambda function name and `YOUR_REGION` with the value you need):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws lambda invoke \
--function-name YOUR_FUNCTION_NAME \
--region YOUR_REGION \
output.json
:::

Print the output for the above command using the following command:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cat output.json
:::

The contents of output.json will be displayed
:::code{language=shell showLineNumbers=false showCopyAction=false}
"Database: cfn-workshop-dynamic-references-database-database-rrxa105iggu0.csxwxntvtkdn.us-east-1.rds.amazonaws.com:3306"
:::

Congratulations! You learned how to use dynamic references with AWS Secrets Manager.

### Challenge
In this exercise, you will reinforce your understanding of *dynamic references.*

AWS Lambda supports specifying memory configuration for a [function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html) with the `MemorySize` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize). Your task is to create a Parameter Store parameter with the AWS CLI, where you set the memory size to use for a Lambda function that you will describe in the `lambda_memory_size.yaml` template. You will then create a dynamic reference to version `1` of the parameter you created, and verify what you built works by creating a stack with your template: call the stack `cfn-workshop-dynamic-references-lambda-memory`. Make sure you create your Parameter Store parameter in the same AWS region you choose to create your stack.

:::expand{header="Need a hint?"}
1. Review the CloudFormation [User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize) to understand how to specify the `MemorySize` configuration for a Lambda Function.
1. Review the CloudFormation [User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-pattern) for help with constructing a dynamic reference string to a specific version of a Parameter Store parameter.
:::
::::expand{header="Want to see the solution?"}
1. Create a Parameter Store parameter specifying your required memory configuration using the following command (replace `YOUR_REGION` with the value you need):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
--name "/lambda/memory-size" \
--value "256" \
--type "String" \
--region YOUR_REGION
:::
1. Open the `code/workspace/dynamic-references/lambda-memory-size.yaml` template in your favorite text editor. Update the template by appending, to the `Resources` section, the example below that include the `MemorySize` property using a dynamic reference to the parameter:
:::code{language=yaml showLineNumbers=false showCopyAction=true}
HelloWorldFunction:
  Type: AWS::Lambda::Function
  Properties:
    Role: !GetAtt FunctionExecutionRole.Arn
    Handler: index.handler
    Runtime: python3.9
    MemorySize: '{{resolve:ssm:/lambda/memory-size:1}}'
    Code:
      ZipFile: |
        import os
        def handler(event, context):
            return "Hello World!"
:::
1. As for the previous Lambda function, create a `cfn-workshop-dynamic-references-lambda-memory` CloudFormation stack to provision resources you described and updated in the template.
1. Verify the Lambda function was created using the SSM Parameter value for MemorySize by executing the [AWS Command Line Interface](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-awscli.html) (CLI). The `--query` parameter is already filled for you (replace `YOUR_REGION` with the value you need).
:::code{language=yaml showLineNumbers=false showCopyAction=true}
aws lambda list-functions --query 'Functions[*].[FunctionName,MemorySize,Environment]' --region YOUR_REGION
:::
1. If successful, `aws lambda list-functions` should displayed the details of at least two functions, one you created with RDS Environment Variables and the other with `MemorySize` set to 256.
:::code{language=json showLineNumbers=false showCopyAction=false}
[
    [
        "cfn-workshop-dynamic-references-HelloWorldFunction-xhsdJOc49hhX",
        256,
        null
    ],
    [
        "cfn-workshop-dynamic-references-l-DatabaseFunction-XO1tBoIQL3xT",
        128,
        {
            "Variables": {
                "RDS_HOSTNAME": "cfn-workshop-dynamic-references-database-database-eyffmthgvwih.csxwxntvtkdn.us-east-1.rds.amazonaws.com",
                "RDS_PORT": "3306"
            }
        }
    ]
]
:::
You can find the full solution in the `code/solutions/dynamic-references/lambda-memory-size.yaml` example template.
::::

### Cleanup
1. Delete CloudWatch Log Groups associated with Lambda functions you created with `cfn-workshop-dynamic-references-lambda`, and with `cfn-workshop-dynamic-references-lambda-memory` (if you invoked the Lambda function for the challenge section, you should have a relevant Log Group present).

    For each of the stacks, locate the Lambda function name by navigating to the **Resources** tab in the CloudFormation Console; look for the Physical ID of your Lambda function, and note its value. Then, use the following command for each of the Lambda functions you have created (replace `YOUR_FUNCTION_NAME` with your Lambda function name, and `YOUR_REGION` with the value you need):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws logs delete-log-group \
--log-group-name /aws/lambda/YOUR_FUNCTION_NAME \
--region YOUR_REGION
:::
2. Delete the two Parameter Store parameters you created to store the AMI ID and `MemorySize` configuration using the following command (replace `YOUR_REGION` with the value you need):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws ssm delete-parameters \
--names "/golden-images/amazon-linux-2" "/lambda/memory-size" \
--region YOUR_REGION
:::
3. Next, in the CloudFormation console, select the stack you created last, for example: `cfn-workshop-dynamic-references-lambda-memory`.
4. Choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.
5. Repeat steps above for other stacks you created with this lab, for example: `cfn-workshop-dynamic-references-lambda`, then `cfn-workshop-dynamic-references-database`, and `cfn-workshop-dynamic-references-ec2`.

---
### Conclusion
Great job! Now you know how to use dynamic references to specify external values you store and manage in services such as AWS Systems Manager Parameter Store, and AWS Secrets Manager. For more information, see [Using dynamic references to specify template values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html).
