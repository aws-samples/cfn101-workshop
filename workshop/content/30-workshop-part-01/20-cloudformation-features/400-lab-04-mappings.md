---
title: 'Lab 04: Mapping'
date: 2019-11-01T13:36:34Z
weight: 400
---

## Introduction

This lab will cover Mappings, which allow you to lookup values from a set of predefined keys.

A common use for Mappings is to configure a template according to different environments, such as dev, test and production.
  Mapping allows you to have one template, rather than 3 similar templates. 
 
 Keys and their corresponding values are predefined in the `Mappings` section. The value of these keys are referenced in other parts of your CloudFormation template.

### Key Components

#### Mapping Section

The [`Mappings`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) section is a top level section of a CloudFormation template. It is used to define maps, their keys and values.


A Mappings Section contains one or more maps. Each map contains at least one key. \
Each key is another map! It contains one or more keys that map to values.
Each key contains one or more Name - Value pairs. Each top level key  contains one or more second level keys.


Here is a simplified example of a Mappings section. It contains one Map, `AnExampleMapping`. \
`AnExampleMapping` contains three top level keys, `Key01`, `Key02` and `Key03`. \
Each top level key contains one or more `Name`:`Value` pairs.

```yaml
Mappings: 
  AnExampleMapping: 
    Key01: 
      Name: Value01
      AnotherName: Value02
    Key02: 
      Name: Value02
    Key03: 
      Name: Value03
```


### Implementing a simple map

##### 1. Let's start with creating _EnvironmentType_ parameter 
  In the _Parameters_ section of the template. Replace the `InstanceType` parameter with the code below 
  (you will not need the InstanceType parameter anymore as you will use a mapping instead).

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

##### 2. Next, create _EnvironmentToInstanceType_ in the mapping section 
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

##### 3. Next, modify the _InstanceType_ property  
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

##### 4. Finally, update the _Tags_ property
  As you have deleted the `InstanceType` parameter, you will need to update the tag. Reference `EnviromentType` in the tag property.
  ```yaml
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref EnvironmentType, Web Server ] ]
```

## Exercise - Add `Dev` environment
Now it's your turn.
Let's add another Environment `Dev` to your template. It will need to contain `Dev` key name, and name-value 
pair `InstanceType: t3.nano`. Also, don't forget to add `Dev` to the `EnvironmentType` parameter.

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

See `code/40-cloudformation-features/05-lab04-Mapping-Solution.yaml` for the full solution.
{{% /expand%}}

### Deploy the solution

Now that you have added a Mappings section to your template, deploy it again using the console.

## Conclusion

In this lab, you used mappings to create flexible CloudFormation templates. Use Mappings to configure properties 
according to other parameters or pseudo parameters. A template can contain many maps, each with multiple top and 
second level keys. A Common use for a Mappings section is to provide different configurations depending on an 
environment type.

