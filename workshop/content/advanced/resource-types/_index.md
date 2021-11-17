---
title: 'Resource Types'
date: 2021-11-16T16:51:46Z
weight: 300
---

### Introduction

This part of the workshop focuses on how you can extend creation, provisioning, and management capabilities of [AWS CloudFormation](https://aws.amazon.com/cloudformation/) with resource types you develop.

A resource type you create is treated as a first-class citizen within CloudFormation: you can manage your resource as you would manage any AWS resource.

The Software Development Life Cycle (SDLC) process of a resource type can be summarized as follows:

* first, you install prerequisite tools you will use for development and testing of your resource type;
* you then start to develop and run tests for your resource type;
* when ready, you submit the resource type to the [AWS CloudFormation registry](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry.html);
* manage your resource type with CloudFormation: you describe the resource type and its properties in your CloudFormation template(s), like you would do with any AWS resource type.

{{% notice note %}}
You have the choice to register your resource type as a private or as a public extension in the CloudFormation registry: this lab covers private extension examples.
{{% /notice %}}

When you submit a private extension, you make it available in the AWS CloudFormation registry in your AWS account: private extensions give you the ability to test the behavior of your resource type in a sandbox environment, such as in an AWS account you own and that you use for testing/experimentation. Another use case for private extensions is for codifying private or custom application components that would be used within an enterprise, but might be company-specific, or contain proprietary logic.

You can choose to deploy your resource type in other [AWS regions using AWS CloudFormation StackSets](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/publish-extension-stacksets.html) as needed.

For more information on private extensions, see [Using private extensions in CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry-register.html). For more information on public extensions, see [Publishing extensions to make them available for public use](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/publish-extension.html).
