---
title: " CloudFormation Terminology"
date: 2019-10-25T16:15:53+01:00
weight: 100
---

### CloudFormation Templates

**Familiar format:** A CloudFormation template is simply a JSON (JavaScript Object Notation) or YAML-formatted text file.

**Use over and over:** Using template parameters enable a single template to be used for many infrastructure deployments 
with different configuration values, such as how many instances to deploy for the application.

**No manual steps:** Template describes end state of the infrastructure, without manual steps that can lead to errors.

#### A Template example of the high level YAML Structure:

```yaml
AWSTemplateFormatVersion: "2010-09-09"

Description: "A text description of the template usage"

Parameters: "A set of inputs used to customize the template per deployment"

Resources: "The set of AWS resources and relationships between them"

Outputs: "A set of values to be made visible to the stack creator or to pass them between stacks."
```

### A Stack

+ A stack is a collection of AWS resources that you can manage as a single unit.

+ All the resources in a stack are defined by the stack's AWS CloudFormation template.

+ AWS CloudFormation will create, update or delete a stack in its entirety. 
    + If a stack cannot be created or updated in its entirety, AWS CloudFormation will roll it back, and automatically deletes any resources that were created.
    + If a resource cannot be deleted, any remaining resources are retained until the stack can be successfully deleted. 
  
![](/30-cloudformation-fundamentals/cfn-stack.png)