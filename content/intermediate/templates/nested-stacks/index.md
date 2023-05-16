---
title: "Nested stacks"
weight: 400
---

_Lab Duration: ~30 minutes_

---

### Overview

Your CloudFormation template has grown considerably over the course of this workshop. As your infrastructure grows, common
patterns can emerge in which you declare the same components in each of your templates.

You can separate out these common components and create dedicated templates for them. That way, you can mix and match
different templates but use **[nested stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html)**
to create a single, unified stack.

For example, you may wish to enable Systems Manager Session Manager access to every EC2 Instance. Instead of copying and
pasting the same IAM role configuration, you can create a dedicated template containing the IAM role for the instance.
Then, you just use the **[AWS::CloudFormation::Stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-stack.html)**
resource to reference that template from within other templates.

### Topics Covered

In this lab, you will build:

1. **The _root_ stack** (which is also a parent stack for the first level stacks). This root stack will contain all the other stacks.
1. **The VPC stack**. This contains a simple VPC template which the EC2 instance will be placed into.
1. **The IAM instance role stack**. This contains the IAM instance role template decoupled form your EC2 template.
1. **The EC2 stack**. This contains the EC2 instance you have defined in your previous CloudFormation template.

> Top level and first level hierarchy of nested stacks.

![nested-stack-hierarchy](/static/intermediate/templates/nested-stacks/nested-stack-hierarchy.png)

> The following diagram represents high level overview of the infrastructure:

![nested-stack-architecture](/static/intermediate/templates/nested-stacks/ns-architecture.png)

### Start Lab

1. Go to the `code/workspace/nested-stacks`
1. Copy the code as you go through the topics below.

#### 1. Nested Stack Resource

To reference a CloudFormation stack in your template, use the `AWS::CloudFormation::Stack` resource.

It looks like this:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
Resources:
  NestedStackExample:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: 'Path/To/Template'
      Parameters:
        ExampleKey: ExampleValue
:::

The `TemplateURL` property is used to reference the CloudFormation template that you wish to nest.

The `Parameters` property allows you to pass parameters to your nested CloudFormation template.

#### 2. Prepare S3 bucket

Whilst single templates can be deployed from your local machine, Nested Stacks require that the nested templates are stored in an S3 bucket.

In the very first lab, you have created simple CloudFormation template which created S3 bucket. Please make a note of the bucket name.

For example:

Bucket name: `cfn-workshop-s3-s3bucket-2cozhsniu50t`

If you don't have S3 bucket, please go back to [Template and stack](/basics/templates/template-and-stack) lab and create one.

#### 3. Create VPC Nested Stack

The VPC template has been created for you. It is titled `vpc.yaml`. This template will create VPC stack with 2 Public Subnets, Internet Gateway, and Route tables.

##### 1. Create VPC parameters in the main template

If you look in the `vpc.yaml` file, you will notice that there are some parameters in the **Parameters** section of the template.

These parameters need to be added to the main template so that they can be passed to the nested stack.

Copy the code below to the **Parameters** section of the `main.yaml` template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
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
:::

##### 2. Create VPC resource in the main template
In the code below, note that passing parameter values to resources works the same as if using a single standalone template.
Make sure that parameter name in the main template matches parameter name in the VPC template.

Add this code in the **Resources** section of the main template (`main.yaml`)

:::code{language=yaml showLineNumbers=true showCopyAction=true}
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
:::

##### 3. Upload the VPC stack to S3

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Run the below command to copy the `vpc.yaml` to S3 bucket. Replace the `bucket-name` with the bucket name from previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp vpc.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [S3 console](https://console.aws.amazon.com/s3/home) and select your bucket.
1. Click on **Upload** button, **Add files**.
1. Locate the `vpc.yaml` file and select it.
1. Click **Upload** button to upload the file.
::::
:::::

##### 4. Deploy VPC Nested Stack

:::alert{type="info"}
Please note **YAML** is indention sensitive mark down language. If `cfn-lint` or CloudFormation console reports errors,
such as `Template format error: [/Resources/VpcStack] resource definition is malformed`, \
please double-check **Parameters** and **Resources** sections are correctly formatted.\
See the earlier [Linting and Testing](/basics/templates/linting-and-testing) lab to install or for more guidance.
:::

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Use AWS EC2 Api to get list of availability zones from your vpc and copy any 2 AZ's from the output to use them in next step:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **bucketName** with the value you have written down in [Prepare S3 bucket](#2.-prepare-s3-bucket) section. Replace the `ParameterValue` **AZ1** and **AZ2** which you copied in previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation create-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=json showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to CloudFormation in the console and click **Create stack With new resources (standard)**.
1. In **Prepare template** select **Template is ready**.
1. In **Template source** select **Upload a template file**.
1. Choose a file `main.yaml`.
1. Enter a **Stack name**. For example, `cfn-workshop-nested-stacks`.
1. For the **AvailabilityZones** parameter, select 2 AZs.
1. For the **S3BucketName** provide the name of the bucket you have written down in [Prepare S3 bucket](#2.-prepare-s3-bucket) section.
1. You can leave rest of the parameters default and choose **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick both **IAM Capabilities** check boxes.
    ![iam-capabilities.png](/static/intermediate/templates/nested-stacks/iam-capabilities.png)
1. Click on **Submit**. You can view the progress of Nested stacks being created in CloudFormation console.
1. In a few minutes, stacks will be created. Hit the refresh button a few times until you see in the status CREATE_COMPLETE.
::::
:::::

#### 4. Create IAM Nested Stack

##### 1. Prepare IAM role template

The **IAM role** template has been created for you. It is titled `iam.yaml`. This template will create IAM role with
`AmazonSSMManagedInstanceCore` policy which will allow [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
to access EC2 instance.

1. Open the `iam.yaml` file.
1. Copy the code below to the **Resources** section of the template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
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
:::

##### 2. Create IAM resource in the main template
Copy the code below to the **Resources** section of the `main.yaml` template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
IamStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/iam.yaml
    TimeoutInMinutes: 10
:::

##### 3. Upload the IAM stack to S3

Similarly to the [VPC stack](#3.-upload-the-vpc-stack-to-s3), upload the IAM template to the S3.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=true showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Run the below command to copy the `iam.yaml` to S3 bucket. Replace the `bucket-name` with the bucket name from previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp iam.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [S3 console](https://console.aws.amazon.com/s3/home) and select your bucket.
1. Click on **Upload** button, **Add files**.
1. Locate the `iam.yaml` file and select it.
1. Click **Upload** button to upload the file.
::::
:::::

##### 4. Deploy IAM Nested Stack

Update the previously created nested stack with a new template.
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Use AWS EC2 Api to get list of availability zones from your vpc and copy any 2 AZ's from the output to use them in next step:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **bucketName** with the value you have written down in [Prepare S3 bucket](#2.-prepare-s3-bucket) section. Replace the `ParameterValue` **AZ1** and **AZ2** which you copied in previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to Cloudformation service in the AWS console.
1. Select the **root** stack (it is the one without the **nested** tag associated).
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the `main.yaml` template file and click **Next**.
1. Follow the wizard, acknowledge IAM capabilities and click on **Submit**.
::::
:::::

#### 5. Create EC2 Nested Stack

##### 1. Create EC2 parameters in the main template

Similarly to the VPC template, if you look into **Parameters** section of the `ec2.yaml` template there are three parameters:

* `SubnetId` - this property will be passed from VPC stack once the VPC stack is created.
* `EnvironmentType` - this property has a default value and is likely to often change, so let's add this one.
* `AmiID` - this property has default value, it can be left out from the main template.

Add the code below to the **Parameters** section of the `main.yaml` template:

:::code{language=yaml showLineNumbers=true showCopyAction=true}
EnvironmentType:
  Description: 'Specify the Environment type of the stack.'
  Type: String
  Default: Test
  AllowedValues:
    - Dev
    - Test
    - Prod
  ConstraintDescription: 'Specify either Dev, Test or Prod.'
:::

##### 2. Create EC2 resource in the main template

Copy the code below to the **Resources** section of the `main.yaml` template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
:::

##### 3. Add EnvironmentType to the EC2 stack

As you have added `EnvironmentType` parameter to the template, you need to reference this in `EC2Stack` resource.

Add the `EnvironmentType` to the `Parameters` section of the EC2 stack in the `main.yaml` template, lines [6-7]:
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=6-7}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
    Parameters:
      EnvironmentType: !Ref EnvironmentType
:::

#### 6. Pass variable from another nested stack

Before you update your CloudFormation nested stack, there are a couple more things to do.

+ You need to specify which VPC to create the EC2 security group in. Without specifying the VPC parameter, the security group would be created in the **Default VPC**.

+ You need to specify which subnet to create the EC2 instance in.

##### 1. Prepare the security group resource

1. Open up `ec2.yaml` file and create two parameters, `VpcId` and `SubnetId` in **Parameters** section of the template.

  :::code{language=yaml showLineNumbers=true showCopyAction=true}
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: 'The VPC ID'

  SubnetId:
    Type: AWS::EC2::Subnet::Id
    Description: 'The Subnet ID'
  :::

1. Next, locate the `WebServerSecurityGroup` resource.
1. Add `VpcId` property and reference `VpcId` parameter in the `WebServerSecurityGroup` resource, line [18]. Your security group resource should look like the code below.
  :::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=18}
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable HTTP and HTTPS access
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
        - IpProtocol: tcp
       FromPort: 80
       ToPort: 80
       CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
       FromPort: 443
       ToPort: 443
       CidrIp: 0.0.0.0/0
      VpcId: !Ref VpcId
  :::

##### 2. Prepare the VPC template

To pass the variable from one stack to another, you need to create an output containing the value in the stack that will be passing it on.

Using the intrinsic function `!GetAtt`, CloudFormation can access the value from that stack and will pass it on as a parameter.

Add the code below to the `vpc.yaml` template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  VpcId:
    Value: !Ref VPC

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
:::

##### 3. Add VpcId and SubnetId to **EC2Stack** stack

Now, you can grab the values from VPC stack and pass them to EC2 stack.

Add `VpcId` and `SubnetId` parameters to the EC2 stack in the `main.yaml` template.
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=8-9}
EC2Stack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: !Sub https://${S3BucketName}.s3.amazonaws.com/ec2.yaml
    TimeoutInMinutes: 20
    Parameters:
      EnvironmentType: !Ref EnvironmentType
      VpcId: !GetAtt VpcStack.Outputs.VpcId
      SubnetId: !GetAtt VpcStack.Outputs.PublicSubnet1
:::

##### 4. Prepare the IAM template

Open up `iam.yaml` and add the code below.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  WebServerInstanceProfile:
    Value: !Ref WebServerInstanceProfile
:::

##### 5. Prepare the EC2 template

1. Open up `ec2.yaml`
1. Create the parameter `WebServerInstanceProfile` in the **Parameters** section of the template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
WebServerInstanceProfile:
  Type: String
  Description: 'Instance profile resource ID'
:::

##### 6. Add WebServerInstanceProfile to **EC2Stack** stack

Add the `WebServerInstanceProfile` parameter to the EC2 stack in the `main.yaml` template, line[10].
:::code{language=yaml showLineNumbers=true showCopyAction=true highlightLines=10}
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
:::

##### 7. Output the `WebsiteURL` in the main template

Add the `WebsiteURL` to the `Outputs` section of the `main.yaml` template.

:::code{language=yaml showLineNumbers=true showCopyAction=true}
Outputs:
  WebsiteURL:
    Value: !GetAtt EC2Stack.Outputs.WebsiteURL
:::

##### 8. Upload the EC2 stack to S3
Before you can deploy the updated nested stack, you must update the templates in your S3 bucket that are referenced by the parent template, `main.yaml`.

Similar to the [uploading the VPC stack](#3.-upload-the-vpc-stack-to-s3) in a previous step, upload the `vpc.yaml`, `ec2.yaml`
and `iam.yaml` templates to your S3 bucket.


:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Run the below command to copy the `iam.yaml`, `vpc.yaml` and `ec2.yaml` to S3 bucket. Replace the `bucket-name` with the bucket name from previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws s3 cp iam.yaml s3://{bucket-name}
aws s3 cp vpc.yaml s3://{bucket-name}
aws s3 cp ec2.yaml s3://{bucket-name}
  :::
::::
::::tab{id="local" label="Local development"}
1. Navigate to your S3 bucket in the console and select it.
1. Click on **Upload** button -> **Add files**.
1. Locate the `vpc.yaml`, `iam.yaml` and `ec2.yaml` files and select them.
1. Click **Upload** button to upload the file.
::::
:::::

##### 9. Deploy EC2 Nested Stack

Update the previously created nested stack with a new template.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/nested-stacks`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/nested-stacks
  :::
1. Use AWS EC2 Api to get list of availability zones from your vpc and copy any 2 AZ's from the output to use them in next step:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws ec2 describe-availability-zones --output json --query "AvailabilityZones[*].ZoneName"
  :::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **bucketName** with the value you have written down in [Prepare S3 bucket](#2.-prepare-s3-bucket) section. Replace the `ParameterValue` **AZ1** and **AZ2** which you copied in previous step.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-nested-stacks \
  --template-body file://main.yaml \
  --parameters ParameterKey="S3BucketName",ParameterValue="bucketName" ParameterKey="AvailabilityZones",ParameterValue=AZ1\\,AZ2 \
  --capabilities CAPABILITY_NAMED_IAM
  :::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=json showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-nested-stacks/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to Cloudformation service in the AWS console.
1. Select the **root** stack (it is the one without the **nested** tag associated).
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the `main.yaml` template file and click **Next**.
1. Follow the wizard, acknowledge IAM capabilities and click on **Submit**.
::::
:::::

#### 7. Test the deployment

##### 1. Verify that application has been deployed successfully

Open a new browser window in private mode and enter the `WebsiteURL`.

You can get the `WebsiteURL` from the **Outputs** tab of the main stack in CloudFormation console.

![website-url-output.png](/static/intermediate/templates/nested-stacks/website-url-output.png)

In the browser window, you should see some instance metadata, similar to the picture below.

![ami-id](/static/intermediate/templates/nested-stacks/ami-id-1.png)

##### 2. Log in to instance using SSM Session Manager

Verify that you can log in to the instance via **[Session Manager](https://console.aws.amazon.com/systems-manager)**. Select the same region as the instance is deployed in, for example `US East (N. Virginia) us-east-1`.

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the **root** stack you have created in this lab. For example `cfn-workshop-nested-stacks`.
1. The **root** stack will handle the deletion of all the **children** stacks for you.
1. In the top right corner, click on **Delete**.
1. In the pop-up window click on **Delete**.
1. You can click the **refresh** button a few times until you see in the status **DELETE_COMPLETE**.

---
### Conclusion

Nested stacks allow you to compose CloudFormation templates. This allows you to decompose large templates into smaller
reusable components. It also assists in avoiding resource limits of a single template. Nested Stack components are defined
in a template like any other CloudFormation resource.
