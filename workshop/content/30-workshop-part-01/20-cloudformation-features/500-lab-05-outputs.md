---
title: 'Lab 05: Outputs'
date: 2019-11-05T09:25:05Z
weight: 500
---

_Outputs_ enable us to get access to information about resources within a stack. For example, you can output an EC2 
instance's Public DNS name once it is created.

Furthermore, output values can be imported into other stacks. These are known as cross-stack references. 
(You will see this in action once we get to the _Nested Stacks_ lab.)

##### YAML Syntax:
The _Outputs_ section consists of the key name `Outputs`, followed by a colon. 

{{% notice note %}}
You can declare a maximum of 60 outputs in a template.
{{% /notice %}}

```yaml
Outputs:
  Logical ID:
    Description: Information about the value
    Value: Value to return
    Export:
      Name: Value to export
```

**Let's go!**

1. Go to the `code/40-cloudformation-features/` directory.
1. Open the `07-lab05-Outputs.yaml` file.
1. Copy the code as you go through the topics below.

    To get the _PublicDnsName_ of the instance, you will need to use `Fn::GetAtt` intrinsic function. Let's first check
    the [AWS Documentation](https://docs.aws.amazon.com/en_pv/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values)
    for available attributes. You can see that _PublicDnsName_ is valid return value for `Fn::GetAtt` function.
    Add the section below to your template:

```yaml
Outputs:
  EC2PublicDNS:
    Description: 'Public DNS of EC2 instance'
    Value: !GetAtt WebServerInstance.PublicDnsName
``` 
1. Go to the AWS console and update your stack with a new template.
{{%expand "How do I update a Stack?" %}}
Go to the AWS console and deploy the stack the same way you did in 
the [Lab 03: Intrinsic Functions](../300-lab-03-functions)
![](/40-cloudformation-features/update-1.gif)
{{% /expand %}}

1. View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.
{{%expand "How to view Outputs?" %}}
![](/40-cloudformation-features/outputs-1.gif)
{{% /expand %}}

#### Exercise
> In this exercise, you should assign an Elastic IP to your EC2 instance. Then, add an output of the Elastic IP to the _Outputs_ 
>section of the template. You should continue using the `code/40-cloudformation-features/07-lab05-Outputs.yaml` template.

1. Create an `AWS::EC2::EIP` resource and attach it to your existing EC2 instance.
1. Create a logical ID called `ElasticIP` and add it to the Outputs section of the template. 

{{%expand "Need a hint?" %}}
Check out the AWS Documentation for [AWS::EC2::EIP resource](https://docs.aws.amazon.com/en_pv/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-eip.html)
{{% /expand %}}

{{%expand "Want to see the solution?" %}}
```yaml
Resources:
  WebServerInstance:
    Type: 'AWS::EC2::Instance'
    Properties:
      ImageId: !Ref AmiID
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref InstanceType, Web Server ] ]

  EC2EIP:
    Type: 'AWS::EC2::EIP'
    Properties:
      Domain: vpc
      InstanceId: !Ref WebServerInstance

Outputs:
  EC2PublicDNS:
    Description: 'Public DNS of EC2 instance'
    Value: !GetAtt WebServerInstance.PublicDnsName

  ElasticIP:
    Description: 'Elastic IP assigned to EC2'
    Value: !Ref EC2EIP
```
{{% /expand %}}





