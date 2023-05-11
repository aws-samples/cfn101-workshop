---
title: "Pseudo parameters"
weight: 500
---

_Lab Duration: ~15 minutes_

---

### Overview
In this lab, you will learn how to use [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) to write reusable templates.

### Topics Covered
By the end of this lab, you will be able to:

+ Leverage pseudo parameters for template portability best practices
+ Identify sample use cases for leveraging pseudo parameters

When working with CloudFormation templates, one of the things you should aim for is to write modular and reusable templates to facilitate reuse of templates across AWS Accounts and Regions. In addition to [CloudFormation parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html), you can choose to engineer your template to use [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html). Pseudo parameters are parameters predefined by CloudFormation.

You can use a pseudo parameter the same way you use a parameter; for example, as an argument for the [Ref intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html).

In this module, you will use the three pseudo parameters below:

* [AWS::AccountId](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid) -
  returns the Account ID of the Account you choose to create the stack off of your template.
* [AWS::Region](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region) -
  returns the name of the AWS Region where you choose to create the stack.
* [AWS::Partition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-partition) -
  returns the name of the AWS partition. The partition name for standard AWS Regions is `aws`; for the China (Beijing and Ningxia) Region is `aws-cn`, and for the AWS GovCloud (US-West) Region is `aws-us-gov`.

::alert[For more information on available pseudo parameters, see the [pseudo parameters reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) in the documentation.]{type="info"}

Let’s walk through an example of how to leverage pseudo parameters.

### Start Lab
* Change directory to: `code/workspace/pseudo-parameters`.
* Open the `pseudo-parameters.yaml` file.
* Update the content of the template as you follow along steps on this lab.

In the following example, use [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html#what-is-a-parameter)
to centrally store a configuration information, such as the username for your database. For this, describe an `AWS::SSM::Parameter`
resource in your CloudFormation template where you will store the username value.

Then write an IAM policy to describe
action(s) you wish to grant to an [AWS Lambda function](https://aws.amazon.com/lambda/) you will create and use to consume
your parameter store value. Start with describing your IAM policy, where you reference the SSM parameter you created. This
will require you to know the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) of the SSM parameter.

First, check the return values section for the resource (the SSM parameter in this case): in the relevant [documentation page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ssm-parameter.html#aws-resource-ssm-parameter-return-values), you see that `Ref` returns the parameter name, and `Fn::GetAtt` returns the type and the value. Since the ARN is not available as an output value for that resource type today, you can choose to leverage pseudo parameters to construct the ARN.

You want to construct the resource ARN using pseudo parameters like the one in the following example. Let's say, for example, you have a sample parameter called `dbUsername` that you create in the `us-east-1` region, and in the AWS account `111122223333`; an example parameter ARN is constructed as in this example policy snippet:
:::code{language=json showLineNumbers=false showCopyAction=false}
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
:::
Let's describe resources you need in your CloudFormation template.

Start by defining a [template parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html),
you will use as the value of the SSM parameter, that you'll define in the template. Start with a template parameter called
`DatabaseUsername` under the `Parameters` section.

Reference this template parameter in the `Resources` section by using the `Ref` intrinsic function. Copy
the content shown below, and paste it in the `pseudo-parameters.yaml` file, by appending it to the existing file content:
```yaml
Parameters:
  DatabaseUsername:
    AllowedPattern: ^[a-z0-9]{5,12}$
    Type: String
    Default: alice
    Description: Value to be used with the dbUsername SSM parameter. The default value is set to 'alice', which users can override when creating a CloudFormation stack.
```

Now, let's describe an SSM parameter: set its `Name` property to `dbUsername`, and use `Ref` to reference the `DatabaseUsername`
template parameter in the `Value` property.

Append the following content to the existing file content:
```yaml
Resources:
  BasicParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: dbUsername
      Type: String
      Value: !Ref DatabaseUsername
      Description: SSM Parameter for database username.
```

Next, let’s define the IAM role and policy from where you want to reference the SSM parameter you defined above.
Copy the content below, and paste it in the `Resources` section of the `pseudo-parameters.yaml` file by appending it to the existing file content:
```yaml
DemoRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: "2012-10-17"
      Statement:
        - Effect: Allow
          Principal:
            Service:
              - lambda.amazonaws.com
          Action:
            - sts:AssumeRole
    Path: /
    Policies:
      - PolicyName: ssm-least-privilege
        PolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Action: ssm:GetParameter
              Resource: '*'
```

In the example snippet above, you have described an [execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)
you will associate with a Lambda function you plan to deploy. The role allows your Lambda function to perform the `GetParameter`
operation on your SSM parameters. To follow the best practice of the least privilege, scope down actions in your IAM policy,
so to only allow access from the Lambda function, to SSM parameter you defined above.

Instead of using `Resource: '*'` for the `Resource` definition above, specify the ARN of your parameter that you construct
with `AWS::Partition`, `AWS::Region`, and `AWS::AccountId` pseudo parameters. The [Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)
intrinsic function lets you substitute variables in an input string with values that you specify: you will use this intrinsic
function (shown next in its `!Sub` YAML short form) to substitute values of pseudo parameters mentioned earlier. In the ARN you
compose, you will also specify the name of your Parameter Store resource, by referencing it with `BasicParameter`, that is
the [logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) of the
Parameter Store resource you described in your template.

Locate the `Policies` section for `DemoRole`; replace the whole line containing `Resource: '*'` with the following:
```yaml
Resource: !Sub 'arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:parameter/${BasicParameter}'
```

Finally, add the example snippet below to the `Resources` section of the `pseudo-parameters.yaml` template file.
The snippet defines a Lambda function that uses the IAM Role you defined above with permissions to read the SSM parameter,
which you also defined above. You will invoke this Lambda function to test if the Lambda function can access the SSM parameter named `dbUsername`.
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

Save the template you have updated with content above. Next, navigate to the AWS CloudFormation [console](https://console.aws.amazon.com/cloudformation), and choose to create a stack using this template:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/pseudo-parameters`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/pseudo-parameters
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-pseudo-parameters --template-body file://pseudo-parameters.yaml --capabilities CAPABILITY_NAMED_IAM
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-pseudo-parameters/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the CloudFormation console, select *Create stack With new resources (standard)*.
1. In **Prepare template**, select **Template is ready**.
1. In **Specify template**, select **Upload a template file**.
1. Choose the `pseudo-parameters.yaml` template.
1. Enter a **Stack name**. For example, choose to specify `cfn-workshop-pseudo-parameters`.
1. Accept the **Configure stack options** default value, and choose **Next**.
1. On the _Review_ page, scroll down to the bottom, and check the box under the following *Capabilities* section: **I acknowledge that AWS CloudFormation might create IAM resources.**
1. Choose **Submit**. You can view the progress of the stack being created in the CloudFormation console.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `CREATE_COMPLETE` status.
::::
:::::

You should see new resources created under Resources tab in cloudformation stack console:

![resources-png](/static/basics/templates/pseudo-parameters/resources.png)

Verify IAM permissions you described work as you expect. Under the _Resources_ tab for your CloudFormation stack, as shown in the picture above, find the `DemoRole` you described with the `pseudo-parameters.yaml` template. Choose to follow the link to the Physical ID of the `DemoRole`. Expand the inline policy `ssm-least-privilege` under the section for the policy name.

![role-png](/static/basics/templates/pseudo-parameters/role.png)

You should see the IAM policy you described with your CloudFormation template. Verify that the ARN for your parameter is constructed as you expected.

![policy-png](/static/basics/templates/pseudo-parameters/policy.png)

In the _Resources_ tab, you should also find the Lambda function you described with your template.

To verify the Lambda function has permissions to access your SSM parameter you defined in the template,
manually [invoke](https://docs.aws.amazon.com/lambda/latest/dg/getting-started-create-function.html#get-started-invoke-manually) your
Lambda function.

Follow the link to the _Physical ID_ of your Lambda function under the _Resources_ tab of CloudFormation stack. To invoke your Lambda function for testing, you'll first need to create a Test event. On the `Test` tab, give a name to a new Test event in the new event template provided by default.

**Save changes** to your Test event, and then select **Test** to invoke the Lambda function.

![lambda-test](/static/basics/templates/pseudo-parameters/lambda-test.png)
After you invoke the Lambda function, under the **Function Logs** section you should see output similar to the example shown next:

![lambda-png](/static/basics/templates/pseudo-parameters/lambda.png)

You should see a line, similar to the one above, showing `alice` as the value for your `dbUsername` parameter: with this,
you have verified that the logic you added to your Lambda function can access your parameter, and retrieve and print its value as you expected.

### Challenge
You’ve learned how to use pseudo parameters in your CloudFormation templates. Now let’s say you want to add an [Amazon S3 bucket](https://aws.amazon.com/s3/) to
your CloudFormation template: for example, you choose the name of the S3 bucket to be as in the following format: `YOUR_BUCKET_NAME_PREFIX-AWS_REGION-YOUR_ACCOUNT_ID`, such as: `my-demo-bucket-us-east-1-111122223333`.

**Task:** Describe an S3 bucket resource in your template. Add a prefix for your bucket name, and pass this prefix in as a CloudFormation template parameter. Use your template parameter and pseudo parameters to compose the bucket name as in the format mentioned earlier.

:::expand{header="Need a hint?"}
- See the documentation for [CloudFormation parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html), and define a parameter for your S3 bucket name prefix in your template.
- When composing the bucket name, reference your CloudFormation parameter like you referenced pseudo parameters with the `!Sub` intrinsic function earlier. For example, if your template parameter is `S3BucketNamePrefix`, choose to reference it with the `!Sub` intrinsic function as follows: `!Sub '${S3BucketNamePrefix}'`
:::

::::::expand{header="Want to see the solution?"}
First, under the _Parameters_ section, add a template parameter `S3BucketNamePrefix` to be used as the S3 bucket prefix you'll be creating.

```yaml
S3BucketNamePrefix:
  Description: The prefix to use for your S3 bucket
  Type: String
  Default: cfn-workshop
  AllowedPattern: ^(?!(^xn--|.$))^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$
  ConstraintDescription: Bucket name prefix can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-).
```

Then, add a `DemoBucket` resource under the _Resources_ section of the template.

```yaml
DemoBucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Sub '${S3BucketNamePrefix}-${AWS::Region}-${AWS::AccountId}'
```
See `code/solutions/pseudo-parameters/pseudo-parameters.yaml` for the full solution.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/pseudo-parameters`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/pseudo-parameters
:::
1. Use the AWS CLI to update the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name cfn-workshop-pseudo-parameters --template-body file://pseudo-parameters.yaml --capabilities CAPABILITY_NAMED_IAM
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-pseudo-parameters/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
1. Open the **[Amazon S3](https://console.aws.amazon.com/s3)** console and verify your S3 bucket uses the `YOUR_BUCKET_NAME_PREFIX-AWS_REGION-YOUR_ACCOUNT_ID` format.
::::
::::tab{id="local" label="Local development"}
1. Click on the stack name, for example **cfn-workshop-pseudo-parameters**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Template is ready**.
1. In **Specify template**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Choose the `pseudo-parameters.yaml` template.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `UPDATE_COMPLETE` status.
1. Open the **[Amazon S3](https://console.aws.amazon.com/s3)** console and verify your S3 bucket uses the `YOUR_BUCKET_NAME_PREFIX-AWS_REGION-YOUR_ACCOUNT_ID` format.
::::
:::::
::::::

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-pseudo-parameters`.
1. In the top right corner, select **Delete**.
1. In the pop-up window, select **Delete**.
1. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---
### Conclusion
Great job! You have learned how to use pseudo parameters to write more reusable CloudFormation templates. For more information, see [pseudo parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html).
