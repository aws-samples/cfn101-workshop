---
title: 'Pseudo parameters'
date: 2021-12-11T13:36:34Z
weight: 500
---

### Overview

In this lab, you will learn how to use [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) to write reusable templates.



### Topics Covered



By the end of this lab, you will be able to:

+ Leverage pseudo parameters for template portability best practices
+ Identify sample use cases for leveraging pseudo parameters

When working with CloudFormation templates, one of the things you should aim for is to write modular and reusable templates to facilitate reuse of templates across AWS Accounts and Regions. In addition to [CloudFormation parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html), you can choose to engineer your template to use [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html). Pseudo parameters are parameters predefined by CloudFormation.

You use a pseudo parameter the same way you use a parameter, as an argument for the [Ref intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html).

In this module, you will use the three pseudo parameters below:

* [AWS::AccountId](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid)
    * Returns the Account ID of the Account you choose to create the stack off of your template
* [AWS::Region](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region)
    * Returns the name of the AWS Region where you choose to create the stack
* [AWS::Partition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-partition)
    * Returns the name of the AWS partition. For standard AWS Regions, the partition is `aws`. The partition for resources in the China (Beijing and Ningxia) Region is `aws-cn` and the partition for resources in the AWS GovCloud (US-West)) region is `aws-us-gov`.  

For more information on available pseudo parameters, see the [pseudo parameters reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) in the documentation.


Let’s walk through an example of how to leverage pseudo parameters.




### Start Lab


* Go to the `code/workspace` directory in the cfn101-workshop [github repo](https://github.com/aws-samples/cfn101-workshop/tree/main/code/workspace).
* Open the `pseudo-parameters.yaml` file.
* Copy the code as you go through the topics below.


In the following example, you choose to use [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html#what-is-a-parameter) to centrally store a configuration information, such as the username for your database. For this, you choose to describe an `AWS::SSM::Parameter` resource in your CloudFormation template where you will store the username value. You then choose to write an IAM policy to describe action(s) you wish to grant to a Lambda function you will use to consume your parameter store value. You choose to start with describing your IAM policy, where you reference the SSM parameter you create: this will require you to know the Amazon Resource Name (ARN) of the SSM parameter. First, you check the return values section for the resource (the SSM parameter in this case): in the relevant [documentation page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html#aws-resource-ssm-parameter-return-values), you see that `Ref` returns the parameter name, and `Fn::GetAtt` returns the type and the value. Since the ARN is not available as an output value for that resource type today, you can choose to leverage pseudo parameters to construct the ARN.



In this example, you want to construct the resource ARN like one below using pseudo parameters. Let's say, for example, you have a sample parameter called `dbUsername` that you create in the `us-east-1` region, and in the AWS account `111122223333`; an example parameter ARN is constructed as in this example policy snippet:


```json
{
    "Version": "2012-10-17",
    "Statement": [

        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:us-east-1:111122223333:parameter/dbUsername"
        }
    ]
}
```
Let’s see how the CloudFormation template looks like.

First, let’s start by defining the SSM parameter in the template. You will be constructing an ARN for this resource using pseudo parameters. This is a simple example of an SSM parameter where there’s a Name (dbUsername) and Value (alice). Choose to copy content shown next, and paste it in the `pseudo-parameters.yaml` file by appending it to the existing file content:

```YAML
Resources:
  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: dbUsername
      Type: String
      Value: alice
      Description: SSM Parameter for database username.
```

Next, let’s define the IAM role and policy from where you want to reference the SSM parameter you defined above. Again, choose to copy content shown next, and paste it in the Resources section of the `pseudo-parameters.yaml` file by appending it to the existing file content:

```yaml
  DemoRole:
    Type: 'AWS::IAM::Role'
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - 'sts:AssumeRole'
      Path: /
      Policies:
        - PolicyName: ssm-least-privilege
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action: 'ssm:GetParameter'
                Resource: '*'
  ```

  The IAM role above is a service role for a Lambda function that you plan to deploy, and as it stands, this role will allow a Lambda function to perform `GetParameter` operation on all SSM parameters. To follow the best practice of least privilege, let’s scope down the IAM policy so that the role lets our Lambda function to only retrieve the SSM parameter you defined above.



Instead of using `Resource: '*'` for the Resource definition above, you can construct the ARN of the SSM parameter you had defined previously. To construct the ARN for SSM parameter, you can use the `AWS::Partition`, `AWS::Region`, and `AWS::AccountId` pseudo parameters. The intrinsic function [Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) lets you substitute variables in an input string with values that you specify. In this case, you can make use of !Sub intrinsic function to substitute the values of the pseudo parameters to the ARN pattern of the SSM parameter.

For the `DemoRole`, under the Policies property, change the `Resource: '*'` portion to the following:

```yaml
Resource: !Sub 'arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/${BasicParameter}'
```


Finally, add this section below to the Resources section of the `pseudo-parameters.yaml` template file. This section defines a Lambda function that uses the IAM Role you defined above with permissions to read the SSM parameter, which you also defined above. You will invoke this Lambda function to test if the Lambda function can access the SSM parameter named `dbUsername` you defined above.

```yaml
DemoLambdaFunction:
  Type: AWS::Lambda::Function
  Properties:
    Handler: index.lambda_handler
    Role: !GetAtt DemoRole.Arn
    Runtime: python3.8
    Code:
      ZipFile: |
        import boto3

        client = boto3.client('ssm')


        def lambda_handler(event, context):
            response = client.get_parameter(Name='dbUsername')
            print(f'SSM dbUsername parameter value: {response["Parameter"]["Value"]}')

```

Now that you have added the Lambda function definition to your template, you’re ready to deploy a stack with the template. The content of the template file on your machine should look like the following example:



```yaml
AWSTemplateFormatVersion : "2010-09-09"
Description: >
  This template will create a SSM parameter and reference its ARN on an IAM policy
  leveraging CloudFormation pseudo parameters


Resources:

  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: dbUsername
      Type: String
      Value: alice
      Description: SSM parameter for mysql database username.

  DemoRole:
    Type: 'AWS::IAM::Role'
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - lambda.amazonaws.com
            Action:
              - 'sts:AssumeRole'
      Path: /
      Policies:
        - PolicyName: ssm-least-privilege
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action: 'ssm:GetParameter'
                Resource: !Sub 'arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/${BasicParameter}'
  DemoLambdaFunction:
    Type: AWS::Lambda::Function
    Properties:
      Handler: index.lambda_handler
      Role: !GetAtt DemoRole.Arn
      Runtime: python3.8
      Code:
        ZipFile: |
          import boto3

          client = boto3.client('ssm')


          def lambda_handler(event, context):
              response = client.get_parameter(Name='dbUsername')
              print(f'SSM dbUsername parameter value: {response["Parameter"]["Value"]}')

```


Save this template file to the machine you’re working on. Then navigate to the CloudFormation console and create a stack using this template.


* In the CloudFormation console, choose *Create stack With new resources (standard)*.
* In *Prepare template* choose *Template is ready*.
* In *Template source* select *Upload a template file*.
* Choose the file pseudo-parameters.yaml
* Enter a *Stack name*. For example, cfn-workshop-pseudo-parameters
* Choose to accept the *Configure stack options* default value, choose *Next*.
* On the *Review <stack_name>* page, scroll down to the bottom and choose the check box under the *Capabilities* section that says `I acknowledge that AWS CloudFormation might create IAM resources.`
* Choose *Create stack*. You can view the progress of the stack being created in the CloudFormation console.
* Wait until the stack creation is complete. Refresh the view in the console until you see in the status CREATE_COMPLETE.

![resources-png](pseudo-parameters/resources.png)

Let’s verify the IAM permission works as intended. Under the Resources tab of CloudFormation stack like in the picture above, you’ll find the `DemoRole` you described with the `pseudo-parameters.yaml` template.

Choose to follow the link to the Physical ID of the `DemoRole`. Expand the inline policy `ssm-least-privilege` under Policy name section.

![role-png](pseudo-parameters/role.png)

You’ll then see the IAM policy you described with the CloudFormation template. Verify that the SSM parameter ARN is constructed as you expected.

![policy-png](pseudo-parameters/policy.png)


On the Resources tab, you’ll also find the Lambda function that you described with the template above.

To verify the Lambda function has permissions to access the SSM parameter you defined in the template, you'll need to [Deploy and test/invoke the Lambda function](https://docs.aws.amazon.com/lambda/latest/dg/getting-started-create-function.html#get-started-invoke-manually). Choose to follow the link to the Physical ID of the Lambda function under the resource tab of CloudFormation stack. To invoke a Lambda function for testing, you'll first need to create a Test event. On the `Test` tab of your Lambda function, give a name to a new Test event in the new event template provided by default. Click on `Save changes` button to save the Test event. Then choose to click on `Test` button to invoke the Lambda function.

![lambda-test](pseudo-parameters/lambda-test.png)
After you invoke the Lambda function, under the **Function Logs** section you should see output similar to the example shown next:

![lambda-png](pseudo-parameters/lambda.png)

'alice' is the value of the 'dbUsername' SSM parameter and the Lambda function has logic to print the value of `dbUsername` parameter when invoked. If you see a test output that prints `SSM dbUsername parameter value: alice` like in the picture above, you have verified the SSM parameter policy that you constructed using pseudo parameters is working as you expected.


### Challenge
You’ve now learned how to leverage pseudo parameters in CloudFormation templates. Now let’s say you want to add an S3 bucket to the CloudFormation template. Let’s say you choose the name of the S3 bucket to be as in the following format:  YourPrefix-RegionName-AWSAccount ID. Example `my-demo-bucket-us-east-1-111122223333`

**Task:** Describe an S3 bucket resource in your template, and use a combination of CloudFormation parameters and pseudo parameters to construct the bucket name like in the example above. You want to add a prefix for the bucket name, passed in as a CloudFormation parameter, so that your bucket name will be composed as follows: `${yourprefix}-${AWS::AccountId}-${AWS::Region}`

{{%expand "Need a hint?" %}}

- See the documentation for [CloudFormation parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) and define the parameter for s3 bucket prefix in a similar way.
- CloudFormation parameters are referenced in a similar way to how we referenced pseudo parameters inside of the `!Sub` function above. For example, if your parameter name is `S3BucketNamePrefix` you can reference this inside of `!Sub` function as follows `!Sub '${S3BucketNamePrefix}'`



{{% /expand %}}



{{%expand "Want to see the solution?" %}}
```YAML
# add a parameter that will let users input a prefix to be used with s3 buckets
Parameters:
  S3BucketNamePrefix:
    AllowedPattern: ^[0-9a-zA-Z]+([0-9a-zA-Z-]*[0-9a-zA-Z])*$
    ConstraintDescription: Quick Start bucket name can include numbers, lowercase
      letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen
      (-).
    Description: The prefix to use for your S3 bucket
    Type: String
    MinLength: 3
    Default: my-demo-bucket

Resources:
  DemoBucket:
      Type: 'AWS::S3::Bucket'
      Properties:
        BucketName: !Sub '${S3BucketNamePrefix}-${AWS::Region}-${AWS::AccountId}'
```
See `code/solutions/pseudo-parameters.yaml` for the full solution.

{{% /expand %}}

Make sure you test your solution and verify everything works as intended. You can verify by first [updating the stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html) you created earlier using the updated template. If the stack update succeeds, check if the S3 bucket with the name ${yourprefix}-${AWS::AccountId}-${AWS::Region} is created. If so, this proves that pseudo parameters were used to construct the S3 bucket name and shows you’ve completed the challenge successfully.

### Clean up

Follow these steps to clean up created resources:

  * In the CloudFormation console, choose the stack you have created in this lab.
  * Choose **Delete** to delete the stack you created in this lab.
    In the pop-up window click on Delete stack.


---
### Conclusion
Great job! You have learned how to use pseudo parameters to write reusable CloudFormation templates. For more information, see pseudo parameters [documentation page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html).
