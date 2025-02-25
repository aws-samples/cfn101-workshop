---
title: "Cleanup"
weight: 550
---

### Introduction

### Clean Up Resources

After testing is completed, you can delete the resources we created during this Lab.
#### Using AWS CLI**

Run the following command to delete a specific stack:
**TODO dessumi:add commands for each Stack deletion**
```
aws cloudformation delete-stack --stack-name YourStackName
```
#### Ensure Complete Cleanup**

- Verify that the **Lambda function, IAM roles, and log groups** are deleted if they are no longer needed.

**TODO dessumi:Add deregistring the Hook steps**
**TODO dessumi:add undeploy Lambds function steps**
