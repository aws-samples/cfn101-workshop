---
title: 'CloudFormation Terminology'
date: 2019-10-25T16:15:53+01:00
weight: 100
---

A JSON or YAML file used by CloudFormation to model your infrastructure is called a **CloudFormation template**.

When you deploy a CloudFormation template to your account, the resulting collection of resources and configuration is called a **CloudFormation stack**.

Here are the most commonly-used elements of a CloudFormation template:

### AWSTemplateFormatVersion

`AWSTemplateFormatVersion` is the version of the CloudFormation template language that you are using. Currently, there is only one accepted value: `2010-09-09`. You should include this section in your templates to avoid uncertainty as and when AWS releases a new version of the CloudFormation template language.

### Description

The description contains a text description of the Cloudformation template. This will be visible in your AWS account once you have deployed your infrastructure.

### Parameters

Parameters are a set of inputs used to customize the template per deployment.

### Resources

Resources are the components of your infrastructure. A Resource encapsulates the properties and relationships to other Resources.

### Outputs

Outputs are a set of values that are visible in your AWS account once you have deployed your infrastructure and can be used to pass values between CloudFormation stacks.

Outputs are also commonly used to collect useful information after a CloudFormation stack has been deploy, for example S3 Bucket names and endpoint URLs for deployed resources.

--- 

## Stacks

A stack is a deployment of a CloudFormation template. You can create multiple stacks from a single CloudFormation template.

A stack contains a collection of AWS resources that you can manage as a single unit.

+ All the resources in a stack are defined by the stack's AWS CloudFormation template.

* AWS CloudFormation will create, update or delete a stack in its entirety.

    * If a stack cannot be created or updated in its entirety, AWS CloudFormation will roll it back, and automatically delete any resources that were created.

    * If a resource cannot be deleted, any remaining resources are retained until the stack can be successfully deleted.

![cfn-stack](../cfn-stack.png)
