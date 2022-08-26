---
title: "Consume the Example Module"
weight: 330
---

#### Using the Sample Module

You have just created and registered a new CloudFormation Module with the private registry in your AWS account and for a given AWS Region. This means that your module can now be used in CloudFormation template(s) you will leverage to create/update stack(s) in the same AWS Account and Region.

Let's see how you can consume it.

Create a new YAML file:

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch use-module.yaml
:::

Open this file in your chosen text editor and paste the following CloudFormation YAML:

<!-- vale off -->
:::code{language=yaml showLineNumbers=false showCopyAction=true}
AWSTemplateFormatVersion: 2010-09-09

Resources:

  Vpc:
    Type: CFNWORKSHOP::EC2::VPC::MODULE
    Properties:
      VpcCidr: 10.1.0.0/16
:::
<!-- vale on -->

That's it. Nice and short isn't it? You can see why Modules are going to be so useful.

Let's create a new stack from that template using the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deploy --template-file use-module.yaml --stack-name cfn-workshop-modules
:::

### Taking a closer look

Now that the Stack is deployed let's take a closer look at what actually happened. It will help to understand more on how Modules work in CloudFormation.

Open the AWS Console and navigate to the CloudFormation service. Locate the stack that you just created and select the `Resources` tab.
Notice that the Stack is showing it has 23 resources.

![stack-resources](/static/advanced/modules/StackResources.png)

This number of resources can be explained if we take a look at the processed template for this stack. You can see that the actual template that CloudFormation deploys is based upon the content of the Module.
When a Module is consumed in a CloudFormation template the Module resource is replaced with the resources defined for it in the Module template.

![stack-template](/static/advanced/modules/StackTemplate.png)





### Challenge

Add tags to the resources so that the resources created are easily identifiable.

:::expand{header="Need a hint?"}
* Update the `module.yaml` file to add Tags to all the resources that support them. Documentation for adding tags to a VPC can be found [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html#cfn-ec2-vpc-tags).

* Submit the changes, and set the new module version as the default version. For more information, see the `submit` [command](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-cli-submit.html) in the CloudFormation Command Line Interface reference.

* Update he `use-module.yaml` to include the new Tag parameter value.

* Perform a stack update on the `cfn-workshop-modules` stack.
:::

:::expand{header="Want to see the solution?"}

Update the content of the `module.yaml` file as follows:

<!-- vale off -->
```yaml
AWSTemplateFormatVersion: 2010-09-09

Description: A full VPC Stack

Parameters:

  VpcCidr:
    Type: String

  NameTag:
    Type: String

Resources:

  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags:
        - Key: Name
          Value: !Ref NameTag

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Ref NameTag

  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref Vpc
      InternetGatewayId: !Ref InternetGateway

  EIP1:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  EIP2:
    Type: AWS::EC2::EIP
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  NATGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public1Subnet
      AllocationId: !GetAtt EIP1.AllocationId
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  NATGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      SubnetId: !Ref Public2Subnet
      AllocationId: !GetAtt EIP2.AllocationId
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Public1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  Public2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Private1Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [2, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet1

  Private2Subnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref Vpc
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [3, !Cidr [!GetAtt Vpc.CidrBlock, 4, 14 ]]
      MapPublicIpOnLaunch: false
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet2

  Public1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet1

  Public2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PublicSubnet2

  Private1RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet1

  Private2RouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${NameTag}/PrivateSubnet2

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
```
<!-- vale on -->

Execute the following command to submit this new version as the default version:

```shell
cfn submit --set-default
```

Update the content of the `use-module.yaml` file as follows:

<!-- vale off -->
```yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:

  Vpc:
    Type: CFNWORKSHOP::EC2::VPC::MODULE
    Properties:
      VpcCidr: 10.1.0.0/16
      NameTag: VPCModule
```
<!-- vale on -->

Execute another deploy command to update the stack:

```shell
aws cloudformation deploy --template-file use-module.yaml --stack-name cfn-workshop-modules
```
:::
