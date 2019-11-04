---
title: "Lab 03: Intrinsic Functions"
date: 2019-11-01T13:36:34Z
weight: 200
---
  
AWS CloudFormation provides several built-in functions that help you manage your stacks. Use intrinsic functions in 
your templates to assign values to properties that are not available until runtime.

In this Lab, you will use the `Ref` and `Fn::Join` functions to assign values to your EC2 resource properties. 

{{% notice info %}}
More functions, such as `Fn::Base64`, `Fn::FindInMap`, `Fn::GetAtt` and `Fn::Sub` will be introduced in the feature labs.
You can find full list of supported functions in the
[AWS Documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).
{{% /notice %}}

{{% notice note %}} 
You can use intrinsic functions only in specific parts of a template. Currently, you can use intrinsic functions in 
**resource properties, outputs, metadata attributes, and update policy attributes**.
{{% /notice %}}

**Lets go!**

1. Go to `code/40-cloudformation-features/` directory.
1. Open the `03-lab03-IntrinsicFunctions.yaml` file.
1. Copy the code as you go through the topics bellow.

#### Ref <a id="ref"></a>
The intrinsic function _Ref_ returns the value of the specified _parameter_ or _resource_.

Yaml Syntax:
```
  !Ref
```

In the last lab you have "hard coded" an AMI ID directly into the EC2 Resource property. You will now amend this to make your 
template more flexible. Lets convert AMI ID to variable and pass it to resource property at the runtime.

1. First, create new parameter called `AmiID` and put it in the `Parameters` section of your template.
```yaml
      AmiID:
        Type: String
        Description: The ID of the AMI.
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

1. Use `Ref` function to pass user input to resource property.
```yaml
          ImageId: !Ref AmiID
```

#### Fn::Join <a id="join"></a>
The intrinsic function _Fn::Join_ appends a set of values into a single value, separated by the specified delimiter.

Yaml Syntax:
```
  !Join [ delimiter, [ comma-delimited list of values ] ]
```

It is always good idea to Tag your resources, so lets do it now and use _Fn::Join_ function:

```yaml
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref InstanceType, Web Server ] ]
```

#### Exercise

Now it is a time to update your stack. 

Go to AWS console and update your Cloudformation Stack.

{{%expand "Expand here to see the solution" %}}
![](/40-cloudformation-features/update-1.gif)
{{% /expand %}}
