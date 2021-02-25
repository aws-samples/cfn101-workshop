---
title: 'Lab 02: Resources'
date: 2019-10-28T14:35:59Z
weight: 100
---

### Overview

In this Lab, you will learn little more about CloudFormation top-level sections, including Format Version, Description, Metadata, Parameters and Resources.

### Topics Covered
By the end of this lab, you will be able to:

+ Understand CloudFormation template structure and some of its sections.
+ Deploy an EC2 instance via CloudFormation.
+ Query SSM parameter store to get the latest Amazon Linux AMI ID.

### Start Lab

{{% notice note %}}
As you read through each section, there are code samples at the end. Copy these into your own template file.
{{% /notice %}}

1. Go to `code/20-cloudformation-features/` directory.
1. Open the `01-lab02-Resources.yaml` file.
1. Copy the code as you go through the topics below.

#### Format Version
The _AWSTemplateFormatVersion_ section identifies the capabilities of the template. The latest template format version is _2010-09-09_ and is currently the only valid value.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
```

#### Description
The _Description_ section enables you to include comments about your template.

```yaml
Description : CFN 101 Workshop - Lab 02 Resources.
```

#### Metadata
You can use the [_Metadata_ section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/metadata-section-structure.html) to include arbitrary JSON or YAML objects. This section is useful for providing information to other tools that interact with your CloudFormation template. For example, when deploying CloudFormation templates via the AWS console, you can improve the experience of users deploying your templates by specify how to order, label and group parameters. This can be done with the [_AWS::CloudFormation::Interface_](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudformation-interface.html) key.

```yaml
Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: 'Amazon EC2 Configuration'
        Parameters:
          - InstanceType

    ParameterLabels:
      InstanceType:
        default: 'Type of EC2 Instance'
```

#### Parameters
_Parameters_ enable you to input custom values to your template each time you create or update a stack.

AWS CloudFormation supports the following parameter types:

|Type|Description|Example|
|----|----|----|
| _String_ |A literal string.|"MyUserName"|
| _Number_ |An integer or float.|"123"|
| _List\<Number\>_ |An array of integers or floats.|"10,20,30"|
| _CommaDelimitedList_ |An array of literal strings.|"test,dev,prod"|
|[AWS-Specific Parameter Types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-specific-parameter-types)|AWS values such as Amazon VPC IDs.| _AWS::EC2::VPC::Id_ |
|[SSM Parameter Types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html#aws-ssm-parameter-types)|Parameters that correspond to existing parameters in Systems Manager Parameter Store.| _AWS::SSM::Parameter::Value\<AWS::EC2::Image::Id\>_ |

```yaml
Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
    AllowedValues:
      - t2.micro
      - t2.small
    Description: 'Enter t2.micro or t2.small. Default is t2.micro.'
```

#### Resources

The required _Resources_ section declares the AWS resources that you want to include in the stack. Let's add the EC2 resource to your stack.

```yaml
Resources:
  WebServerInstance:
    Type: 'AWS::EC2::Instance'
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: <replace with AMI ID ami-xxxxx>
```

The only required property of the EC2 resource type is _ImageId_. Let's find the AMI ID via AWS console:

  1. Open **[AWS EC2 console](https://console.aws.amazon.com/ec2)**
  1. Click **Instances** -> **Launch Instance**.
  1. Copy the **Amazon Linux 2 AMI** `ami-xxxxxxxxx` ID.
  {{% notice note %}}
  Make sure to use **(x86)** AMI ID, if the region supports both x86 and ARM architectures.
  {{% /notice %}}
  {{% expand "Expand to see the solution" %}}
  ![ami-gif](100-lab-02-resources/ami-1.gif)
  {{% /expand %}}
  1. Once you have your AMI ID, copy and paste it to **ImageId** property.

{{% notice info %}}

You can find a working solution for the **London Region** in `code/20-cloudformation-features/02-lab02-Resources-Solution.yaml` file.

{{% /notice %}}

Now your EC2 template is ready to be deployed. Go back to AWS console and deploy the stack same way as you did in [Lab 01: Template and Stack](../10-cloudformation-fundamentals/200-lab-01-stack.html).

{{% notice warning %}}
To complete this and future labs you will need **Default VPC** in the region you will be deploying CloudFormation templates to. \
If you have deleted your default VPC, you can create a new one by following the AWS documentation for **[Creating a Default VPC](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html#create-default-vpc)**.
{{% /notice %}}

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on **Create stack** (_With new resources (Standard)_ if you have clicked in the top right corner).
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `01-lab02-Resources.yaml`.
1. Click **Next**.
1. Provide a **Stack name**. For example **cfn-workshop-ec2**.
    + The _Stack name_ identifies the stack. Use a name to help you distinguish the purpose of this stack.
    + For **Type of EC2 Instance** select you preferred instance size, for example **t2.micro**.
    + Click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Create stack**.
    {{% notice tip %}}
  This will create EC2 instance in your account. To check the cost of the deployed stack, click on **Estimate cost** on the review page.
    {{% /notice %}}
1. You can click the **refresh** button a few times until you see in the status **CREATE_COMPLETE**.

### Challenge

In this exercise, use the AWS CLI to query the AWS Systems Manager Parameter Store the get the latest Amazon Linux AMI ID.

{{% notice note %}}
To complete this challenge, you have to have [AWS CLI](../../../20-prerequisites/200-awscli.html) configured.
{{% /notice %}}

{{%expand "Need a hint?" %}}
Check out the [AWS Compute Blog](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/) to find out.
{{% /expand %}}

{{%expand "Want to see the solution?" %}}
Copy the code below to your terminal. Make sure to change the `--region` flag to use a region that you are deploying your CloudFormation to.

```shell script
aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --query "Parameters[].Value" \
  --region eu-west-2 \
  --output text
```

![ami-id-gif](100-lab-02-resources/ami-id.gif)
{{% /expand %}}

---
### Conclusion
Congratulations! You now have successfully learned how to deploy EC2 instance via CloudFormation.
