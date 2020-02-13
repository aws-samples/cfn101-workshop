---
title: 'Lab 10: Nested Stacks'
date: 2019-11-13T16:52:42Z
weight: 100
---

### Overview

Your CloudFormation template has grown considerably over the course of this workshop. As your infrastructure grows, common patterns can emerge in which you declare the same components in each of your templates.

You can separate out these common components and create dedicated templates for them. That way, you can mix and match different templates but use nested stacks to create a single, unified stack.

For example, you may wish to enable Systems Manager Session Manager access to every EC2 Instance. Instead of copying and pasting the same IAM role configuration, you can create a dedicated template containing the IAM role for the instance. Then, you just use the **[AWS::CloudFormation::Stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html)** resource to reference that template from within other templates.

### Topics Covered

In this lab, you will build:

1. **The _root_ stack** (which is also a parent stack for the first level stacks). This root stack will contain all the other stacks.
1. **The VPC stack**. This contains a simple VPC template which the EC2 instance will be placed into.
1. **The IAM instance role stack**. This contains the IAM instance role template decoupled form your EC2 template.
1. **The EC2 stack**. This contains the EC2 instance you have defined in your previous CloudFormation template.

> Top level and first level hierarchy of nested stacks.

![nested-stack-hierarchy](../nested-stack-hierarchy.png)

> The following diagram represents high level overview of the infrastructure:

![nested-stack-architecture](../ns-architecture.png)

### Start Lab

1. Go to the `code/50-nested-stacks/01-working directory`
1. Copy the code as you go through the topics below.

#### 1. Nested Stack Resource

To reference a CloudFormation stack in your template, use the `AWS::CloudFormation::Stack` resource.

It looks like this:

    Resources:
      NestedStackExample
        Type: AWS::CloudFormation::Stack
          Properties:
            TemplateURL: 'Path/To/Template'
            Parameters:
              ExampleKey: ExampleValue

The `TemplateURL` property is used to reference the CloudFormation template that you wish to nest.

The `Parameters` property allows you to pass parameters to your nested CloudFormation template.

#### 2. Prepare S3 bucket

Whilst single templates can be deployed from your local machine, Nested Stacks require that the nested templates are stored in an S3 bucket.

In the very first lab, you have created simple CloudFormation template which created S3 bucket. Please make a note of the bucket name.

For example:

Bucket name: `cfn-workshop-s3-s3bucket-2cozhsniu50t`

If you dont have S3 bucket, please go back to [Lab01](/30-workshop-part-01/10-cloudformation-fundamentals/200-lab-01-stack) and create one.

#### 3. Create VPC Nested Stack

The VPC template has been created for you. It is titled `vpc.yaml`. This template will create VPC stack with 2 Public Subnets, Internet Gateway, and Route tables.

##### 1. Create VPC parameters in the main template

If you look in the `vpc.yaml` file, you will notice that there are some parameters in the **Parameters** section of the template.

These parameters needs to be added to the main template so that they can be passed to the nested stack.

Copy the code below to the **Parameters** section of the `main.yaml` template.

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

##### 2. Create VPC resource in the main template
In the code below, note that passing parameter values to resources works the same as if using a single standalone template. Make sure that parameter name in the main template matches parameter name in the VPC template.

Add this code in the **Resources** section of the main template (`main.yaml`)

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

##### 3. Upload the VPC stack to S3

1. Navigate to your S3 bucket in the console and select it.
1. Click on **Upload** button -> **Add files**.
1. Locate the `vpc.yaml` file and select it.
1. Click **Upload** button to upload the file.

##### 4. Deploy VPC Nested Stack

1. Navigate to CloudFormation in the console and click **Create stack With new resources (standard)**.
1. In **Prepare template** select **Template is ready**.
1. In **Template source** select **Upload a template file**.
1. Choose a file `main.yaml`.
1. Enter a stack name. For example, cfn-workshop-nested-stack
1. For the `AvailabilityZones` parameter, select 2 AZs.
1. Fo the `S3BucketName` provide the name of the bucket you have wrote down in "Prepare S3 bucket" section.
1. You can leave rest of the parameters default.
1. Navigate through the wizard leaving everything default.
1. Acknowledge IAM capabilities and click on **Create stack**

#### 4. Create IAM Nested Stack

##### 1. Prepare IAM role template

The IAM role template has been created for you. It is titled `iam.yaml`. This template will create IAM role with `AmazonSSMManagedInstanceCore` policy which will allow [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) to access EC2 instance.

1. Open the `iam.yaml` file.
1. Copy the code below to the **Resources** section of the template.

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


##### 2. Create IAM resource in the main template
Copy the code below to the **Resources** section of the `main.yaml` template.

    IamStack:
      Type: AWS::CloudFormation::Stack
      Properties:
        TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/iam.yaml
        TimeoutInMinutes: 10

##### 3. Upload the IAM stack to S3

Similarly to the [VPC stack](#3-upload-the-vpc-stack-to-s3), upload the IAM template to the S3.

1. Navigate to your S3 bucket in the console and select it.
1. Click on **Upload** button -> **Add files**.
1. Locate the `iam.yaml` file and select it.
1. Click **Upload** button to upload the file.

##### 4. Deploy IAM Nested Stack

Update the previously created nested stack with a new template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the **root** stack (it is the one without the **nested** tag associated).
1. Select **replace current template**
1. Upload the new `main.yaml` template file.
1. Follow the wizard, acknowledge IAM capabilities and click on **Update stack**.

#### 5. Create EC2 Nested Stack

##### 1. Create EC2 parameters in the main template

Similarly to the VPC template, if you look into **Parameters** section of the `ec2.yaml` template there are three parameters:

* `SubnetId` - this property will be passed from VPC stack once the VPC stack is created.
* `EnvironmentType` - this property has a default value and is likely to change often, so let's add this one.
* `AmiID` - this property has default value, it can be left out from the main template.

Add the code below to the **Parameters** section of the main template:

    EnvironmentType:
      Description: 'Specify the Environment type of the stack.'
      Type: String
      Default: Test
      AllowedValues:
        - Dev
        - Test
        - Prod
      ConstraintDescription: 'Specify either Dev, Test or Prod.'

##### 2. Create EC2 resource in the main template

Copy the code below to the **Resources** section of the `main.yaml` template.

    EC2Stack:
      Type: AWS::CloudFormation::Stack
      Properties:
        TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
        TimeoutInMinutes: 20

##### 3. Add EnvironmentType to the EC2 stack

As you have added `EnvironmentType` parameter to the template, you need to reference this in `EC2Stack` resource.

Add the `EnvironmentType` parameter to the EC2 stack in the `main.yaml` template.
```yaml {hl_lines=[7]}
  EC2Stack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
      TimeoutInMinutes: 20
      Parameters:
        EnvironmentType: !Ref EnvironmentType
```

#### 6. Pass variable from another nested stack

Before you update your CloudFormation nested stack, there are a couple more things to do.

+ You need to specify which VPC to create the EC2 security group in. Without specifying the VPC parameter, the security group would be created in the **Default VPC**.

+ You need to specify which subnet to create the EC2 instance in.

##### 1. Prepare the security group resource

1. Open up `ec2.yaml` file and create two parameters, `VpcId` and `SubnetId` in **Parameters** section of the template.

       VpcId:
         Type: AWS::EC2::VPC::Id
         Description: 'The VPC ID'

       SubnetId:
         Type: AWS::EC2::Subnet::Id
         Description: 'The Subnet ID'

1. Next, locate the `WebServerSecurityGroup` resource.
1. Add `VpcId` property and reference `VpcId` parameter in the `WebServerSecurityGroup` resource. Your security group resource should look like the code below.

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

##### 2. Prepare the VPC template

To pass the variable from one stack to another, you need to create an output containing the value in the stack that will be passing it on.

Using the intrinsic function `!GetAtt`, CloudFormation can access the value from that stack and will pass it on as a parameter.

Add the code below to the `vpc.yaml` template.

    Outputs:
      VpcId:
        Value: !Ref VPC

      PublicSubnet1:
        Value: !Ref VPCPublicSubnet1

      PublicSubnet2:
        Value: !Ref VPCPublicSubnet2


##### 3. Add VpcId and SubnetId to **EC2Stack** stack

Now, you can grab the values from VPC stack and pass them to EC2 stack.

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

##### 4. Prepare the IAM template

Open up `iam.yaml` and add the code below.

    Outputs:
      WebServerInstanceProfile:
        Value: !Ref WebServerInstanceProfile

##### 5. Prepare the EC2 template

1. Open up `ec2.yaml`
1. Create the parameter `WebServerInstanceProfile` in the **Parameters** section of the template.

       WebServerInstanceProfile:
         Type: String
         Description: 'Instance profile resource ID'

##### 6. Add WebServerInstanceProfile to **EC2Stack** stack

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

##### 5. Upload the EC2 stack to S3
Before you can deploy the updated nested stack, you must update the templates in your S3 bucket that are referenced by the parent template, `main.yaml`.

Similar to the [uploading the VPC stack](#3-upload-the-vpc-stack-to-s3) in a previous step, upload the `ec2.yaml` and `iam.yaml` templates to your S3 bucket.

1. Navigate to your S3 bucket in the console and select it.
1. Click on **Upload** button -> **Add files**.
1. Locate the `iam.yaml` and `ec2.yaml` files and select them.
1. Click **Upload** button to upload the file.

##### 6. Deploy EC2 Nested Stack

Update the previously created nested stack with a new template.

1. Navigate to Cloudformation service in the AWS console.
1. Select the **root** stack (it is the one without nested tag associated).
1. Select **replace current template**.
1. Upload the new `main.yaml` template file.
1. Follow the wizard, acknowledge IAM capabilities and click on **Update stack**.

### Making changes to the Nested Stacks

It's possible to change components of a nested stack. For example, you may edit the properties of a resource in a stack, or add a resource.

To do so, follow the workflow below:

* First, make the updates to the required stacks.
* Then, upload the changed nested templates to S3.
* Finally, redeploy the parent stack to update the entire nested stack.

---
### Conclusion

Nested stacks allow you to compose CloudFormation templates. This allows you to decompose large templates into smaller reusable components. It also assists in avoiding resource limits of a single template. Nested Stack components are defined in a template like any other CloudFormation resource.
