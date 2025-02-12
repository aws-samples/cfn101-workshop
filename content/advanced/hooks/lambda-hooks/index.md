---
title: "Lamba Hooks"
weight: 500
---

### Introduction

AWS CloudFormation Lambda Hooks enable you to validate CloudFormation and AWS Cloud Control API operations using your custom code logic. When an operation is triggered, your Hook can:

* Evaluate the operation against your defined criteria
* Either block the operation if it doesn't meet requirements
  Or allow it to proceed with a warning message.

These Hooks act as custom validation checkpoints that you can configure to intercept and assess specific CloudFormation operations before they're executed.

You can configure Lambda Hooks to intercept and evaluate the following CloudFormation operations:
* Resource operations
* Stack operations
* Change set operations

Now let’s take an example where we can see use of Lambda Hook at resource level operations. So, as a member of security team for an example organization, task is to ensure that all DynamoDB tables deployed via CloudFormation always have encryption enabled.
<TODO :add details about of type of encryption enabled >
So, for this example first we will review and deploy Lambda function required for Lambda Hooks, then register and activate Lambda Hook using deployed function. Once Lambda Hook is activated, then test the Lambda hook functionality with new CloudFormation deployments as well steps for how to validate and troubleshoot errors for Lambda Hook innovations.

## Start Lab
<TODO :add Lab instructions here, e.g. navigate to Lambda Hooks Folder.>
