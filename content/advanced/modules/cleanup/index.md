---
title: "Clean up"
weight: 340
---

## Clean Up

To clean up the resources you created in this module, follow steps shown next.

Delete the sample stack that consumed the sample module:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name cfn-workshop-modules
aws cloudformation wait stack-delete-complete --stack-name cfn-workshop-modules
:::

:::alert{header="Only required if you completed the challenge" type="warning"}
Deregister version `00000001` of the module from the CloudFormation Registry. You will need to repeat this step for each version of this module you registered (except for the default version that cannot be deregistered):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE --version-id 00000001
:::

Deregister the module from the CloudFormation Registry:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation deregister-type --type MODULE --type-name CFNWORKSHOP::EC2::VPC::MODULE
:::
