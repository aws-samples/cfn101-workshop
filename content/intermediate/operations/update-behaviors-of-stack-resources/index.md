---
title: "Update behaviors of stack resources"
weight: 100
---

### Overview
In this lab, you will learn important aspects of how to design and address updates of your infrastructure. As your applications and environments evolve, you apply updates to resource configurations described in your templates.

CloudFormation updates resources by comparing changes between the updated template you provide, and resource configurations you described in the previous version of your template. Resource configurations that haven't changed remain unaffected during the update process; otherwise, CloudFormation uses one of the following [update behaviors](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html): **Update with No Interruption**, **Updates with Some Interruption**, and **Replacement**, depending on which new property you add, or on which property value you modify, for a given [resource type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) you describe in your template.

### Topics Covered
By the end of this lab, you will be able to:

* Learn update behaviors of stack resources.
* Learn important considerations of how update behaviors affect your provisioned stack resources.

**Start Lab**
* Change directory to: `code/workspace/update-behaviors-of-stack-resources`.
* Open the `update-behaviors-of-stack-resources.yaml` file with your favorite text editor.
* Copy and append content to the file, as you go through the lab.

Let’s get started with describing an [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instance in your template. Copy and append the `Parameters` section shown next to the `update-behaviors-of-stack-resources.yaml` template:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=5}
Parameters:
  InstanceType:
    Description: WebServer EC2 instance type
    Type: String
    Default: t2.micro
    AllowedValues: [t2.micro, t2.small, t2.medium]
    ConstraintDescription: must be a valid EC2 instance type.

  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
:::

Next, copy and append the following `Resources` section and the Amazon EC2 instance definition to your template:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=17}
Resources:
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: !Ref LatestAmiId
      Tags:
        - Key: Name
          Value: cfn-workshop
:::

Save your changes to the file. Next, create your stack with the `update-behaviors-of-stack-resources.yaml` template:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/update-behaviors-of-stack-resources`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd code/workspace/update-behaviors-of-stack-resources
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-update-behaviors-of-stack-resources --template-body file://update-behaviors-of-stack-resources.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-update-behaviors-of-stack-resources/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. [Choose a Region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) you wish to use.
1. From **Create stack**, choose **With new resources (standard)**.
1. In **Prepare template**, choose **Template is ready**.
1. From **Template source**, choose **Upload a template file**. Choose the `update-behaviors-of-stack-resources.yaml` template mentioned earlier, and then choose **Next**.
1. Specify a stack name: for example, `cfn-workshop-update-behaviors-of-stack-resources`. On the same page, accept default values for `InstanceType` and `LatestAmiId` parameters, and choose **Next**.
1. Choose to accept default values in the **Configure stack options** page. Choose **Next**.
1. On the **Review** page, scroll down to the bottom, and choose **Submit**.
1. Wait until the stack creation is complete. Refresh the view in the console until you see your stack to be in the `CREATE_COMPLETE` status.
::::
:::::

**Replacement**

So far, you've created an Amazon EC2 instance with your stack. For your instance's [Amazon Machine Image](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMI), you used the latest `x86-64` Amazon Linux 2 AMI in this lab. Let's now consider a scenario where you have a requirement to use a different AMI for your Amazon EC2 instance. In this lab, you choose to update the CloudFormation stack you created earlier, `cfn-workshop-update-behaviors-of-stack-resources`, and override the parameter value for `LatestAmiId` with `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs`.

::alert[When you change a property value for a resource, always look at the value for [Update requires](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-imageid) for the given resource property in the documentation. In this case, updating the value for the `ImageId` property results in a resource [replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) behavior.]{type="info"}

Now it’s time to update your stack! Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and update your `cfn-workshop-update-behaviors-of-stack-resources` stack as shown next:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure to choose the [region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) where you’ve created the stack: `cfn-workshop-update-behaviors-of-stack-resources`.
1. Choose the stack you created earlier, for example `cfn-workshop-update-behaviors-of-stack-resources`.
1. Choose **Update**.
1. In **Prepare template**, choose **Use current template,** and then choose **Next**.
1. On the **Parameters** page, accept the default value for `InstanceType`, and replace the existing value for the `LatestAmiId` parameter with this new value: `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs`. When ready, choose **Next**.
1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
1. On the **Review** page, scroll down to the bottom, and choose **Update stack**.

While your stack is updating, navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/), and choose **Instances**. You will notice a new instance will be launched, and the instance you created earlier in this lab will be terminated. When you updated the stack with the AMI change you made above, CloudFormation created your new instance first, and deleted the previous one: this example illustrates the **Replacement** behavior.

Congratulations! You have learned the **Replacement** behavior.

**Updates with Some Interruption**
Let’s go over an example where your workload requirements change, and you determine that you need a new [Amazon EC2 instance type](https://aws.amazon.com/ec2/instance-types/) for your CPU and memory requirements. For this, you choose to change the type for the instance, that you manage with your `cfn-workshop-update-behaviors-of-stack-resources` stack, from `t2.micro` to `t2.small` for example.

:::alert{type="info"}
As you’re changing the `InstanceType` property value for your instance, you first want to look at the behavior described in [Update requires](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-instancetype) for the property, to understand what will happen when you update the stack.
:::

Let’s go ahead and update the stack:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you choose the [region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) where you’ve created the stack: `cfn-workshop-update-behaviors-of-stack-resources`.
1. Choose the stack you created earlier, for example `cfn-workshop-update-behaviors-of-stack-resources`.
1. Choose **Update**.
1. In **Prepare template**, choose **Use current template** and choose **Next**.
1. On the next page, accept the default value for the `LatestAmiId` parameter, and choose `t2.small` for the `InstanceType` parameter value. Choose **Next**.
1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
1. On the **Review** page, scroll down to the bottom and choose **Update stack**.

While your stack is updating, navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/), and choose **Instances**. Note that your instance will be first stopped - thus, it will be temporarily not available - and, once the instance type changes to `t2.small`, it will then enter the running status shortly. This example illustrates the **Updates with Some Interruption** behavior.

Congratulations! You have learned the **Updates with Some Interruption** behavior.

**Update with No Interruption**

Let’s continue the previous example: your instance is currently using [basic monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch-new.html), where instance metric data is sent to [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/) in 5-minute periods. Let’s say that you require metric data to be available on 1-minute periods for your workload, and you choose to enable [detailed monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch-new.html) for your instance.

You then choose to add the `Monitoring` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-monitoring), set to `true`, for the instance you described in your `update-behaviors-of-stack-resources.yaml` template.

::alert[As you’re adding this new property, look at the value for [Update requires](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-monitoring) for `Monitoring`, to learn what will happen when you update the stack.]{type="info"}

Update your existing `update-behaviors-of-stack-resources.yaml` template, and specify the `Monitoring` property in the definition for `EC2Instance` as shown next:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=17 highlightLines=22}
EC2Instance:
  Type: AWS::EC2::Instance
  Properties:
    InstanceType: !Ref InstanceType
    ImageId: !Ref LatestAmiId
    Monitoring: true
    Tags:
      - Key: Name
        Value: cfn-workshop
:::

Save your changes to the file. Next, update your stack:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/update-behaviors-of-stack-resources`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd code/workspace/update-behaviors-of-stack-resources
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name update-behaviors-of-stack-resources --template-body file://update-behaviors-of-stack-resources.yaml
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/drift-detection-workshop/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. Make sure you choose the [region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) where you’ve created the `cfn-workshop-update-behaviors-of-stack-resources` stack.
3. Choose the stack you created earlier, for example `cfn-workshop-update-behaviors-of-stack-resources`.
4. Choose **Update**.
5. In **Prepare template**, choose **Replace current template**, and then choose the `update-behaviors-of-stack-resources.yaml` template file for **Upload a template file** in the **Specify template** section. When ready, choose **Next**.
6. On the parameters page, accept the default value for `LatestAmiId`  and `InstanceType` parameters, and choose **Next**.
7. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
8. On the **Review** page, scroll down to the bottom and choose **Update stack**.
::::
:::::

Navigate to the [Amazon EC2 Console](https://console.aws.amazon.com/ec2/), and choose **Instances**. While the stack is updating, note that your instance will stay in the running status. This illustrates the **Update with No Interruption** behavior.

Congratulations! You have learned the **Update with No Interruption** behavior.

### Challenge
You are tasked with updating the `Value` of the `Name` tag key for `EC2Instance` in the template you used in this lab. Choose to describe this information in the `Tags` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-tags) for your instance. In the `update-behaviors-of-stack-resources.yaml` template, choose to specify `cfn-workshop-new-value` for the `Name` tag's `Value`. Can you tell which of the three update behaviors will apply when you update the stack?

:::expand{header="Need a hint?"}
Where, in the CloudFormation documentation for a given resource type (in this case, for the `AWS::EC2::Instance` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html)), can you learn about the update behavior for a given resource property?
:::
::::::expand{header="Want to see the solution?"}
Update the `Value` of the `Name` tag key in your template, as shown next:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=17 highlightLines=25}
EC2Instance:
  Type: AWS::EC2::Instance
  Properties:
    InstanceType: !Ref InstanceType
    ImageId: !Ref LatestAmiId
    Monitoring: true
    Tags:
      - Key: Name
        Value: cfn-workshop-new-value
:::

Save your changes to the `update-behaviors-of-stack-resources.yaml` template. Before you update the stack with your updated template, see the **Update requires** [section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-tags) for the `Tags` property; you will notice that **Update requires**, in this case, requires [No interruption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-no-interrupt).

Update your stack:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/update-behaviors-of-stack-resources`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd code/workspace/update-behaviors-of-stack-resources
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name` and `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name update-behaviors-of-stack-resources --template-body file://update-behaviors-of-stack-resources.yaml
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/drift-detection-workshop/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you choose the [region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html) where you’ve created the `cfn-workshop-update-behaviors-of-stack-resources` stack.
1. Choose the stack you created earlier, for example `cfn-workshop-update-behaviors-of-stack-resources`.
1. Choose **Update**.
1. In **Prepare template**, choose **Replace** **current template**, and then choose the `update-behaviors-of-stack-resources.yaml` template mentioned earlier. When ready, choose **Next**.
1. On the next page, choose to accept default values for `LatestAmiId`  and `InstanceType` parameters, and choose **Next**.
1. Choose to accept default values in the **Configure stack options** page, and choose **Next**.
1. On the **Review** page, scroll down to the bottom and choose **Update stack**.
::::
:::::
::::::

### Cleanup
Follow steps shown next to clean up resources you created in this lab:

* In the CloudFormation console, choose the `cfn-workshop-update-behaviors-of-stack-resources` stack you created in this lab.
* Choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.

---

### Conclusion
Congratulations! You have now learned the update behaviors of stack resources!
