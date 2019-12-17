---
title: 'Lab 02: Resources'
date: 2019-10-28T14:35:59Z
weight: 100
---

### Overview

In this Lab, you will learn little bit more about CloudFormation top-level sections, including Format Version, Description, Metadata, Parameters and Resources.

### Topics Covered
By the end of this lab, you will be able to:

+ Understand CloudFormation template structure and some of its sections.
+ Deploy an EC2 instance via CloudFormation.
+ Query SSM parameter store to get latest Amazon Linux AMI ID.

### Start Lab

{{% notice note %}}

As you read through each sections, there are code samples at the end. Copy these into your own template file. 

{{% /notice %}}

1. Go to `code/20-cloudformation-features/` directory.
1. Open the `01-lab02-Resources.yaml` file.

#### Format Version
The _AWSTemplateFormatVersion_ section identifies the capabilities of the template. The latest template format
 version is _2010-09-09_ and is currently the only valid value. 
 
```yaml
AWSTemplateFormatVersion: '2010-09-09'
```

#### Description
The _Description_ section enables you to include comments about your template.

```yaml
Description : 'AWS CloudFormation Workshop template.'
```

#### Metadata
You can use the [_Metadata_ section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/metadata-section-structure.html) to include arbitrary JSON or YAML objects. 
This section is useful for providing information to other tools that interact with your CloudFormation template. 
For example, when deploying CloudFormation templates via the AWS console, you can improve the experience of users deploying your templates by specify how to order, label and group parameters. This can be done with the [_AWS::CloudFormation::Interface_](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloudformation-interface.html) key. 

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
      - m1.small
      - m1.large
    Description: 'Enter t2.micro, m1.small, or m1.large. Default is t2.micro.'
``` 

#### Resources

The required _Resources_ section declares the AWS resources that you want to include in the stack. Let's add the EC2 resource to your stack.

```yaml {hl_lines=[6]}
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
  {{% expand "Expand to see the solution" %}}
  ![ami-gif](../ami-1.gif)
  {{% /expand %}}
  1. Once you have your AMI ID, copy and paste it to **ImageId** property.

{{% notice info %}}
 
You can find a working solution for the **London Region** in `code/40-cloudformation-features/02-lab02-Resources-Solution.yaml` file.

{{% /notice %}}

Now your EC2 template is ready to be deployed. Go back to AWS console and deploy the stack same way as you did in 
[Lab 01: Template and Stack](/30-cloudformation-fundamentals/200-lab-01-stack).

### Challenge

In this exercise, use the AWS CLI to query the AWS Systems Manager Parameter Store the get latest Amazon Linux AMI ID. 

To complete this challenge, you have to have [AWS CLI](/20-prerequisites/200-awscli) configured.

{{%expand "Need a hint?" %}}

Check out the [AWS Compute Blog](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/) to find out.

{{% /expand %}}

{{%expand "Want to see the solution?" %}}

Copy the code below to your terminal. Make sure to change the `--region` flag to use a region that you are deploying your CloudFormation to.

```bash
aws ssm get-parameters \
--names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
--query "Parameters[].Value" \
--region eu-west-2 \
--output text
```

![ami-id-gif](../ami-id.gif)

{{% /expand %}}

---
### Conclusion
Congratulations! You now have successfully learned how to deploy EC2 instance via CloudFormation.
