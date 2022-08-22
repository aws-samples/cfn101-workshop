---
title: "Consume the Example Module"
weight: 330
---

#### Using the Sample Module

You have just created and registered a new CloudFormation Module with the private registry in your AWS account and for a given AWS Region. This means that your module can now be used in CloudFormation template(s) you will leverage to create/update stack(s) in the same AWS Account and Region.

Let's see how you can consume it.

Create a new YAML file:

:::code{language=shell showLineNumbers=false showCopyAction=true}
touch use-module.yaml
:::

Open this file in your chosen text editor and paste the following CloudFormation YAML:

<!-- vale off -->
:::code{language=yaml showLineNumbers=false showCopyAction=true}
AWSTemplateFormatVersion: 2010-09-09

Resources:

  Vpc:
    Type: CFNWORKSHOP::EC2::VPC::MODULE
    Properties:
      VpcCidr: 10.1.0.0/16
      NameTag: Sample
:::
<!-- vale on -->

That's it. Nice and short isn't it? You can see why Modules are going to be so useful.

Let's create a new stack from that template using the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deploy --template-file use-module.yaml --stack-name cfn-workshop-modules
:::

### Taking a closer look

Now that the Stack is deployed let's take a closer look at what actually happened. It will help to understand more on how Modules work in CloudFormation.

Open the AWS Console and navigate to the CloudFormation service. Locate the stack that you just created and select the `Resources` tab.
Notice that the Stack is showing it has 23 resources.

![stack-resources](/static/advanced/modules/StackResources.png)

This number of resources can be explained if we take a look at the processed template for this stack. You can see that the actual template that CloudFormation deploys is based upon the content of the Module.
When a Module is consumed in a CloudFormation template the Module resource is replaced with the resources defined for it in the Module template.

![stack-template](/static/advanced/modules/StackTemplate.png)
