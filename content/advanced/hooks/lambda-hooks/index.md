---
title: "Lambda Hooks"
weight: 500
---

### Introduction

AWS CloudFormation Lambda Hooks enable you to validate CloudFormation and AWS Cloud Control API operations using your custom code logic. When an operation is triggered, your Hook can:

* Evaluate the operation against your defined criteria.
* Either block the operation if it doesn't meet requirements
  Or allow it to proceed with a warning message.

These Hooks act as custom validation checkpoints that you can configure to intercept and assess specific CloudFormation operations before they're executed.

You can configure Lambda Hooks to intercept and evaluate the following CloudFormation operations:
* Resource operations
* Stack operations
* Change set operations

## In This Lab

We will explore how Lambda Hooks can be effectively used for resource-level operations. Consider a common security requirement: as a member of an organization's security team, you need to ensure all DynamoDB tables deployed through CloudFormation have encryption enabled.

In the example, we will review and deploy a Lambda function required for Lambda Hooks, followed by registering and activating the Lambda Hook using the deployed function. After activation, we'll test the Lambda hook functionality with new CloudFormation deployments and explore the steps for validating and troubleshooting Lambda Hook invocations.
