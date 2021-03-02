---
title: 'Lab 11: Layered Stack'
date: 2020-02-16T14:46:43Z
weight: 100
---

### Overview
In the previous lab, we saw how we use the `Outputs` section and the `Fn::GetAtt` function to pass values from a child stack to parent stack. This enabled us to have dedicated templates for a VPC and an IAM role. As we mentioned previously, this gives us the ability to create templates that can be re-used. However, what about if we want to re-use **stacks**?

For example, you may have plans for many workloads deployed with many templates but every EC2 instance is expected to enable Systems Manager Session Manager access to every EC2 Instance. Similarly, you may wish to deploy a VPC via one stack and then use it with multiple future stacks and workloads. Achieving this one-many relationship is not possible in a Nested Stack scenario. This is where Layered Stacks come in.

We use **[Exports](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html)** to create global variables that can be **[Imported](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html)** into any CloudFormation stack.

### Topics Covered
In this lab, you will build:

1. **The VPC stack.** This contains the same simple VPC template used in the previous lab but with Export added to the Outputs.
1. **The IAM instance** role stack. This contains the same IAM instance role used in the previous lab but with Export added to the Outputs.
1. **The EC2 stack.** This contains the EC2 instance you have defined in previous labs but will make use of the Fn::ImportValue function.

Here is a diagram showing the hierarchy of layered stacks.

![layered-stack-hierarchy.png](100-lab-11-layered-stack/layered-stack-hierarchy.png)

This diagram represents the high-level overview of the infrastructure that will be deployed:

![layered-stack-hierarchy.png](100-lab-11-layered-stack/ls-architecture.png)

### Start Lab

You will find the working files in `code/50-layered-stack/01-working-directory`. In the rest of this lab, you should add your code to the templates here. The solution can be found in the `code/50-layered-stack/02-solution` folder. You can reference these against your code.

#### Create VPC Stack
The VPC template has been created for you. It is titled `vpc.yaml`. This template will create VPC stack with 2 Public Subnets, an Internet Gateway, and Route tables.

##### 1. Prepare the VPC template

{{% notice note %}}
All the files referenced in this lab can be found within `code/50-layered-stack`
{{% /notice %}}

If you look in the file `vpc.yaml` file, you will notice that there are some outputs in the **Outputs** section of the template. You will now add exports to each of these so that we can consume them from other CloudFormation stacks.

Add the highlighted lines shown below to your template file.

```yaml {hl_lines=[4,5,9,10,14,15]}
Outputs:
  VpcId:
    Value: !Ref VPC
    Export:
      Name: cfn-workshop-VpcId

  PublicSubnet1:
    Value: !Ref VPCPublicSubnet1
    Export:
      Name: cfn-workshop-PublicSubnet1

  PublicSubnet2:
    Value: !Ref VPCPublicSubnet2
    Export:
      Name: cfn-workshop-PublicSubnet2
```

##### 2. Deploy the VPC Stack

1. Navigate to CloudFormation in the console and click **Create stack With new resources (standard)**.
1. In **Prepare template** select **Template is ready**.
1. In **Template source** select **Upload a template file**.
1. Choose a file `vpc.yaml`.
1. Enter a **stack name**. For example, `cfn-workshop-vpc`.
1. For the **AvailabilityZones** parameter, select **2 AZs**.
1. You can leave the rest of the parameters **default**.
1. Navigate through the wizard leaving everything default.
1. On the Review page, scroll down to the bottom and click on **Create stack**.

#### Create IAM Stack

##### 1. Prepare the IAM role template

1. Open `iam.yaml` file.
1. Copy the highlighted lines below to the **Outputs** section of the template.
    ```yaml {hl_lines=[4,5]}
    Outputs:
      WebServerInstanceProfile:
        Value: !Ref WebServerInstanceProfile
        Export:
          Name: cfn-workshop-WebServerInstanceProfile
    ```

##### 2. Deploy the IAM Stack

1. Navigate to CloudFormation in the console and click **Create stack With new resources (standard)**.
1. In **Prepare template** select **Template is ready**.
1. In **Template source** select **Upload a template file**.
1. Choose a file `02-lab11-iam.yaml`.
1. Enter a **stack name**. For example, `cfn-workshop-iam`.
1. Click **Next**.
1. Navigate through the wizard leaving everything default.
1. **Acknowledge IAM capabilities** and click on **Create stack**.

#### Create EC2 Layered Stack

##### 1. Prepare the EC2 template
The concept of the **Layered Stack** is to use intrinsic functions to import previously exported values instead of using **Parameters**. Therefore, the first change to make to the `ec2.yaml` is to remove the parameters that will no longer be used; `SubnetId`, `VpcId`, and `WebServerInstanceProfile`.

##### 2. Update the Parameters section

Update the Parameters section to look as follows:

```yaml
Parameters:
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Dev
      - Test
      - Prod
    ConstraintDescription: 'Specify either Dev, Test or Prod.'

  AmiID:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Description: 'The ID of the AMI.'
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```

##### 3. Update WebServerInstance resource

Next, we need to update the `Fn::Ref` in the template to import the exported values from the vpc and iam stacks created earlier. We perform this import by using the [Fn::ImportValue](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) intrinsic function.

Update WebServerInstance resource in the Resources section of the `ec2.yaml` template:

```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    {...}
    Properties:
      SubnetId: !ImportValue cfn-workshop-PublicSubnet1
      IamInstanceProfile: !ImportValue cfn-workshop-WebServerInstanceProfile
      ImageId: !Ref AmiID
      InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
    {...}
```

##### 4. Update the security group
Finally, update the security group resource similarly. Update `WebServerSecurityGroup` resource in the **Resources** section of the `ec2.yaml` template.

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
    VpcId: !ImportValue cfn-workshop-VpcId
```

##### 5. Deploy the EC2 Stack

1. Navigate to CloudFormation in the console and click **Create stack With new resources (standard)**.
1. In **Prepare template** select **Template is ready**.
1. In **Template source** select **Upload a template file**.
1. Choose a file `ec2.yaml`.
1. Enter a **stack name**. For example, `cfn-workshop-ec2`.
1. You can leave the rest of the parameters **default**.
1. Navigate through the wizard leaving everything default.
1. On the **Review page**, scroll down to the bottom and click on **Create stack**.

#### 7. Test the deployment

##### 1. Verify that application was deployed successfully

Open a new browser window in private mode and enter the `WebsiteURL` (you can get the WebsiteURL from the **Outputs** tab of the EC2 stack in the CloudFormation console).
You should see some instance metadata, similar to the picture below.

![ami-id](100-lab-11-layered-stack/ami-id-1.png)

##### 2. Log in to the instance using SSM Session Manager

Verify that you can log in to the instance via Session Manager.

If you not sure how to do that, follow the instructions from the [Lab 07: SSM - Session Manager](/30-workshop-part-01/30-launching-ec2/200-lab-07-session-manager.html#challenge)

### Clean up

{{% notice info %}}
After the stack imports an output value, you can't delete the stack that is exporting the output value or modify the exported output value. All the imports must be removed before you can delete the exporting stack or modify the output value.
{{% /notice %}}

For example, you can not delete the **VPC stack** before you delete **EC2 stack**. You get following error message:

![delete-export-before-import.png](100-lab-11-layered-stack/delete-export-before-import.png)

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the **EC2 stack**, for example `cfn-workshop-ec2`.
1. In the top right corner, click on **Delete**.
1. In the pop up window click on **Delete stack**.
1. Hit the **refresh** button a few times until you see in the status **DELETE_COMPLETE**.
1. Now you can delete **IAM** and **VPC** stack in any other as there are no more dependencies.

---
### Conclusion
**Layered stacks** allow you to create resources that can be used again and again in multiple stacks. All the stack needs to know is the **Export** name used. They allow the separation of roles and responsibilities. For example, a network team could create and supply an approved VPC design as a template. You deploy it as a stack and then just reference the Exports as needed. Similarly, a security team could do the same for IAM roles or EC2 security groups.
