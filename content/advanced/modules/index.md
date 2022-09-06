---
title: "Modules"
weight: 300
---

### Introduction

This part of the workshop focuses on how you can extend the creation, provisioning, and management capabilities of [AWS CloudFormation](https://aws.amazon.com/cloudformation/) with modules you develop.

In this workshop so far you have seen how to use CloudFormation to build applications using the resource types published by AWS. In this lab you will leverage [AWS CloudFormation Modules](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/modules.html) to create reusable template snippets that can be used many times by other users in the same AWS Account and Region.

A common use case for CloudFormation Modules is for codifying best practice or common configuration components that would be used within an enterprise, but might be company-specific, or contain proprietary logic.

A module is a first-class object in CloudFormation: you can manage your module as you would manage any AWS resource with CloudFormation. The Software Development Life Cycle (SDLC) process of a module can be summarized as follows:

1. Install prerequisite tools you will use for development and testing of your module;
2. Start to develop your module;
3. When ready, submit the module to the [AWS CloudFormation registry](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry.html);
4. Manage your module with CloudFormation: you describe the module and its properties in your CloudFormation template(s), like you would do with any AWS resource type.

::alert[You have the choice to register your module as a private or as a public extension in the CloudFormation registry: this lab covers private extension examples.]{type="info"}

When you submit a private extension, you make it available in the AWS CloudFormation registry in your AWS account. Private extensions give you the ability to test the behavior of your resource type in a sandbox environment, such as in an AWS account you own and that you use for testing/experimentation.

You can choose to deploy your module in other [AWS regions using AWS CloudFormation StackSets](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/publish-extension-stacksets.html) as needed.

For more information on private extensions, see [Using private extensions in CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry-register.html). For more information on public extensions, see [Publishing extensions to make them available for public use](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/publish-extension.html).

::alert[There is no additional charge for using modules. You pay only for the resources those modules resolve to in your stacks.]{type="info"}

::alert[CloudFormation quotas, such as the maximum number of resources allowed in a stack, or the maximum size of the template body, apply to the processed template whether the resources included in that template come from modules or not.]{type="info"}

### Module structure

A module consists of two main pieces:

* A [template fragment](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/modules-structure.html#modules-template-fragment), which defines the resources and associated information you want to provision through use of the module, including any module parameters you define.
* A [module schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/modules-structure.html#modules-schema) that you generate based on the template fragment. The module schema declares the contract you defined in the template fragment, and is viewable to users in the CloudFormation registry.
