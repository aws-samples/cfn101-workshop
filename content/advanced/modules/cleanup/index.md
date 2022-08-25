---
title: "Clean up"
weight: 340
---

## Clean Up

To clean up the resources you created in this module execute the following commands:

Delete the sample Stack that consumed the sample Module.

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name cfn-workshop-modules
aws cloudformation wait stack-delete-complete --stack-name cfn-workshop-modules
:::

:::alert{header="Only required if you completed the challenge" type="warning"}
Deregister version 1 of the Module from the CloudFormation Registry

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE --version-id 00000001
:::

Deregister the Module from the CloudFormation Registry

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE
:::
