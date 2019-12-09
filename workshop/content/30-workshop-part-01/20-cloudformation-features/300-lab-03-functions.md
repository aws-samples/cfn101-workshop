---
title: 'Lab 03: Intrinsic Functions'
date: 2019-11-01T13:36:34Z
weight: 300
---
  
When creating a CloudFormation template, it's common to reference one CloudFormation resource from another. 
For example, if you have a security group, you need to know the ID of the VPC to attach the group to. 
This is a problem because the `VpcId` is only known when you deploy the VPC resource. 

How can you refer to values in your CloudFormation template that are only know at deployment?

CloudFormation provides several built in functions that help with this problem.
These can evaluate expressions in CloudFormation when being deployed. 

For example, it is often neccessary to refer to one CloudFormation resource in another resource using the function, `Fn::Ref`. 
AWS CloudFormation provides several built-in functions that help you manage your stacks. 
Use intrinsic functions in your templates to assign values to properties that are not available until runtime.

In this Lab, you will use the [`Fn::Ref`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) and [`Fn::Join`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html) functions to assign values to your EC2 resource properties. 

{{% notice info %}}
More functions, such as `Fn::Base64`, `Fn::FindInMap`, `Fn::GetAtt` and `Fn::Sub` will be introduced in the feature labs.
You can find full list of supported functions in the
[AWS Documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).
{{% /notice %}}

{{% notice note %}} 
Intrinsic functions can only be used in certain parts of a template. You can use intrinsic functions in 
**resource properties, outputs, metadata attributes, and update policy attributes**.
{{% /notice %}}

**Let's go!**

1. Go to the `code/40-cloudformation-features/` directory.
1. Open the `03-lab03-IntrinsicFunctions.yaml` file.
1. Copy the code as you go through the topics below.

#### Ref <a id="ref"></a>
The intrinsic function _Ref_ returns the value of the specified _parameter_ or _resource_.

Yaml Syntax:
```
!Ref
```

In the last lab you have "hard coded" an AMI ID directly into the EC2 Resource property. You will now amend this to make your 
template more flexible. Let's convert AMI ID to variable and pass it to resource property at the runtime.

1. First, create new parameter called `AmiID` and put it in the `Parameters` section of your template.

    ```yaml
      AmiID:
        Type: AWS::EC2::Image::Id
        Description: 'The ID of the AMI.'
    ```
   
    **Challenge:**
    
    Add the `AmiID` to ParameterGroup and label it `Amazon Machine Image ID`

      {{%expand "Expand here to see the solution" %}}
```yaml
      ParameterGroups:
        - Label:
            default: 'Amazon EC2 Configuration'
          Parameters:
            - InstanceType
            - AmiID

      ParameterLabels:
        InstanceType:
          default: 'Type of EC2 Instance'

        AmiID:
          default: 'Amazon Machine Image ID'
```
    {{% /expand %}}

1. Use the intrinsic function `Ref` to pass the `AmiID` parameter input to resource property.
    ```yaml
          ImageId: !Ref AmiID
    ```

#### Fn::Join <a id="join"></a>
The intrinsic function _Fn::Join_ appends a set of values into a single value, separated by the specified delimiter.

Yaml Syntax:
```
!Join [ delimiter, [ comma-delimited list of values ] ]
```

It is always a good idea to tag your resources. You can use the intrinsic function _Fn::Join_ to create a string.

```yml
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref InstanceType, Web Server ] ]
```

#### Exercise

Now it is time to update your stack. 

Go to the AWS console and update your CloudFormation Stack.

{{%expand "Expand here to see the solution" %}}
![update-gif](../update-1.gif)
{{% /expand %}}
