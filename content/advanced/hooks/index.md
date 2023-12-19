---
title: "Hooks"
weight: 400
---

### Introduction

This part of the workshop focuses on how you can extend creation, provisioning, and management capabilities of [AWS CloudFormation](https://aws.amazon.com/cloudformation/) with proactive compliance validation controls you develop.

[AWS CloudFormation Hooks](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/what-is-cloudformation-hooks.html) is a feature that allows you to create proactive controls (or to reuse existing ones) to validate that your CloudFormation resources are compliant with your company's best practices. For example, you could create a proactive validation control to check that an [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) bucket, whose desired state you describe in CloudFormation template(s), is set up by your users to have [versioning configuration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-versioningconfiguration) enabled, or if [server-side encryption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-bucketencryption) is enabled for S3 buckets you create, with CloudFormation, with an [encryption algorithm](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-serversideencryptionbydefault.html#cfn-s3-bucket-serversideencryptionbydefault-ssealgorithm) you choose from the ones that are available. Those are just two examples and, as you can imagine, there can be many others.

With the examples above using an S3 bucket, when you model your hook you choose to target the `AWS::S3::Bucket` resource type. When you then create or update a stack with a template that describes an S3 bucket, your hook gets invoked before CloudFormation attempts to create or update the bucket. When invoked, your hook validates that -for example- the versioning property for your bucket is set to the `Enabled` `Status`. If you were to have 2 S3 buckets in your template, each bucket would cause an instance of the hook getting invoked (in this example, you'll have 2 hook invocations, one for each bucket).

A hook can encompass one or more resource type target for a given invocation point (such as, pre-create, pre-update, and pre-delete -
 that is, before you create, update, or delete a CloudFormation stack).

There are two discrete workflows for hooks, each one for a specific user persona/team of a given company:

- the security team, that establishes which proactive controls to enable, and
- the application team(s), that describe the infrastructure for their applications, or for their workloads, with CloudFormation.

In this lab, you'll start with the first workflow to build and test a sample hook, and then you'll create a stack to verify your hook works as you'd expect as part of the second workflow above.

The Software Development Life Cycle (SDLC) process of a hook, that is part of the first workflow, can be described as follows:

- install prerequisite tools you will use for development and testing of your hook;
- develop and run tests for your hook;
- when ready, submit the hook to the [AWS CloudFormation registry](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry.html) as a private extension for a given AWS account and region;
- manage the configuration of your hook: you describe the behavior of the hook (for example, whether to invoke the hook for stacks in your account in a given region, whether compliance validation errors yield to denying the provisioning of the non-compliant resource, or simply to a warning);
- if your hook needs user input configuration (that is, if the author of the hook has designed configuration values to be user-configurable), you'd configure the hook according to your needs.

::alert[You have the choice to register your hook as a private or as a public extension in the CloudFormation registry: this lab covers private extension examples.]{type="info"}

When you submit a private extension (such as a module, a resource type, or a hook), you make it available in the CloudFormation registry in your AWS account for a given AWS region: private extensions give you the ability to test the behavior of your resource type in a sandbox environment, such as in an AWS account you own, and that you use for testing/experimentation. Another use case for having a private extension is for validation logic that is company-specific or proprietary.

For more information on private extensions, see [Using private extensions in CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry-register.html). For more information on public extensions, see [Publishing extensions to make them available for public use](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/publish-extension.html).

::alert[Please refer to [AWS CloudFormation pricing](https://aws.amazon.com/cloudformation/pricing/) for information on charges to your account when you use hooks.]{type="info"}


### Key concepts

Key concepts for developing a hook include:

* [model](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/hooks-model.html): a document where you describe which resource type (or types) you wish to trigger a hook invocation, and at which lifecycle phase (pre-create, pre-update, or pre-delete). Moreover, if you plan to make AWS API calls from your hook to make additional validation checks, you can also specify the relevant permissions you need in the model;
* [handlers](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/hooks-model.html#model-hook-project-add-handler): the invocation points for your hook: at least one of `preCreate`, `preUpdate`, or `preDelete` is required.
