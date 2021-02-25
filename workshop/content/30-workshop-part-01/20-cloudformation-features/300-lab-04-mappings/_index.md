---
title: 'Lab 04: Mapping'
date: 2019-11-01T13:36:34Z
weight: 300
---

### Overview

This lab will introduce **[Mappings](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html)**. A _Mappings_ section is a top level section of a CloudFormation template. It is used to define maps, their keys and values which can be then referenced in your template.

![A diagram of the structure of a mappings section](300-lab-04-mappings/mapping.png)

Here is a simplified example of a Mappings section. It contains one Map, `AnExampleMapping`. \
`AnExampleMapping` contains three top level keys, `TopLevelKey01`, `TopLevelKey02` and `TopLevelKey03`. \
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

### Topics Covered
In this Lab, you will:

+ Create a mapping for environment type such as _Test_ or _Prod_. Each environment type will be mapped to different instance type.
+ Find the required value in mappings and reference it in properties section of the EC2 resource.

### Start Lab

You will now add a `Mappings` section to your own template.

{{% notice info %}}
The templates for this lab can be found in `code/20-cloudformation-features`\
The starting template is `05-lab04-Mapping.yaml` \
The final template is `06-lab04-Mapping-Solution.yaml`
{{% /notice %}}

#### 1. Let's start with creating _EnvironmentType_ parameter

This section will define two possible environments, `Test` and `Prod`. It will use a new parameter, `EnvironmentType`.

In the _Parameters_ section of the template. Replace the `InstanceType` parameter with the code below (you will not need the `InstanceType `parameter anymore. You will use the mapping instead).

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
Don't forget to remove `InstanceType` from the _ParameterGroups_ and _ParameterLabels_ sections of the template.
{{% /notice %}}

#### 2. Next, create _EnvironmentToInstanceType_ in the mapping section

The map contains two top level keys, one for each environment. Each top level key contains a single `InstanceType` second level key.

```yaml
Mappings:
  EnvironmentToInstanceType: # Map Name
    Test: # Top level key
      InstanceType: t2.micro # Second level key
    Prod:
      InstanceType: t2.small
```

#### 3. Next, modify the _InstanceType_ property

Using the intrinsic function `Fn::FindInMap`, CloudFormation will lookup the value in the `EnvironmentToInstanceType` map and will return the value back to `InstanceType` property.

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

#### 4. Next, update the _Tags_ property

As you have deleted the `InstanceType` parameter, you will need to update the tag. Reference `EnviromentType` in the tag property.

```yaml
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

#### 5. Finally, Deploy the solution

Now that you have added a Mappings section to your template, go to the AWS console and update your CloudFormation Stack.

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-ec2**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `05-lab04-Mapping.yaml` and click **Next**.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** select the environment from drop down list, for example **Test** and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Update stack**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.

### Challenge

Add another Environment, `Dev`, to your template. It will need to contain `Dev` key name, and name-value pair `InstanceType: t2.nano`.

Don't forget to add `Dev` to the list of allowed values for the `EnvironmentType` parameter.

{{%expand "Need a hint?" %}}
  1. In a _Parameters_ section
    * Add `Dev` to the `EnvironmentType` AllowedValues list.
  1. In a `Mappings` section.
    * Add a top level key of `Dev`.
    * Add a name-value pair `InstanceType: t2.nano`.
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
      InstanceType: t2.nano
    Test: # Top level key
      InstanceType: t2.micro # Second level key
    Prod:
      InstanceType: t2.small
```

See `code/20-cloudformation-features/06-lab04-Mapping-Solution.yaml` for the full solution.

{{% /expand%}}

To test that your solution works, update the stack as you did in step [5. Finally, Deploy the solution](#5-finally-deploy-the-solution) and change the `EnvironmentType` to **Dev**.

{{% notice note %}}
Changing the instance type will cause some downtime as EC2 instance has to be stopped before changing the type.
{{% /notice %}}

---
### Conclusion

Great work! You have now successfully learned how to use mappings to create more flexible CloudFormation templates.
