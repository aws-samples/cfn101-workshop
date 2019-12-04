---
title: "Lab 10: Nested Stacks"
date: 2019-11-13T16:52:42Z
weight: 100
---

## Introduction

Your CloudFormation template has grown considerably over the course of this workshop. As your infrastructure grows, common 
patterns can emerge in which you declare the same components in each of your templates. For example, IAM instance role will 
very likely be used for every EC2 instance created, to enable SSH access. Instead of copying and pasting the same configuration 
into EC2 template, you can create dedicated template for IAM instance role and then use the `AWS::CloudFormation:Stack`
resource to reference that template from within other templates.

## Lab Overview

In this lab, you will build:

1. **The _root_ stack** (which is also a parent stack for the first level stacks). This root stack will contain all the other stacks.
1. **The VPC stack**. This contains a simple VPC template which the EC2 instance will be placed into.
1. **The IAM instance role stack**. This contains the IAM instance role template decoupled form your EC2 template. 
1. **The EC2 stack**. This contains the EC2 instance you have defined in your previous CloudFormation template.

Top level and first level hierarchy of nested stacks.

![nested-stack-hierarchy](/60-setting-up-nested-stack/nested-stack-hierarchy.png)

The following diagram represents high level overview of the infrastructure:

![nested-stack-architecture](/60-setting-up-nested-stack/nested-stack-2.png)

You will find working directory in `code/60-setting-up-nested-stack/01-working directory`. You should copy/paste lab code there.

You can find working solution in `code/60-setting-up-nested-stack/02-solution`. You can reference this against your code.

**Let's start..**

### Nested Stack Resource

To reference a CloudFormation stack in your template, use the `AWS::CloudFormation::Stack` resource.

It looks like this:

```bash
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

In order to deploy Nested Stacks, CloudFormation needs to find them somewhere. In the very first lab, you have created simple
CloudFormation template which created S3 bucket. Please make a note of the bucket name.

For example:

Bucket name: `cfn-workshop-s3-s3bucket-2cozhsniu50t`

If you dont have S3 bucket, please go back to [Lab01](../../30-cloudformation-fundamentals/200-lab-01-stack) and create one.

### Create VPC Nested Stack

The VPC template has been created for you. This template wil create VPC stack with 2 Public Subnets, Internet Gateway, and Route tables.

#### 1. Create VPC parameters in main template

If you look in `code/60-setting-up-nested-stack/01-working directory/vpc.yaml` file, you will notice that there are some parameters in the _Parameters_ section of the template.
You need to pass in those parameters from the main stack. Copy the code bellow to the `main.yaml` template to the _Parameters_ section.
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
In the code bellow, note that passing parameter values to resource works the same as you single standalone template. The only difference is,
that parameter name in main template has to match parameter name in the VPC template

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
1. Copy the code bellow to the _Resources_ section of the template
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

```yaml
  IamStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/iam.yaml
      TimeoutInMinutes: 10
```

#### 3. Upload the IAM stack to S3

Similarly to VPC stack, upload the IAM template to the S3.

#### 4. Deploy IAM Nested Stack

Update previously created stack with a new template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the _root_ stack (it is the one without nested tag associated).
1. Select _replace current template_
1. Upload the new template file
1. Follow the wizard and click _Update stack_

### Create EC2 Nested Stack

#### 1. Create EC2 parameters in main template

Similarly to VPC template, if you look into _Parameters_ section of the `code/60-setting-up-nested-stack/01-working directory/ec2.yaml` template
there are three parameters:

`AvailabilityZone` - you can get the value from existing parameter `AvailabilityZones` by using intrinsic function `!Select`
`EnvironmentType` - this property has a default value and is likely to change often, so you need to create this one
`AmiID` - this property has default value so it can be left out from the main template

Add code bellow to _Properties_ section of the main template:
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
```yaml
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
```

#### 3. Add Parameters to EC2 stack
```yaml
      Parameters:
        AvailabilityZone: !Select [0, !Ref AvailabilityZones]
        EnvironmentType: !Ref EnvironmentType
```

#### 4. Pass variable from another nested stack

Before you update your CloudFormation nested stack, there is a last thing to do. You need to tell EC2 Security Group in which VPC to be created.
Without specifying VPC parameter, Security group is created in the _Default_ VPC. Lets fix that:

##### 1. Prep Security Group resource

1. Open up `code/60-setting-up-nested-stack/01-working directory/ec2.yaml` and locate the `WebServerSecurityGroup` resource.
1. Add `VpcId` property and reference VpcId parameter. Your security Group should look like the code bellow.
```yaml
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
1. Next, create parameter `VpcId` you have just referenced and add it to _Parameters_ section of the template.
```yaml
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: 'The ID of the VPC'
``` 

##### 2. Prep VPC template

To pass the variable from one stack to another, you need to first output the value in the stack that will be passing it on.
Then, using intrinsic function `!GetAtt`, CloudFormation will get the value from that stack and will pass it on as a parameter.

Add the code bellow to `code/60-setting-up-nested-stack/01-working directory/vpc.yaml` template.
```yaml
Outputs:
  VpcId:
    Value: !Ref VPC
```

##### 3. Add VpcId to _EC2Stack_ stack

Add `VpcId` parameter to the EC2 stack in the main.yaml template.
```yaml
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        AvailabilityZone: !Select [0, !Ref AvailabilityZones]
        EnvironmentType: !Ref EnvironmentType
        VpcId: !GetAtt VpcStack.Outputs.VpcId
```

##### 4. Prep IAM template

Open up `code/60-setting-up-nested-stack/01-working directory/iam.yaml` and add the code below.
```yaml
Outputs:
  WebServerInstanceProfile:
    Value: !Ref WebServerInstanceProfile
```

##### 5. Prep EC2 template

1. Open up `code/60-setting-up-nested-stack/01-working directory/ec2.yaml`
1. Create parameter `WebServerInstanceProfile` in _Parameters_ section of the template.
```yaml
  WebServerInstanceProfile:
    Type: String
    Description: 'Instance profile resource ID'
``` 

##### 6. Add WebServerInstanceProfile to _EC2Stack_ stack

Add `WebServerInstanceProfile` parameter to the EC2 stack in the main.yaml template.
```yaml
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        AvailabilityZone: !Select [0, !Ref AvailabilityZones]
        EnvironmentType: !Ref EnvironmentType
        VpcId: !GetAtt VpcStack.Outputs.VpcId
        WebServerInstanceProfile: !GetAtt IamStack.Outputs.WebServerInstanceProfile
```

#### 5. Upload the IAM stack to S3

Similarly to other stacks, upload the EC2 template to the S3.

#### 6. Deploy EC2 Nested Stack

Update previously created stack with a new template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the _root_ stack (it is the one without nested tag associated).
1. Select _replace current template_
1. Upload the new template file
1. Follow the wizard and click _Update stack_

---
<-- End of rezabekf PR -->

## Making changes to nested stacks

It's possible to change the template of a nested stack. For example, you may edit the properties of a resource in a stack, or add a resource. If you do so, deploy the parent stack to update the child stack.

## Why is it useful?

<!-- TODO convert to prose -->
* Decompose large templates - Avoid resource definition limits
* Reuse common components

<!-- TODO Write steps for completing main.template -->
## Conclusion

<!-- TODO Write Conclusion -->



