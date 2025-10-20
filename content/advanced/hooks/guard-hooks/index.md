---
title: "Guard Hooks"
weight: 600
---

### Introduction

AWS CloudFormation Guard Hooks enable you to validate CloudFormation and AWS Cloud Control API operations using AWS CloudFormation Guard rules. Guard is an open-source, general-purpose, domain-specific language (DSL) that you can use to author policy-as-code. When an operation is triggered, your Hook can:

* Evaluate the operation against your defined Guard rules.
* Either block the operation if it doesn't meet requirements
  Or allow it to proceed with a warning message.

These Hooks act as custom validation checkpoints that you can configure to intercept and assess specific CloudFormation operations before they're executed using declarative Guard rules instead of custom code.

You can configure Guard Hooks to intercept and evaluate the following CloudFormation operations:
* Resource operations
* Stack operations
* Change set operations

## In This Lab

We will explore how Guard Hooks can be effectively used for resource-level operations. Consider a common security requirement: as a member of an organization's security team, you need to ensure all S3 buckets deployed through CloudFormation have versioning enabled and public access blocked.

In the example, we will review and create Guard rules required for Guard Hooks, followed by registering and activating the Guard Hook using the created rules. After activation, we'll test the Guard hook functionality with new CloudFormation deployments and explore the steps for validating and troubleshooting Guard Hook invocations.
