---
title: "Lab 04: Mapping & Conditionals"
date: 2019-11-01T13:36:34Z
weight: 300
---

## Introduction

This lab will cover Mapping, which allows you to lookup values from a set of predefined keys.

### Motivation
A common use for Mappings is to configure a template according to different environments, such as dev, test and production.

Rather than have 3 similar templates, one for each of dev, test and production, mapping allows you to have one template. Keys and their corresponding values are predefined in a map. These keys can be accessed in other parts of your template.

### Key Components

#### Mapping Section

The [`Mapping`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) section is a top level section of a CloudFormation template. It is used to define maps, their keys and values.



A Mapping Section can contain multiple maps. Each map contains atleast one key
A key in a map has two components, a top level key and a second level key.
Each key contains one or more Name - Value pairs. Each top level key must contain atleast one second level key.


Here is a simplified example of a Mapping section. It contains one Map, `Mapping01`. \
`Mapping01` contains three top level keys, `TopLevelKey01`, `TopLevelKey02` and `TopLevelKey03`. \
Each top level key contains one second level key, `SecondLevelKey`.
```yaml
Mappings: 
  Mapping01: 
    TopLevelKey01: 
      SecondLevelKey: Value01
    TopLevelKey02: 
      SecondLevelKey: Value02
    TopLevelKey03: 
      SecondLevelKey: Value03
```

#### Fn::FindInMap

[`Fn::FindInMap`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html) is an intrinsic function used to lookup the value of a key in a map.

It takes three parameters:
* `MapName`
* `TopLevelKey`
* `SecondLevelKey`

It will return the value of the second level key in that map

## Implementing a simple map

Below is a simple template defining a single EC2 instance. It uses a simple mapping to configure the EC2 instance type according to a parameter, `EnvironmentType`. Next, each part of the template will be discussed individually.


```yaml
Parameters:
  EnvironmentType: 
    Description: "Specify the Environment type of the stack"
    Type: String
    Default: "Dev"
    AllowedValues:
      - "Dev"
      - "Test"
      - "Production"

Mappings:
  EnvironmentToInstanceType: # Map Name
    Dev: # Top level key
      Type: "t3.micro" # Second level key
    Test:
      Type: "t3.nano"
    Production: 
      Type: "t3.small"

Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties: 
      ImageId: "ami-79fd7eee"

      # Use the intrinsic function FindInMap to lookup the 
      # InstanceType value from the EnvironmentToInstanceTypeMap.
      # It references the EnvironmentType parameter provided to the template
      InstanceType: !FindInMap
        - EnvironmentToInstanceType # Map Name
        - !Ref EnvironmentType # Top Level Key
        - "Type" # Second Level Key
```


### Parameters

The parameters section specifies one parameter, `EnvironmentType`
It allows three possible values, `Dev`, `Test` or `Production`.

```yaml
Parameters:
  EnvironmentType: 
    Description: "Specify the Environment type of the stack"
    Type: String
    Default: "Dev"
    AllowedValues:
      - "Dev"
      - "Test"
      - "Production"

# Rest of Template omitted
```


### Mapping

The mapping section defines one map, `EnvironmentToInstanceType`.
The map contains three top level keys, one for each environment.
Each top level key contains a single `Type` second level key.
```yaml
Mappings:
  EnvironmentToInstanceType: # Map Name
    Dev: # Top level key
      Type: "t3.micro" # Second level key
    Test:
      Type: "t3.nano"
    Production: 
      Type: "t3.small"
```

### Resources

The resource section defines one resource, an [EC2 instance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html).
The `InstanceType` property defines the type of EC2 instance.The intrinsic function `Fn::FindInMap` is used to lookup the value in the `EnvironmentToInstanceType` map.
The parameter `EnvironmentType` is passed as the top level key using the intrinsic function `Fn::Ref`.
Finally, the second level key is specified as `Type`
```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties: 
      ImageId: "ami-79fd7eee"

      # Use the intrinsic function FindInMap to lookup the 
      # InstanceType value from the EnvironmentToInstanceTypeMap.
      # It references the EnvironmentType parameter provided to the template
      InstanceType: !FindInMap
        - EnvironmentToInstanceType # Map Name
        - !Ref EnvironmentType # Top Level Key
        - "Type" # Second Level Key
```


This examples demonstrates how mapping is used in a CloudFormation template. It allows the creation of flexible templates.

## Exercise #1 - Simple Map
Now it's your turn! 
In our fictitious scenario, each environment has a seperate ssh key to access it.
Each key has a title of the form `{Environment}-key`. For example, the key for the dev environment is `dev-key`
Add a new property, `KeyName`, that uses a map to determine the key name from the `Environment Parameter`.

A template to get you started is available at `code/40-cloudformation-features/05-lab04-Mapping.yaml`

{{%expand "Need a hint?" %}}
1. Add an `KeyName` property to the `EC2Instance` in the resource section.
2. Try adding a second level key to the existing map to specify the different key names.
3. Reference that key with the `Fn::FindInMap`
{{% /expand%}}

{{%expand "Expand to see the solution" %}}
```yaml
Parameters:
  EnvironmentType: 
    Description: Environment Type
    Type: String
    Default: Dev
    AllowedValues:
      - "Dev"
      - "Test"
      - "Production"

Mappings:
  EnvironmentToInstanceType: # Map Name
    Dev: # Top level key
      Type: "t3.micro" # Second level key
      KeyName: "dev-key"
    Test:
      Type: "t3.nano"
      KeyName: "test-key"
    Production: 
      Type: "t3.small"
      KeyName: "production-key"

Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties: 
      ImageId: "ami-79fd7eee"
      KeyName: !FindInMap
        - EnvironmentToInstanceType
        - !Ref EnvironmentType
        - "KeyName"

      # Use the intrinsic function FindInMap to lookup the 
      # InstanceType value from the EnvironmentToInstanceTypeMap.
      # It references the EnvironmentType parameter provided to the template
      InstanceType: !FindInMap
        - EnvironmentToInstanceType # Map Name
        - !Ref EnvironmentType # Top Level Key
        - "Type" # Second Level Key
```
{{% /expand%}}

## Conclusion

In this lab, we used mappings to create flexible CloudFormation templates. Mapping can be used to configure properties according to other parameters or pseudo parameters. One template can contain many maps, each with multiple top and second level keys

