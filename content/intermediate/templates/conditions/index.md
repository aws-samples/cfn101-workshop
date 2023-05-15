---
title: "Conditions"
weight: 100
---

_Lab Duration: ~20 minutes_

---

### Overview

When you describe your infrastructure with [AWS CloudFormation](https://aws.amazon.com/cloudformation/), you declare resources and resource properties in your CloudFormation templates. You might have use cases where you want to create resources, or specify resource property values, based on conditions.

As part of best practices, you want to maximize reuse of templates you write for your application's infrastructure across your life cycle environments, such as `test` and `production`. Let’s say you choose to run resources at a reduced capacity in your `test` environment, for cost savings: for example, you choose a `t2.small` [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) [instance type](https://aws.amazon.com/ec2/instance-types/) for your `production` environment, and a `t2.micro` instance type for your `test` environment. Another example: you choose to create a 2 GiB [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (Amazon EBS) [volume](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html) to use with your `production` instance, and a 1 GiB volume to use with your `test` instance. You might also have use cases where you only want to create a resource when a condition is true.

To conditionally create resources, you add the optional [Conditions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html) section to your template. Once you define conditions and relevant criteria, you use your conditions in [Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) and [Outputs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) template sections. For example, you associate a condition to a resource, or to an output you describe in your template, so you can conditionally create the given resource or the given output if your condition is true. To conditionally specify resource property values - such as, for example, the instance type of your EC2 instance - you use [Condition Functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html).

To use conditions in your template, you include statements in following template sections:
* **Parameters**: specify template input parameter(s) you want your conditions to evaluate.
* **Conditions**: define your conditions by using [intrinsic condition functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html).
* **Resource and Outputs**:
    * associate conditions with resources, or outputs, that you want to conditionally create.
    * Use the `Fn::If` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if) to conditionally specify resource property values based on a condition you define.


CloudFormation evaluates all conditions in your template before creating any resources at stack creation or stack update. Resources that are associated with a true condition are only created during stack creation or stack update.

### Topics Covered

By the end of this lab, you will be able to:

* Identify sample use cases for leveraging Condition functions.
* Provision resources based on Condition evaluation.
* Specify resource property values using Condition functions.

Let’s walk through examples of how to use Condition functions!

### Start Lab

#### **Defining Conditions at the resource level**

* Change directory to: `code/workspace/conditions`.
* Open the `condition-resource.yaml` template.
* Update the content of the template as you follow along steps on this lab.

Let’s get started!

Let’s first focus on making your template more reusable. Choose to add a `Parameters` section in your template, with an input parameter for your life cycle environments; call the parameter `EnvType`, and describe two example environment names, `test` and `prod`, as input values you allow. Define an input parameter for the [Amazon Machine Image](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMI) you will use: in this example, you use an example parameter called `LatestAmiId` to refer, in its value, to the latest available Amazon Linux AMI by using [AWS Systems Manager](https://aws.amazon.com/systems-manager/) [Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html).

::alert[For more information, see [Query for the latest Amazon Linux AMI IDs using AWS Systems Manager Parameter Store](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/).]{type="info"}

Copy the content shown below, and paste it in the `condition-resource.yaml` file, by appending it to the existing file content:

```yaml
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

  EnvType:
    Description: Specify the Environment type of the stack.
    Type: String
    AllowedValues:
      - test
      - prod
    Default: test
    ConstraintDescription: Specify either test or prod.
```
Next, describe `IsProduction`, an example condition in the `Conditions` section of your [template.](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html) In this condition, you evaluate if the `EnvType` parameter value equals to `prod`.

Append the following content to the existing file content:

```yaml
Conditions:
  IsProduction: !Equals
    - !Ref EnvType
    - prod
```
Next, associate conditions to resources you want to conditionally provision based on the `IsProduction` condition. In the following example, you associate the `Volume` and `MountPoint` resources with `IsProduction`. Therefore, these resources are created only when the `IsProduction` condition is true: that is, if the `EnvType` parameter value is equal to `prod`. Otherwise, only the EC2 instance resource will be provisioned.

Copy the content below, and paste it in the `condition-resource.yaml` file by appending it to the existing file content:

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro

  MountPoint:
    Type: AWS::EC2::VolumeAttachment
    Properties:
      InstanceId: !Ref EC2Instance
      VolumeId: !Ref Volume
      Device: /dev/sdh
    Condition: IsProduction

  Volume:
    Type: AWS::EC2::Volume
    Properties:
      Size: 2
      AvailabilityZone: !GetAtt EC2Instance.AvailabilityZone
      Encrypted: true
    Condition: IsProduction
```

Let’s deploy the solution!

When you create the stack, you will pass `test` as the value for `EnvType`, and you will observe only an EC2 instance resource will be provisioned by CloudFormation. Save the template you have updated with content above; next, navigate to the AWS CloudFormation [console](https://console.aws.amazon.com/cloudformation), and choose to create a stack using this template:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/conditions`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/conditions
:::
1. Use the AWS CLI to create the stack. The required parameters have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-condition-test \
--template-body file://condition-resource.yaml \
--parameters ParameterKey="EnvType",ParameterValue="test"
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-condition-test/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the CloudFormation console, select **Create stack**, **With new resources (standard)**.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `condition-resource.yaml` template.
1. Enter a **Stack name**. For example, choose to specify `cfn-workshop-condition-test`.
1. Pass `test` as the value for the `EnvType` parameter. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page. Choose **Next**.
1. Choose **Submit**. You can view the progress of the stack being created in the CloudFormation console.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `CREATE_COMPLETE` status.
::::
:::::
Once the stack is in the `CREATE_COMPLETE` status, navigate to the **Resources** tab for your stack: verify the only resource provisioned is your EC2 instance, based on the logic you created driven by the `test` value you passed to the `EnvType` parameter, and to the condition you added and associated to the other two resources in the template:

![condition-test](/static/intermediate/templates/conditions/condition-test.png)

In the next step, you will create a new stack with the same template. This time, you will pass `prod` as the value for the `EnvType` parameter, and verify that you will provision, with CloudFormation, your `Volume` and `MountPoint` resources as well. Navigate to the AWS CloudFormation [console](https://console.aws.amazon.com/cloudformation), and choose to create a stack using your existing template:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/conditions`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/conditions
:::
1. Use the AWS CLI to create the stack. The required parameters have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-condition-prod \
--template-body file://condition-resource.yaml \
--parameters ParameterKey="EnvType",ParameterValue="prod"
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-condition-prod/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the CloudFormation console, select **Create stack**, **With new resources (standard)**.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `condition-resource.yaml` template.
1. Enter a **Stack name**. For example, choose to specify `cfn-workshop-condition-prod`.
1. Pass `prod` as the value for the `EnvType` parameter. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page. Choose **Next**.
1. Choose **Submit**. You can view the progress of the stack being created in the CloudFormation console.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `CREATE_COMPLETE` status.
::::
:::::

This time, the `IsProduction` condition is true. Navigate to the **Resources** tab for your stack, and verify that along with your EC2 instance resource, your other `Volume` and `MountPoint` resources are also provisioned:

![condition-prod](/static/intermediate/templates/conditions/condition-prod.png)

Congratulations! You learned how to conditionally create resources!


#### **Defining Conditions at the property level**

Let’s evaluate an example use case where you conditionally define resource property values. For example, let's say you want to create an EC2 instance of the `t2.micro` type for your `test` environment, and an EC2 instance of type `t2.small` for your `production` environment. You choose to define a condition that you associate at the resource property level for the `InstanceType` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype).

First, you design your condition such as, for example, if you specify `prod` as the input parameter for the `EnvType` parameter, your condition is true. Next, you associate the condition to your EC2 instance, and describe your desired behavior as such: if your condition is true, your instance will use `t2.small` as the instance type, or `t2.micro` otherwise. Let’s take a look at how this works in the example following next.

1. Make sure you are in the following directory: `code/workspace/conditions`.
2. Open the `condition-resource-property.yaml` file.
3. Update the content of the template as you follow along steps on this lab.

Let’s get started! In this example, that is similar to the previous one, you define the `EnvType` parameter and the `IsProduction` condition to create resource based on parameter value you passed. Copy the content shown below, and paste it in the `condition-resource-property.yaml` file, by appending it to the existing file content:

```yaml
Parameters:
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2

  EnvType:
    Description: Specify the Environment type of the stack.
    Type: String
    AllowedValues:
      - test
      - prod
    Default: test
    ConstraintDescription: Specify either test or prod.

Conditions:
  IsProduction: !Equals
    - !Ref EnvType
    - prod
```

Next, let’s wire up the `IsProduction` condition to conditionally specify a property values. In this example, you use the `Fn::if` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#intrinsic-function-reference-conditions-if), in its YAML short form, to evaluate if the `IsProduction` condition is true: if that is the case, the `t2.small` property value will be used for `InstanceType`; otherwise, `t2.micro` will be used if the condition is false. Copy and append the following code to the template:

```yaml
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !If [IsProduction, t2.small, t2.micro]
```

Time to deploy your resources!

In this section, you will pass `test` as the value for the `EnvType` parameter, and verify the type of your EC2 instance will be `t2.micro`. Navigate to the AWS CloudFormation [console](https://console.aws.amazon.com/cloudformation), and choose to create a stack using this template:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/conditions`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/conditions
:::
1. Use the AWS CLI to create the stack. The required parameters have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-condition-property-test \
--template-body file://condition-resource-property.yaml \
--parameters ParameterKey="EnvType",ParameterValue="test"
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-condition-property-test/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the CloudFormation console, select **Create stack**, **With new resources (standard)**.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `condition-resource-property.yaml` template.
1. Enter a **Stack name**. For example, choose to specify `cfn-workshop-condition-property-test`.
1. Pass `test` as the value for the `EnvType` parameter. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page. Choose **Next**.
1. Choose **Submit**. You can view the progress of the stack being created in the CloudFormation console.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `CREATE_COMPLETE` status.
::::
:::::

Once the Stack is in the `CREATE_COMPLETE` status, navigate to the **Resources** tab for your stack, and locate the EC2 instance you created with your stack.

Next, verify the instance type is the one you expect: follow the link for the Physical ID of your instance, to view your instance in the Amazon EC2 Console:
![condition-test-property](/static/intermediate/templates/conditions/condition-test-property.png)

You should see a view, as in the example shown next, showing that your instance type is `t2.micro`:
![ec2-instance](/static/intermediate/templates/conditions/ec2-instance.png)

If you create a new stack with the same template, and specify `prod` as the value for `EnvType`, the type of your instance will be `t2.small` instead.

Congratulations! You have learned how to conditionally specify resource property values!

### **Challenge**

So far, you’ve learned how to use conditions with resources and property values in your CloudFormation templates. In this challenge, you will conditionally create an output in the [Outputs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) section of your `condition-resource.yaml` CloudFormation template.

**Task:** Describe an [Outputs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) section in your `condition-resource.yaml` template. Specify `VolumeId` for the Logical ID of your output, and use the `Ref` intrinsic function to [return the ID of your volume](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values). Your goal, in this challenge, is to create your output only if the `IsProduction` condition is true: how can you reflect this intent in your template? Once ready, update your existing `cfn-workshop-condition-prod` stack with the template you updated, and verify your changes led to creating the output as you expected.

:::expand{header="Need a hint?"}
* See the documentation for [Stack Output](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html#outputs-section-structure-examples), and define a `VolumeId` output in your template.
* Review the documentation on [Conditions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html) and [Associating a condition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#associating-a-condition). How do you conditionally create an output?
:::

::::::expand{header="Want to see the solution?"}
Append the following content to the `condition-resource.yaml` file:

```yaml
Outputs:
  VolumeId:
    Value: !Ref Volume
    Condition: IsProduction
```

Next, navigate to the AWS CloudFormation [console](https://console.aws.amazon.com/cloudformation), and choose to  update your `cfn-workshop-condition-prod` stack:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/conditions`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/conditions
  :::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-condition-prod \
--template-body file://condition-resource.yaml \
--parameters ParameterKey="EnvType",ParameterValue="prod"```
  :::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-condition-prod/739fafa0-e4d7-11ed-a000-12d9009553ff"
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. In the CloudFormation console, select **Update stack**.
1. In **Prepare template**, select **Replace current template**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `condition-resource.yaml` template.
1. `EnvType` should already be set to `prod`. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page. Choose **Next**.
1. Choose **Submit**. You can view the progress of the stack being created in the CloudFormation console.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the
  `UPDATE_COMPLETE` status.
::::
:::::

Navigate to the `Outputs` section of your stack, and validate the `VolumeId` output is present.
![condition-prod-update](/static/intermediate/templates/conditions/condition-prod-update.png)
::::::

The full solution is also available in the `code/solutions/conditions/condition-output.yaml` template file.

### Cleanup

Follow steps shown next to clean up resources you created in this lab:

* In the CloudFormation console, choose the `cfn-workshop-condition-test` stack you created in this lab.
* Choose **Delete** to delete the stack you created in this lab, and then choose **Delete stack** to confirm.


Perform the same cleanup steps above for your other stacks you created in this lab: `cfn-workshop-condition-prod`, and `cfn-workshop-condition-property-test`.

---
### Conclusion

Congratulations! You have learned how to conditionally create resources, and how to conditionally specify resource property values. For more information, see [Conditions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html) and [Condition functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html).
