---
title: "Create an Example Module"
weight: 320
---

### Overview

In this lab, you will follow steps to register a sample CloudFormation module as a private extension with the AWS CloudFormation registry in your AWS account for a specified AWS region.

For this example you will create a module that deploys an entire [Amazon Virtual Private Cloud](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) (Amazon VPC), including associated resources with defaults set. This example has been chosen to show how something as complex as a VPC can be defined by a central team in a best practice way and then consumed easily by other teams.

### Topics Covered

By the end of this lab, you will be able to:

* understand key concepts to leverage when you develop a module;
* use the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) to create a new project and submit the module as a private extension to the CloudFormation registry in your AWS account for a specified AWS region;
* understand how to consume the module in CloudFormation templates.

### Start Lab

#### Sample Module Walkthrough

Let's get started! Create a new directory and then issue the following commands from inside that directory:

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir module
cd module
cfn init
:::

You will be prompted to answer some questions. Supply the answers as shown below:

:::code{language=shell showLineNumbers=false showCopyAction=false}
Initializing new project
Do you want to develop a new resource(r) or a module(m) or a hook(h)?.
>> m
What's the name of your module type?
(<Organization>::<Service>::<Name>::MODULE)
>> CFNWORKSHOP::EC2::VPC::MODULE
Directory  /PATH-TO-YOUR-DIRECTORY/cfn101-workshop/module/fragments  Created
Initialized a new project in /PATH-TO-YOUR-DIRECTORY/cfn101-workshop/module
:::

Let's take a look at what the command created in the directory structure:

* `fragments/`: contains an auto generated `sample.json` CloudFormation template file;
* `.rpdk-config`: this is the config file that stores the details you supplied when you ran the init command above;
* `rpdk.log`: a log file for the actions carried out by the cfn cli;


Let's first clean up a little. You will be using the YAML format for this workshop, so go ahead and delete the `sample.json` file, you will not need it:

:::code{language=shell showLineNumbers=false showCopyAction=true}
rm fragments/sample.json
:::

CloudFormation modules are created using a standard CloudFormation template, just like those you have been creating already in this workshop. However, modules can use a single template file only; no nested stacks are supported. For more information, see _Creating the module template fragment_ and _Considerations when authoring the template fragment_ in the [Module structure](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/modules-structure.html) documentation.

The following diagram shows the VPC resources that you will be including in your example module.

![vpc-diagram](/static/advanced/modules/vpc.png)

Create a new YAML file for your module within the `fragments` folder:

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch fragments/module.yaml
:::

Open `module.yaml` file in your text editor and paste in the following CloudFormation YAML:

<!-- vale off -->
:::code{language=yaml showLineNumbers=true showCopyAction=true}
AWSTemplateFormatVersion: 2010-09-09

Description: A full VPC Stack

Parameters:

  VpcCidr:
    Type: String

Resources:

  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref Vpc
      InternetGatewayId: !Ref InternetGateway

  EIP1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  EIP2:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc

  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public1Subnet
      AllocationId: !GetAtt EIP1.AllocationId

  NATGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public2Subnet
      AllocationId: !GetAtt EIP2.AllocationId

  Public1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true

  Public2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true

  Private1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [2, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false

  Private2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [3, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false

  Public1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Public2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Private1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Private2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc

  Public1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Public1RouteTable
      SubnetId: !Ref Public1Subnet

  Public2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Public2RouteTable
      SubnetId: !Ref Public2Subnet

  Private1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Private1RouteTable
      SubnetId: !Ref Private1Subnet

  Private2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref Private2RouteTable
      SubnetId: !Ref Private2Subnet

  Public1DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn:
      - VPCGatewayAttachment
    Properties:
      RouteTableId: !Ref Public1RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  Public2DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn:
      - VPCGatewayAttachment
    Properties:
      RouteTableId: !Ref Public2RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  Private1DefaultRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref Private1RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway1

  Private2DefaultRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref Private2RouteTable
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NATGateway2
:::
<!-- vale on -->

This CloudFormation template has 23 resources and will be very familiar to anyone that has used CloudFormation to deploy an entire VPC. With so many components it can be hard to ensure that all the VPCs you deploy are done in a standard way and no mistakes or differences are made.

This is a great use case for CloudFormation modules. These resources can be placed in a single module that can be used by many teams as many times as they wish, removing the complexity and chance of error or differences when needed multiple times.

You will have noticed that template has a parameter; `VpcCidr`. This will be available when consuming the module so that users can use a standard deployment but still have the ability to tailor it to their use case.

Now that you have the `YAML` file complete, you are ready to submit this as a Module to the CloudFormation registry. The command below registers the module in the default region; if you wish to specify a region, append the `--region` option to the command, for example `--region us-east-2`.

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn submit
:::

You will see output as below:

:::code{language=shell showLineNumbers=false showCopyAction=false}
Module fragment is valid.
Successfully submitted type. Waiting for registration with token '{token}' to complete.
Registration complete.
{'ProgressStatus': 'COMPLETE', 'Description': 'Deployment is currently in DEPLOY_STAGE of status COMPLETED', ...
...}
:::

You can now visit the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/), and you should be able to see your new module in the `Activated extensions` section of the relevant registry page.

![activated-extensions](/static/advanced/modules/ActivatedExtensions.png)
