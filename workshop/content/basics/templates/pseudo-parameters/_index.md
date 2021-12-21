---
title: 'Pseudo parameters'
date: 2021-12-11T13:36:34Z
weight: 200
---

### Overview

In this lab, you will learn about **[pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)** and learn how to leverage them for writing reusable templates.


### Topics Covered



By the end of this lab, you will be able to:

+ Leverage pseudo parameters for template portability best practices
+ Identify sample use cases for leveraging pseudo parameters

When working with CloudFormation templates, one of the things you should aim for is to make templates modular and reusable to facilitate reuse of templates across accounts and regions. In addition to **[CloudFormation parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)** , you can choose to engineer your template, you can leverage pseudo parameters (LINK) that are parameters predefined by CloudFormation.

You can use them the same way as you would a parameter, as the argument for the **[Ref intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html)**.

In this module, you will use the three pseudo parameters below:

* **[AWS::AccountId](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid)**
    * Returns the Account ID of the Account where the stack is being deployed to
* **[AWS::Region](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region)**
    * Returns the AWS Region where the Stack is deployed to
* **[AWS::Partition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-partition)**
    * Returns the partition of AWS where the stack is deployed to. For standard AWS Regions, the partition is aws. For resources in other partitions, the partition is aws-partitionname. For example, the partition for resources in the China (Beijing and Ningxia) Region is aws-cn and the partition for resources in the AWS GovCloud (US-West)) region is aws-us-gov.  

For more information on available pseudo parameters, see the **[pseudo parameters reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)** in the documentation.


Let’s walk through an example of how to leverage pseudo parameters.




### Start Lab


Context: **[Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html#what-is-a-parameter)**, a capability of AWS Systems Manager, provides secure, hierarchical storage for configuration data management and secrets management. A Parameter Store parameter is any piece of data that is saved in Parameter Store, such as a block of text, a list of names, a password, an AMI ID, a license key, and so on. You can centrally and securely reference this data in your scripts, commands, and SSM documents. Let’s say you want to define AWS::SSM::Parameter resource in a CloudFormation template. Then you want to reference that SSM parameter in an IAM policy. This will require you to know the Amazon Resource Name (ARN) of the SSM parameter. First, you check the return values section for the resource (the SSM parameter in this case): in the relevant **[documentation page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html#aws-resource-ssm-parameter-return-values)** you see that `Fn::Ref` returns the parameter name, and `Fn::GetAtt` returns the type and the value. Let's see an example of leveraging pseudo parameters to construct the ARN.


In this example, you want to construct the resource ARN like one below using pseudo parameters. This policy allows you to get the value of a given SSM parameter. In this case, a parameter named dbUsername, in us-east-1 region and in Account with ID of `111122223333`.


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

First, let’s start by defining the SSM parameter in the template. You will be constructing an ARN for this resource using pseudo parameters. This is a simple example of an SSM parameter where there’s a Name(dbUsername) and Value(alice).

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

Next, let’s define the IAM Role and policy from where you want to reference the SSM parameter you defined above.

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

  The IAM role above is a service role for a Lambda function that you plan to deploy, and as it stands, this role will allow a Lambda function to perform GetParameter operation on all SSM parameters. To follow the best practice of least privilege, let’s scope down the IAM policy so that the role lets our Lambda function to only retrieve the SSM Parameter you defined above.

For the DemoRole, under the Policies property, change the Resource: `*` portion to the following:

```yaml
Resource: !Sub 'arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/${BasicParameter}'
```

In the Resource definition above, instead of using a `*` for Resource, you can construct the ARN of the SSM Parameter you defined above. To construct the ARN for SSM parameter, you use the AWS::Partition, AWS::Region, and AWS::AccountId pseudo parameters. The intrinsic function    **[Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** lets you substitute variables in an input string with values that you specify. In this case, you can make use of !Sub intrinsic function to substitute the values of the pseudo parameters to the ARN pattern of the SSM parameter.

Finally, add this section below to the template. This will define a Lambda function which uses the IAM Role you defined above with permissions to read the SSM parameter which you also defined above. You will invoke this Lambda function to test if the Lambda function can access the SSM parameter named dbUsername you defined above.

```yaml
TestLambdaFunction:
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
            response = client.get_parameter(
            Name='dbUsername',
            )
            print(f'SSM dbUsername parameter value: {response["Parameter"]["Value"]}')

```

Now that you have added the Lambda Function definition to your template, you’re ready to deploy a stack with the template.

{{%expand "Want to see the full template? Click to expand" %}}

```yaml
---
AWSTemplateFormatVersion : "2010-09-09"
Description: >
  This template will create a SSM Parameter and reference its ARN on an IAM policy
  leveraging CloudFormation pseudo parameters

Resources:
  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: dbUsername
      Type: String
      Value: alice
      Description: SSM Parameter for mysql database username.

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
            response = client.get_parameter(
            Name='dbUsername',
            )
            print(f'SSM dbUsername parameter value: {response["Parameter"]["Value"]}')


```
{{% /expand %}}

Save this template file(ssm-least-privilege.yaml) to the machine you’re working on. Then navigate to the CloudFormation Console and create a stack using this template.


* Navigate to CloudFormation in the console and choose *Create stack With new resources (standard)*.
* In *Prepare template* choose *Template is ready*.
* In *Template source* select *Upload a template file*.
* Choose a file ssm-least-privilege.yaml
* Enter a *Stack name*. For example, cfn-workshop-pseudo-parameters
* Choose to accept the *Configure stack options* default value, choose *Next*.
* On the *Review <stack_name>* page, scroll down to the bottom and choose both *IAM Capabilities* check boxes. i.e. CAPABILITY_IAM and CAPABILITY_NAMED_IAM
* Choose *Create stack*. You can view the progress of the stack being created in CloudFormation console.
* Wait until the stack creation is complete. Refresh the view in the console until you see in the status CREATE_COMPLETE.

![resources-png](pseudo-parameters/resources.png)

Let’s verify the IAM permission works as intended. Under the resource tab of CloudFormation Stack like in the picture above, you’ll find the DemoRole you described with the template above.

Choose to follow the link to the Physical ID of the DemoRole. Expand the inline policy under Policy name section.

![role-png](pseudo-parameters/role.png)

You’ll then see the IAM policy you described with the CloudFormation template. You can verify that the SSM Parameter ARN has been constructed properly as you expected.

![policy-png](pseudo-parameters/policy.png)


On the Resources tab, you’ll also find the Lambda function that you described with the template above

Choose to follow the link to the Physical ID of the Lambda function. **[Deploy and test/invoke the Lambda function](https://docs.aws.amazon.com/lambda/latest/dg/getting-started-create-function.html#get-started-invoke-manually)**. After you invoke the Lambda function, under Function Logs you will see some output text like the example below:

![lambda-png](pseudo-parameters/lambda.png)

If you see a test output like the one above, you have verified the SSM parameter policy that you constructed using pseudo parameters is working as you expected.



### Challenge
You’ve now learned how to leverage pseudo parameters in CloudFormation templates. Now let’s say you want to add an S3 bucket to the CloudFormation template. Let’s say the name of the S3 bucket needs to be in the following format:  YourPrefix-RegionName-AWSAccount ID. Example `myprodbucket-us-east-1-111122223333`

**Task:** Add a S3 bucket resource to the template and use a combination of CloudFormation parameters and pseudo parameters to construct the bucket name like in the example above. You want to add a prefix for the bucket name, passed in as a CloudFormation parameter, so that your bucket name is : `${yourprefix}-${AWS::AccountId}-${AWS::Region}`

{{%expand "Want to see the solution to the challenge ? Click to expand" %}}
```YAML
# add a parameter that will let users input a prefix to be used with s3 buckets
Parameters:
  S3BucketNamePrefix:
    Description: The prefix to use for your S3 bucket
    Type: String
    MinLength: 3
    Default: my-demo-bucket
    AllowedPattern: ^[a-z0-9]*$

Resources:
  DemoBucket:
      Type: 'AWS::S3::Bucket'
      Properties:
        BucketName: !Sub '${S3BucketNamePrefix}-${AWS::Region}-${AWS::AccountId}'
```

{{% /expand %}}

Make sure you test your solution and verify everything works as intended. You can verify by first **[updating the stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-direct.html)** you created earlier using the updated template. If the stack update succeeds, check if the S3 bucket with the name ${yourprefix}-${AWS::AccountId}-${AWS::Region} is created. If so, you’ve completed the challenge successfully.

---
### Conclusion
Great job! Now you know how to use pseudo parameters to make your CloudFormation templates more reusable. For more information, see pseudo parameters **[documentation page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)**. You can also choose to combine pseudo parameters with parameters you describe in your templates (for example, an application name parameter, a life cycle environment name parameter) as needed.
