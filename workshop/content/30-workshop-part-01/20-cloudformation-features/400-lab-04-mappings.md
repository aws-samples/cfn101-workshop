---
title: 'Lab 04: Mapping'
date: 2019-11-01T13:36:34Z
weight: 400
---

## Introduction

This lab will introduce `Mappings`. 
A `Mappings` section contains predefined keys and values. You can reference these in your template.


## The Mapping Section

The [`Mappings`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) section is a top level section of a CloudFormation template. It is used to define maps, their keys and values.


![A diagram of the structure of a mappings section](../mapping.png)

Here is a simplified example of a Mappings section. It contains one Map, `AnExampleMapping`. \
`AnExampleMapping` contains three top level keys, `Key01`, `Key02` and `Key03`. \
Each top level key contains one or more `Key: Value` pairs.

```yaml
Mappings: 
  AnExampleMap: 
    TopLevelKey01: 
      Key01: Value01
      Key02: Value02

    TopLevelKey02: 
      AnotherKey: AnExampleValue

    TopLevelKey03: 
      AFinalKey: ADifferentValue
```


## Implementing a simple map

You will now add a `Mappings` section to your own template. 

{{% notice info %}}
The templates for this lab can be found in `code/40-cloudformation-features`\
The starting template is `05-lab04-Mapping.yaml` \
The final template is `05-lab04-Mapping-Solution.yaml`
{{% /notice %}}

This section will define two possible environments, `test` and `prod`. It will use a new parameter, `EnvironmentType`.

You will use this mapping to configure the `InstanceType` property of the `AWS::EC2::Resource` according to the environment specified.

### 1. Let's start with creating _EnvironmentType_ parameter 
  In the _Parameters_ section of the template. Replace the `InstanceType` parameter with the code below 
  (you will not need the `InstanceType `parameter anymore. You will use the mapping instead).

```yaml
Parameters:
  EnvironmentType:
    Description: 'Specify the Environment type of the stack.'
    Type: String
    Default: Test
    AllowedValues:
      - Test
      - Prod
    ConstraintDescription: 'Specify either Test or Prod.'
```
{{% notice note %}}
Dont forget to remove `InstanceType` from the _ParameterGroups_ and _ParameterLabels_ sections of the template.
{{% /notice %}}

### 2. Next, create _EnvironmentToInstanceType_ in the mapping section 
  The map contains two top level keys, one for each environment. Each top level key contains a single
  `InstanceType` second level key.
```yaml
Mappings:
  EnvironmentToInstanceType: # Map Name
    Test: # Top level key
      InstanceType: t3.micro # Second level key
    Prod:
      InstanceType: t3.small
```

### 3. Next, modify the _InstanceType_ property  
  Using the intrinsic function `Fn::FindInMap`, CloudFormation will lookup the value in the `EnvironmentToInstanceType` 
  map and will return the value back to `InstanceType` property. 
```yaml
Resources:
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties: 
      ImageId: !Ref AmiID
      InstanceType: !FindInMap
        - EnvironmentToInstanceType # Map Name
        - !Ref EnvironmentType # Top Level Key
        - InstanceType # Second Level Key
```

### 4. Finally, update the _Tags_ property
  As you have deleted the `InstanceType` parameter, you will need to update the tag. Reference `EnviromentType` in the tag property.
  ```yaml
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref EnvironmentType, Web Server ] ]
```

## Optional Challenge

Add another Environment, `dev`, to your template. It will need to contain `dev` key name, and name-value 
pair `InstanceType: t3.nano`. 

Don't forget to add `dev` to the list of allowed values for the `EnvironmentType` parameter.

{{%expand "Need a hint?" %}}
  1. In a _Parameters_ section
    * Add `Dev` to the `EnvironmentType` AllowedValues list.
  1. In a `Mappings` section. 
    * Add a top level key of `Dev`.
    * Add a name-value pair `InstanceType: t3.nano`.
{{% /expand%}}

{{%expand "Expand to see the solution" %}}
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

Mappings:
  EnvironmentToInstanceType: # Map Name
    Dev:
      InstanceType: t3.nano
    Test: # Top level key
      InstanceType: t3.micro # Second level key
    Prod:
      InstanceType: t3.small
```

See `code/05/lab04-Mapping-Solution.yaml` for the full solution.
{{% /expand%}}

## Deploy the solution

Now that you have added a Mappings section to your template, deploy it again using the console.

## Conclusion

In this lab, you used mappings to create flexible CloudFormation templates. 
You can use Mappings to configure properties 
according to other parameters or pseudo parameters.