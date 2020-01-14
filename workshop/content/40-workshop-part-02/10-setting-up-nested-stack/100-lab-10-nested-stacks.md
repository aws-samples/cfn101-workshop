---
title: 'Lab 10: Nested Stacks'
date: 2019-11-13T16:52:42Z
weight: 100
---

{{% notice warning %}} 
Hi there, thank you for the interest in the CFN201 - Workshop. Currently the Part 02 of the workshop is under development.
{{% /notice %}}

## Introduction

Your CloudFormation template has grown considerably over the course of this workshop. As your infrastructure grows, common 
patterns can emerge in which you declare the same components in each of your templates. 

For example, you may wish to enable Systems Manager Session Manager access to every EC2 Instance. Instead of copying and 
pasting the same IAM role configuration, you can create a dedicated template containing the IAM role for the instance. You 
can then use this template like a resource via `AWS::CloudFormation::Stack`

## Lab Overview

In this lab, you will build:

1. **The _root_ stack** (which is also a parent stack for the first level stacks). This root stack will contain all the other stacks.
1. **The VPC stack**. This contains a simple VPC template which the EC2 instance will be placed into.
1. **The IAM instance role stack**. This contains the IAM instance role template decoupled form your EC2 template. 
1. **The EC2 stack**. This contains the EC2 instance you have defined in your previous CloudFormation template.

Top level and first level hierarchy of nested stacks.

![nested-stack-hierarchy](../nested-stack-hierarchy.png)

The following diagram represents high level overview of the infrastructure:

![nested-stack-architecture](../ns-architecture.png)

You will find the working directory in `code/60-setting-up-nested-stack/01-working directory`. In the rest of this lab you should add your code to the templates here.

You can find the working solution in `code/60-setting-up-nested-stack/02-solution`. You can reference this against your code.

**Let's start..**

### Nested Stack Resource

To reference a CloudFormation stack in your template, use the `AWS::CloudFormation::Stack` resource.

It looks like this:

```yaml
Resources:
    NestedStackExample
        Type: AWS::CloudFormation::Stack
        Properties: 
            Parameters: 
                ExampleKey: ExampleValue
            TemplateURL: "Path/To/Template"
```

The `TemplateURL` property is used to reference the CloudFormation template that you wish to nest.

The `Parameters` property allows you to pass parameters to your nested CloudFormation template.

### Prepare S3 bucket

Whilst single templates can be deployed from your local machine, Nested Stacks require that the nested templates are stored in an S3 bucket.
In the very first lab, you have created simple
CloudFormation template which created S3 bucket. Please make a note of the bucket name.

For example:

Bucket name: `cfn-workshop-s3-s3bucket-2cozhsniu50t`

If you dont have S3 bucket, please go back to [Lab01](../../30-cloudformation-fundamentals/200-lab-01-stack) and create one.

### Create VPC Nested Stack

The VPC template has been created for you. It is titled `vpc.yaml`. This template will create VPC stack with 2 Public Subnets, Internet Gateway, and Route tables.

#### 1. Create VPC parameters in main template

{{% notice note %}} 
All of the files referenced in this lab can be found within `code/60-setting-up-nested-stack/01-working`
{{% /notice %}}

If you look in the file `vpc.yaml` file, you will notice that there are some parameters in the _Parameters_ section of the template.
The parameters are added to the main template so that they can be passed to the nested stack. Copy the code below to the  _Parameters_ section of the `main.yaml` template.

```yaml
  AvailabilityZones:
    Type: List<AWS::EC2::AvailabilityZone::Name>
    Description: The list of Availability Zones to use for the subnets in the VPC. Select 2 AZs.

  VPCName:
    Type: String
    Description: The name of the VPC.
    Default: cfn-workshop-vpc

  VPCCidr:
    Type: String
    Description: The CIDR block for the VPC.
    AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
    ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
    Default: 10.0.0.0/16

  PublicSubnet1Cidr:
    Type: String
    Description: The CIDR block for the public subnet located in Availability Zone 1.
    AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
    ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
    Default: 10.0.0.0/24

  PublicSubnet2Cidr:
    Type: String
    Description: The CIDR block for the public subnet located in Availability Zone 2.
    AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$
    ConstraintDescription: CIDR block parameter must be in the form x.x.x.x/16-28
    Default: 10.0.1.0/24
```

#### 2. Create VPC resource in main template
In the code below, note that passing parameter values to resources works the same as if using a single standalone template. Make sure that parameter name in the main template matches parameter name in the VPC template.

Add this code in the _Resources_ section of the main template (`main.yaml`)

```yaml
  VpcStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/vpc.yaml
      TimeoutInMinutes: 20
      Parameters:
        AvailabilityZones:
          Fn::Join:
            - ','
            - !Ref AvailabilityZones
        VPCCidr: !Ref VPCCidr
        VPCName: !Ref VPCName
        PublicSubnet1Cidr: !Ref PublicSubnet1Cidr
        PublicSubnet2Cidr: !Ref PublicSubnet2Cidr
```

#### 3. Upload the VPC stack to S3

1. Navigate to your S3 bucket in the console and select it.
1. Click on _Upload_ button -> _Add files_.
1. Locate the `vpc.yaml` file and select it.
1. Click _Upload_ button to upload the file.

#### 4. Deploy VPC Nested Stack

1. Navigate to CloudFormation in the console and click _Create stack With new resources (standard)_.
1. In **Prepare template** select _Template is ready_.
1. In **Template source** select _Upload a template file_.
1. Choose a file `main.yaml`.
1. Enter a stack name. For example, cfn-workshop-nested-stack
1. For the `AvailabilityZones` parameter, select 2 AZs.
1. Fo the `S3BucketName` provide the name of the bucket you have wrote down in "Prepare S3 bucket" section.
1. You can leave rest of the parameters default.
1. Navigate through the wizard leaving everything default.
1. Acknowledge IAM capabilities and click on _Create stack_

### Create IAM Nested Stack

#### 1. Prepare IAM role template

The IAM instance role resource has been removed from ec2 template for you.

1. Open `code/60-setting-up-nested-stack/01-working directory/02-lab10-iam.yaml`.
1. Copy the code below to the _Resources_ section of the template.

```yaml
  SSMIAMRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ec2.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  WebServerInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: /
      Roles:
        - !Ref SSMIAMRole
```

#### 2. Create IAM resource in main template
Copy the code below to the _Resources_ section of the `main.yaml` template.

```yaml
  IamStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/iam.yaml
      TimeoutInMinutes: 10
```

#### 3. Upload the IAM stack to S3

Similarly to the [VPC stack](#3-upload-the-vpc-stack-to-s3), upload the IAM template to the S3.

#### 4. Deploy IAM Nested Stack

Update the previously created stack with a new template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the _root_ stack (it is the one without the **nested** tag associated).
1. Select _replace current template_
1. Upload the new template file.
1. Follow the wizard, acknowledge IAM capabilities and click on _Update stack_.

### Create EC2 Nested Stack

#### 1. Create EC2 parameters in main template

Similarly to VPC template, if you look into _Parameters_ section of the `ec2.yaml` template
there are three parameters:

* `SubnetId` - this property will be passed from VPC stack once the VPC stack is created.
* `EnvironmentType` - this property has a default value and is likely to change often, so let's add this one.
* `AmiID` - this property has default value, it can be left out from the main template.

Add the code below to the _Parameters_ section of the main template:
```yaml
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Dev
      - Test
      - Prod
    ConstraintDescription: 'Specify either Dev, Test or Prod.'
```

#### 2. Create EC2 resource in main template

Copy the code below to the _Resources_ section of the `main.yaml` template.
```yaml
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
```

#### 3. Add EnvironmentType to EC2 stack

Add the `EnvironmentType` parameter to the EC2 stack in the `main.yaml template`.
```yaml {hl_lines=[7]}
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        EnvironmentType: !Ref EnvironmentType
```

#### 4. Pass variable from another nested stack

Before you update your CloudFormation nested stack, there are a couple more things to do. 

+ You need to specify which VPC to create the EC2 security group in. Without specifying the VPC parameter, the security group will be created in the _Default_ VPC.
    
+ You need to specify which subnet to create the EC2 instance in.

##### 1. Prepare the security group resource

1. Open up `ec2.yaml` and locate the `WebServerSecurityGroup` resource.
1. Add `VpcId` property and reference VpcId parameter. Your security group resource should look like the code below.

```yaml {hl_lines=[10]}
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Enable HTTP access via port 80'
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
      VpcId: !Ref VpcId
```

1. Next, create two parameters, `VpcId` and `SubnetId` in _Parameters_ section of `ec2.yaml`.

```yaml
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: 'The VPC ID'
    
  SubnetId:
    Type: AWS::EC2::Subnet::Id
    Description: 'The Subnet ID'
``` 

##### 2. Prep VPC template

To pass the variable from one stack to another, you need to create an output containing the value in the stack that will be passing it on.
Using the intrinsic function `!GetAtt`, CloudFormation can access the value from that stack and will pass it on as a parameter.

Add the code below to the `vpc.yaml` template.
```yaml
Outputs:
  VpcId:
    Value: !Ref VPC

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
```

##### 3. Add VpcId to _EC2Stack_ stack

Add `VpcId` and `SubnetId` parameters to the EC2 stack in the `main.yaml` template.
```yaml {hl_lines=[8,9]}
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        EnvironmentType: !Ref EnvironmentType
        VpcId: !GetAtt VpcStack.Outputs.VpcId
        SubnetId: !GetAtt VpcStack.Outputs.PublicSubnet1
```

##### 4. Prep IAM template

Open up `iam.yaml` and add the code below.
```yaml
Outputs:
  WebServerInstanceProfile:
    Value: !Ref WebServerInstanceProfile
```

##### 5. Prep EC2 template

1. Open up `ec2.yaml`
1. Create the parameter `WebServerInstanceProfile` in the _Parameters_ section of the template.
```yaml
  WebServerInstanceProfile:
    Type: String
    Description: 'Instance profile resource ID'
``` 

##### 6. Add WebServerInstanceProfile to _EC2Stack_ stack

Add the `WebServerInstanceProfile` parameter to the EC2 stack in the `main.yaml` template.
```yaml {hl_lines=[10]}
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        EnvironmentType: !Ref EnvironmentType
        VpcId: !GetAtt VpcStack.Outputs.VpcId
        SubnetId: !GetAtt VpcStack.Outputs.PublicSubnet1
        WebServerInstanceProfile: !GetAtt IamStack.Outputs.WebServerInstanceProfile
```

#### 5. Upload the EC2 stack to S3
Before you can deploy the updated nested stack, you must update the templates in your S3 bucket that are referenced by the parent template, `main.yaml`.

Similar to the [uploading the VPC stack](#3-upload-the-vpc-stack-to-s3) in a previous step, upload the `ec2.yaml` and `iam.yaml` templates to your S3 bucket.

#### 6. Deploy EC2 Nested Stack

Update your previously created stack with a new parent template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the _root_ stack (it is the one without nested tag associated).
1. Select _replace current template_.
1. Upload the new template file.
1. Follow the wizard, acknowledge IAM capabilities and click on _Update stack_.

## Making changes to nested stacks

It's possible to change components of a nested stack. For example, you may edit the properties of a resource in a stack, or add a resource. First, make the updates to the required stacks. Then upload the changed nested templates to S3. Finally, redeploy the parent stack to update the entire nested stack

## Conclusion

Nested stacks are allow you to compose CloudFormation templates. This allows you to decompose large templates into smaller reusable components. It also assists in avoid resource limits of a single template. These components are defined in a template like any other CloudFormation resource.
