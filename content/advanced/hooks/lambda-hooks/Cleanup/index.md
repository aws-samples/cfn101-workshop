---
title: "Cleanup"
weight: 550
---

### Introduction

TODO: dessumi move this to cleanup section
### Clean Up Resources

After testing, you can delete the test resources.
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
