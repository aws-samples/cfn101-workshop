---
title: " CloudFormation Terminology"
date: 2019-10-25T16:15:53+01:00
weight: 100
---

A CloudFormation template contains one or more resources. Alongside resources, a template will commonly contain other sections. Here you will learn about the common sections of a CloudFormation template.

Here are some commonly used sections in a template

### AWSTemplateFormatVersion
AWSTemplateFormatVersion is the version of the CloudFormationTemplate. Currently there is only one accepted value, `2010-09-09`

### Description

The description contains a text description of the Cloudformation template.

### Parameters

Parameters are a set of inputs used to customize the template per deployment

### Resources
Resources are the set of AWS resources, their properties and relationships between them

### Outputs
Outputs are a set of values to be made visible to the stack creator or to pass them between stacks. This is commonly used to provide endpoint URLS, Bucketnames or other information that is useful to access.

--- 
## Stacks

A stack is an deployment of a CloudFormation template. You could create multiple stacks reusing a single CloudFormation template. \
A stack contains a collection of AWS resources that you can manage as a single unit.

+ All the resources in a stack are defined by the stack's AWS CloudFormation template.
+ AWS CloudFormation will create, update or delete a stack in its entirety.
    + If a stack cannot be created or updated in its entirety, AWS CloudFormation will roll it back, and automatically deletes any resources that were created.
    + If a resource cannot be deleted, any remaining resources are retained until the stack can be successfully deleted. 
  
![](/30-cloudformation-fundamentals/cfn-stack.png)