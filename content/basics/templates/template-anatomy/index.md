---
title: "Template anatomy"
weight: 100
---

_Lab Duration: ~10 minutes_

---

### Template

**An AWS CloudFormation template** is a declaration of the AWS resources that make up a **stack**.
The template is stored as a text file in either JavaScript Object Notation (JSON) or YAML format.
Because they are just text files, you can create and edit them in any text editor and manage them in your source control
system with the rest of your source code.

:::alert{type="info"}
Throughout this workshop, code samples will use the YAML format. If you prefer to use JSON, please be aware
of [the differences](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-formats.html).
:::

The following example shows an AWS CloudFormation YAML template structure and its top-level objects:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
AWSTemplateFormatVersion: 'version date' (optional) # version of the CloudFormation template. Only accepted value is '2010-09-09'

Description: 'String' (optional) # a text description of the Cloudformation template

Metadata: 'template metadata' (optional) # objects that provide additional information about the template

Parameters: 'set of parameters' (optional) # a set of inputs used to customize the template

Rules: 'set of rules' (optional) # a set of rules to validate the parameters provided at deployment/update

Mappings: 'set of mappings' (optional) # a mapping of keys and associated values

Conditions: 'set of conditions' (optional) # conditions that control whether certain resources are created

Transform: 'set of transforms' (optional) # for serverless applications

Resources: 'set of resources' (required) # a components of your infrastructure

Hooks: 'set of hooks' (optional) # Used for ECS Blue/Green Deployments

Outputs: 'set of outputs' (optional) # values that are returned whenever you view your stack's properties
:::

The only required top-level object is the **Resources** object, which must declare at least one resource.
The definition of each of these objects can be found in the online [Template Anatomy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html) documentation.

### Stack

A stack is a deployment of a CloudFormation template. You can create multiple stacks from a single CloudFormation
template. A stack contains a collection of AWS resources that you can manage as a single unit. All the resources in
a stack are defined by the stack's AWS CloudFormation template.

AWS CloudFormation will create, update or delete a stack in its entirety:

  * If a stack cannot be created or updated in its entirety, AWS CloudFormation will roll it back, and automatically delete any resources that were created.
  * If a resource cannot be deleted, any remaining resources are retained until the stack can be successfully deleted.

![cfn-stack](/static/basics/templates/template-anatomy/cfn-stack.png)
