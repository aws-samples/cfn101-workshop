---
title: "Lab 10: Nested Stacks"
date: 2019-11-13T16:52:42Z
weight: 100
---

## Introduction

## Using Nested Stacks

### `AWS::CloudFormation::Stack` Resource

To reference a CloudFormation in your template, use the `AWS::CloudFormation::Stack` resource.
It looks like this

```bash
Resources:
    NestedStackExample
        Type: AWS::CloudFormation::Stack
        Properties: 
            Parameters: 
                ExampleKey: ExampleValue
            TemplateURL: "Path/To/Template"
```

The `TemplateURL` property is used to reference the CloudFormation template that you wish to nest.
The `Parameters` property allows you to pass parameters to your nested CloudFormation template.

## Making changes to nested stacks

It's possible to change the template of a nested stack. For example, you may edit the properties of a resource in a stack, or add a resource. If you do so, deploy the parent stack to update the child stack.

## Why is it useful?

<!-- TODO convert to prose -->
* Decompose large templates - Avoid resource definition limits
* Reuse common components


## Nesting our stacks

Your CloudFormation template has grown considerably over the course of this workshop. It's time to split it into reusable components.
Three templates have been created for you. 

1. The parent template.  This parent template will contain the other stacks. It has been left empty for you to complete.
2. The EC2 template. This contains the EC2 instance you have defined in your previous CloudFormation template.
3. The VPC template. This contains a simple VPC which the EC2 instance will be placed into.

You will find all three templates in `code/60-setting-up-nested-stack/`

<!-- TODO Write steps for completing main.template -->
## Conclusion

<!-- TODO Write Conclusion -->



