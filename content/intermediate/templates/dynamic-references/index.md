---
title: "Dynamic References"
weight: 300
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

In this lab, you will create a Parameter Store parameter to persist an AMI ID: instead of a custom AMI, you will use the latest _Amazon Linux 2 AMI, 64-bit x86_ available in a region of your choice. You will then reference your parameter in the `ImageId` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid) of an EC2 instance that you describe in a template.

Let’s get started! Choose to follow steps shown next:

1. Navigate to the Amazon EC2 [Console](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LaunchInstanceWizard:), and [choose the Region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) you wish to use. Next, locate the latest *Amazon Linux 2 AMI, (64-bit x86)*, and note the AMI ID (e.g., `ami-abcd1234`). You will use this value in the next step.

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

3. Follow steps shown next to create a dynamic reference to your parameter in an EC2 instance you describe in a template:

    1. change directory to `code/workspace/dynamic-references`.
    2. Open the `ec2-instance.yaml` CloudFormation template in your favorite text editor.
    3. Locate the `AWS::EC2::Instance` resource type block in the template; update the template by appending, to properties in the `Properties` section, the `ImageId` property and a dynamic reference to your parameter:

       :::code{language=yaml showLineNumbers=false showCopyAction=true}
       ImageId: '{{resolve\:ssm:/golden-images/amazon-linux-2}}'
       :::

With the dynamic reference above, you describe the intent of resolving the `LATEST` version of your `/golden-images/amazon-linux-2` parameter during stack runtime.

::alert[CloudFormation does not support [public parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-finding-public-parameters.html) [in dynamic references](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm). You can choose to use [SSM Parameter Types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types) to retrieve the value for a public parameter.]{type="info"}

4. It’s now time to create your stack! Follow steps below:

    1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
    2. In **Prepare template**, select **Template is ready**.
    3. In **Template source**, select **Upload a template file**.
    4. Choose the file `ec2_instance.yaml`.
    5. Enter a Stack name. For example, `cfn-workshop-ec2-stack`.
    6. Choose to use default values for **Configure stack options**, and choose **Next**.
    7. On the **Review** page for your stack, scroll down to the bottom, and choose **Create stack**.
    8. You can view the progress of stack being created in the CloudFormation Console, by refreshing the stack creation page.
    9. Refresh the page until you see the `CREATE_COMPLETE` status for your stack.

::alert[You can also use dynamic references to an SSM parameter to point a specific parameter version. For example, to have CloudFormation resolve version `1` of your parameter, you use: `ImageId: '{{resolve\:ssm:/golden-images/amazon-linux-2:1}}'`. When you lock a dynamic reference to a specific version, this helps to prevent unintentional updates to your resource when you update your stack.]{type="info"}

5. Verify that the ID of the image you used for your EC2 instance matches the image ID you stored in your Parameter Store parameter. First, locate the EC2 Instance ID by navigating to the **Resources** tab in the CloudFormation Console: look for the Physical ID of your EC2 Instance, and note its value. Next, run the following command (replace the `YOUR_INSTANCE_ID` and `YOUR_REGION` placeholder before you run the command):

   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws ec2 describe-instances \
    --instance-ids YOUR_INSTANCE_ID \
    --region YOUR_REGION \
    --query 'Reservations[0].Instances[0].ImageId'
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
        1. the resource of type `AWS::RDS::DBInstance`, with which you describe your Amazon RDS instance;
        2. the resource of type `AWS::SecretsManager::Secret`, where you will store database connection parameters, as JSON key-value pairs, in a secret named `DatabaseConnParams`:
   ```json
   {
       "RDS_HOSTNAME": "${Database.Endpoint.Address}",
       "RDS_PORT": "${Database.Endpoint.Port}",
       "RDS_USERNAME": "${DBUsername}",
       "RDS_PASSWORD": "${DBPassword}"
   }
   ```
2. To deploy the Database stack, follow the steps below:
    1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
    2. In **Prepare template**, select **Template is ready**.
    3. In **Template source**, select **Upload a template file**.
    4. Choose the file `database.yaml`.
    5. Enter a Stack name. For example, `cfn-workshop-database-stack`.
    6. For `DBUsername`, specify the primary username for the DB instance.
    7. For `DBPassword`, specify the password for the primary user.
    8. Choose to use default values for **Configure stack options**, and choose **Next**.
    9. On the **Review** page for your stack, scroll down to the bottom, and choose **Create stack**.
    10. You can view the progress of stack being created in the CloudFormation Console, by refreshing the stack creation page.
    11. Refresh the page until you see the `CREATE_COMPLETE` status for your stack.
3. Next, you will create an AWS Lambda Function, and read a number of database connection parameters as [Environment Variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html) to your Lambda function, by using dynamic references to the Secrets Manager secret you created earlier.
    1. Make sure you are in the `code/workspace/dynamic-references` directory.
    2. Open the `lambda-function.yaml` CloudFormation template in your favorite text editor.
    3. The template describes an `AWS::Lambda::Function` resource type; update the template by appending the `Properties` section with the `Environment` property, with variables using dynamic references to the AWS Secret Manager secret you created earlier:
   ```yaml
   Environment:
     Variables:
       RDS_HOSTNAME: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_HOSTNAME}}'
       RDS_PORT: '{{resolve:secretsmanager:DatabaseConnParams:SecretString:RDS_PORT}}'
   ```
4. To Deploy the Lambda stack, follow the steps below:
    1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and choose **Create stack With new resources (standard)**.
    2. In **Prepare template**, select **Template is ready**.
    3. In **Template source**, select **Upload a template file**.
    4. Choose the file `lambda_function.yaml`.
    5. Enter a Stack name. For example, `cfn-workshop-lambda-stack`, and choose **Next**.
    6. Choose to use default values for **Configure stack options**, and choose **Next**.
    7. On the **Review** page for your stack, scroll down to the bottom, and select the IAM Capabilities check box as shown in the following example:
       ![Acknowledge IAM Capability](/static/intermediate/templates/dynamic-references/iam-capability.png)
    8. Choose **Create** stack. Refresh the page until you see your stack in the `CREATE_COMPLETE` status.

   In the template you just used, database connection parameters are retrieved during stack runtime using a dynamic string. You retrieved the value for a given key, such as `RDS_HOSTNAME`, with: `'{{resolve\:secretsmanager\:DatabaseConnParams\:SecretString\:RDS_HOSTNAME}}'`, where `DatabaseConnParams` is the secret ID.

   ::alert[A secret in AWS Secrets Manager has [*versions*](https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html#term_version) holding copies of the encrypted secret value. When you change the secret value, Secrets Manager creates a new version. A secret always has a version with the staging label `AWSCURRENT`, which is the current secret value. If required, you can modify this string specifying a *version-stage* or *version-id* as such: `'{{resolve\:secretsmanager\:prod-DatabaseConnParams\:SecretString\:RDS_HOSTNAME:<version-stage>:<version-id>}}'`. When you do not specify a version, CloudFormation defaults to resolving the secret associated with the stage `AWSCURRENT`.]{type="info"}

5. When you invoke the example Lambda function you created, the function fetches `RDS_HOSTNAME` and `RDS_PORT` environment variables, and prints out their values. First, locate the Lambda function name by navigating to the **Resources** tab in the CloudFormation Console: look for the Physical ID of your Lambda function, and note its value. Next, verify you are passing database connection parameters to your Lambda function by invoking it with the following command (replace `YOUR_FUNCTION_NAME` with your Lambda function name and `YOUR_REGION` with the value you need):
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   aws lambda invoke \
    --function-name YOUR_FUNCTION_NAME \
    --region YOUR_REGION \
    output.json
   :::

   Print the output for the above command using the following command:
   :::code{language=shell showLineNumbers=false showCopyAction=true}
   cat output.json
   "Database: db.us-east-1.rds.amazonaws.com:3306"
   :::

Congratulations! You learned how to use dynamic references with AWS Secrets Manager.

### Challenge

In this exercise, you will reinforce your understanding of *dynamic references.*

AWS Lambda supports specifying memory configuration for a [function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html) with the `MemorySize` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize). Your task is to create a Parameter Store parameter with the AWS CLI, where you set the memory size to use for a Lambda function that you will describe in the `lambda_memory_size.yaml` template. You will then create a dynamic reference to version `1` of the parameter you created, and verify what you built works by creating a stack with your template: call the stack `cfn-workshop-lambda-memory-size-stack`. Make sure you create your Parameter Store parameter in the same AWS region you choose to create your stack.

:::expand{header="Need a hint?"}
* Review the CloudFormation [User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html#cfn-lambda-function-memorysize) to understand how to specify the `MemorySize` configuration for a Lambda Function.
* Review the CloudFormation [User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-pattern) for help with constructing a dynamic reference string to a specific version of a Parameter Store parameter.
:::

::::expand{header="Want to see the solution?"}
* Create a Parameter Store parameter specifying your required memory configuration using the following command (the example uses the `us-east-1` region - update this value accordingly):

:::code{language=yaml showLineNumbers=false showCopyAction=true}
aws ssm put-parameter \
    --name "/lambda/memory-size" \
    --value "256" \
    --type "String" \
    --region YOUR_REGION
:::

* Open the `code/workspace/dynamic-references/lambda-memory-size.yaml` template in your favorite text editor. Update the template by appending, to the `Resources` section, the example below that include the `MemorySize` property using a dynamic reference to the parameter:
```yaml
HelloWorldFunction:
  Type: AWS::Lambda::Function
  Properties:
    Role: !GetAtt FunctionExecutionRole.Arn
    Handler: index.handler
    Runtime: python3.7
    MemorySize: '{{resolve:ssm:/lambda/memory-size:1}}'
    Code:
      ZipFile: |
        import os
        def handler(event, context):
            return "Hello World!"
```

Create a `cfn-workshop-lambda-memory-size-stack` CloudFormation stack to provision resources you described and updated in the template.

You can find the full solution in the `code/solutions/dynamic-references/lambda-memory-size.yaml` example template.
::::

### Cleanup
1. Delete CloudWatch Log Groups associated with Lambda functions you created with `cfn-workshop-lambda-stack`, and with `cfn-workshop-lambda-memory-size-stack` (if you invoked the Lambda function for the challenge section, you should have a relevant Log Group present). For each of the stacks, locate the Lambda function name by navigating to the **Resources** tab in the CloudFormation Console; look for the Physical ID of your Lambda function, and note its value. Then, use the following command for each of the Lambda functions you have created (replace `YOUR_FUNCTION_NAME` with your Lambda function name, and `YOUR_REGION` with the value you need):
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
3. Next, in the CloudFormation console, select the stack you created last, for example: `cfn-workshop-lambda-memory-size-stack`.
4. Choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.
5. Repeat steps above for other stacks you created with this lab, for example: `cfn-workshop-lambda-stack`, then `cfn-workshop-database-stack`, and `cfn-workshop-ec2-stack`.

---
### Conclusion
Great job! Now you know how to use dynamic references to specify external values you store and manage in services such as AWS Systems Manager Parameter Store, and AWS Secrets Manager. For more information, see [Using dynamic references to specify template values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html).
