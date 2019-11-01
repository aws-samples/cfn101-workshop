---
title: "Intrinsic Functions"
date: 2019-11-01T13:36:34Z
weight: 200
---
  
AWS CloudFormation provides several built-in functions that help you manage your stacks. 

In this Lab, you will use intrinsic functions to assign values to your EC2 resource properties. 
The following functions will be used in this exercise:

* [Ref](#ref)
* [Fn::Join](#join)
* [Fn::Sub](#sub)
* [Fn::FindInMap](#find-in-map)
* [Fn::GetAtt](#get-att)

{{% notice info %}}
Full list of functions is available at 
[AWS Documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) 
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

In the last lab you have "hard coded" AMI ID directly in EC2 Resource property. We need to fix that to make your 
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

Lets Tag our instance:

```yaml
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref InstanceType, Web Server ] ]
```

#### Fn::Sub <a id="sub"></a>

#### Fn::FindInMap <a id="find-in-map"></a>

#### Fn::GetAtt <a id="get-att"></a>
