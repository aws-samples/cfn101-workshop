---
title: "Orchestrating with StackSets"
weight: 700
---

_Lab Duration: ~45 minutes_

---

### Overview

You can deploy the same infrastructure in multiple AWS [Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) and/or multiple AWS accounts using [AWS CloudFormation StackSets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html). With CloudFormation StackSets, you can create, update, or delete stacks across multiple accounts and AWS regions with a single operation. From an administrator account, you can define and manage a CloudFormation template, and use the template as a basis for provisioning stacks into target accounts or regions of your choice. You can also share parameters between stack sets by [exporting and importing output values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html), and establish dependencies in your stack sets.

Although you can use StackSets to deploy across multiple AWS accounts and regions, in this lab you will focus on learning how to deploy across regions using one account. An architecture diagram of the target state is shown next:

![StackSetsOverview](/static/intermediate/operations/stacksets/stacksetsoverview.png)

### Topics Covered

By the end of this lab, you will be able to:

* Leverage CloudFormation StackSets to provision resources in one account and across multiple regions using a single operation.
* Understand how you can export output parameters from a stack set instance, and import them into another stack set instance.

### Start Lab

### Prerequisites

Specific permissions are required by AWS CloudFormation StackSets to deploy stacks in multiple AWS accounts - and across multiple AWS Regions. You will need an administrator role to perform StackSets operations, and an execution role to deploy the actual stacks in target account(s). These roles require specific naming conventions: **AWSCloudFormationStackSetAdministrationRole** for the administrator role, and **AWSCloudFormationStackSetExecutionRole** for the execution role. StackSets execution will fail if these roles are missing.

::alert[Note that, on cross-account deployments, the **AWSCloudFormationStackSetAdministrationRole** should be created in the account where you are creating the stack set (the Administrator account). The **AWSCloudFormationStackSetExecutionRole** should be created in each target account where you wish to deploy the stack. Learn more about [granting self-managed permissions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html) for CloudFormation StackSets. If your accounts are managed using AWS Organizations, you can [enable trusted access](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-orgs-enable-trusted-access.html), and CloudFormation will take care of provisioning all the necessary roles across the accounts.]{type="info"}

To get started with this lab, use CloudFormation to create the administrator and execution roles:

1.  Download the administrator role CloudFormation template: https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetAdministrationRole.yml
2. Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), and make sure you are in the **US East (N. Virginia)** region.
3. Choose **Create Stack**, and select **With new resources**.
4. Leave the **Prepare template** setting as is.
    1. For **Template source**, select **Upload a template file**.
    2. Select **Choose file**, and supply the CloudFormation template you downloaded: *AWSCloudFormationStackSetAdministrationRole.yml*. Choose **Next**.
5. For **Stack name**, use `StackSetAdministratorRole`. Choose **Next**.
6. In **Configure stack options** you may choose to configure tags, which are key-value pairs, that can help you identify your stacks and the resources they create. For example, enter *Owner* in the left column which is the tag key, and your email address in the right column which is the tag value. Accept default values for the other settings in the page. Choose **Next**.
7. Under **Review,** review the contents of the page. At the bottom of the page, select **I acknowledge that AWS CloudFormation might create IAM resources with custom names**.
8.  Choose **Submit**.

Wait until the stack creation completes with a `CREATE_COMPLETE` **Status**.

You created the administrator role for StackSets; next, you will create the execution role.

1. Download the execution role CloudFormation template: https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml
2. In the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), select **Create Stack** and choose **With new resources**.
3. Leave the **Prepare template** setting as is.
    1. For **Template source**, select **Upload a template file**.
    2. Select **Choose file**, and supply the CloudFormation template you downloaded: *AWSCloudFormationStackSetExecutionRole.yml*. Choose **Next**.
4. In the **Specify stack details** page: for **Stack name**, use `StackSetExecutionRole`.
5. In **Parameters**, enter the 12-digit account ID for the AWS account you are using for this lab. Choose **Next**.
6. For **Configure stack options** you may choose to configure tags, as mentioned earlier. For example, enter *Owner* for the tag key, and your email address for the tag value. Accept default values for the other settings in the page. Choose **Next**.
7. Under **Review**, review the contents of the page. At the bottom of the page, select **I acknowledge that AWS CloudFormation might create IAM resources with custom names**.
8. Select **Submit**.

Wait until the stack creation completes with a `CREATE_COMPLETE` **Status**.

Now that you created necessary permissions, you will proceed with Part 1 of the lab.

#### Part 1

In part 1 of this lab, you'll use an example CloudFormation template, `example_network.yaml`, to create stacks in two Regions of the same account using StackSets. In part 2 of this lab, you'll use another example CloudFormation template, `example_securitygroup.yaml`, and create a security group for each network you created with the previous stack set. The architecture diagram of resources you'll describe with `example_network.yaml` is shown next:

![StackSetsNetworkStack](/static/intermediate/operations/stacksets/stacksetsnetworkstack.png)

To get started, follow steps shown next:

1. Navigate to the `code/workspace/stacksets` directory.
1. Open the `example_network.yaml` CloudFormation template in the text editor of your choice.
1. Familiarize with the configuration for the example resources in the template. In the example, your intents are to:
   1. create an [Amazon Virtual Private Cloud](https://aws.amazon.com/vpc/), Internet Gateway, two public subnets, route table, and two routes to the Internet: you will choose to deploy these resources in multiple regions using a single create operation via CloudFormation StackSets;
   1. [export](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) the VPC ID and Subnet IDs outputs. Exports are region-specific.

You will use the `example_network.yaml` template, that contains the network resources mentioned earlier, to deploy the template in two regions (`us-east-1` and `us-west-2`) of the same account.

In this next step, you will use the AWS CloudFormation Console to create a stack set from the `example_network.yaml` template:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's **Create StackSets** by using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-network \
--template-body file://example_network.yaml
:::
1. Create stack instances to your stackset by using the following AWS CLI command. This command requires you specify the 12-digit AWS Account ID for the account you are using for this Lab. You can find this value by choosing the user/role drop-down menu in the top-right corner.For regions, choose to deploy in US East (N. Virginia) and US West (Oregon).
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-network \
--accounts 123456789012 \
--regions us-east-1 us-west-2
:::
1. CloudFormation returns the following output.
:::code{language=json showLineNumbers=false showCopyAction=false}
"OperationId": "d7995c31-83c2-xmpl-a3d4-e9ca2811563f"
:::
1. Verify that the stack instances were created successfully. Run `DescribeStackSetOperation` with the `operation-id` that is returned as part of the output of step 3.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-set-operation \
--stack-set-name cfn-workshop-network \
--operation-id operation_ID
:::
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/). From the panel on the left of the page, select the **StackSets** tab.
1. Select `cfn-workshop-network`,Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From the panel on the left of the page, select the **StackSets** tab. Choose **Create StackSets**.
1. In the **Permissions** section: choose **Self-service permissions**; leave the value for **IAM Admin role ARN** empty; set **IAM execution role name** to **AWSCloudFormationStackSetsExecutionRole**.
1. From the **Prerequisite**-**Prepare template** section, choose **Template is ready**.
1. Under **Specify template**, select **Template source** and choose **Upload a template file**. Select **Choose file** and supply the CloudFormation template `example_network.yaml` mentioned earlier, and then choose **Next**.
1. In **Specify StackSet details** page, provide name, description, and set parameters:
    1. Specify a **StackSet** name. For example, choose `cfn-workshop-network`.
    2. Provide a **StackSet description**. For example, choose `Provisions VPC, internet gateway, two public subnets, and two routes to the Internet`.
    3. Accept default values for **Parameters**. Choose **Next**.
1. On **Configure StackSet options**, leave **Execution configuration** as is. Choose **Next**.
1. In **Set deployment options** page, in **Add stacks to stack set** section, choose to **Deploy new stacks**.
1. Under **Accounts**, choose **Deploy stacks in accounts**.
1. In the **Account numbers** text box, enter the 12-digit AWS account ID for the account you are using for this lab. You can find this value by choosing the user/role drop-down menu in the top-right corner.
![StackSetsDeploymentOptions](/static/intermediate/operations/stacksets/stacksetsdeploymentoptions.png)
1. For **Specify regions**, choose to deploy in **US East (N. Virginia)** and **US West (Oregon)**.
1. Accept default values for **Deployment options**, and choose **Next**.
1. On the **Review** page, review the contents of the page and choose **Submit**.
1. Refresh the StackSet creation page until you see **CREATE** status as `SUCCEEDED`.
![StackSetCompletion](/static/intermediate/operations/stacksets/createstacksetcompletion.png)
1. Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`.
![StackInstances](/static/intermediate/operations/stacksets/stackinstances.png)
::::
:::::
Navigate to **Exports**. You should see 3 exports named `AWS-CloudFormationWorkshop-SubnetId1`, `AWS-CloudFormationWorkshop-SubnetId2,` and `AWS-CloudFormationWorkshop-VpcId`. These exports are created in each region where you deployed your stack sets (`us-east-1` and `us-west-2`).

![StackSetExports](/static/intermediate/operations/stacksets/exports.png)

Congratulations! You have deployed your infrastructure to multiple AWS Regions using a single operation.

#### Part 2

In this part of the lab, you will use a new CloudFormation template, `example_securitygroup.yaml`, describing a security group that you will associate to the VPC you created earlier in a given region. You will also export the output for the **Security Group ID**, so that you can consume it later in the *Challenge* portion of this workshop lab. The architecture diagram highlighting the security group resource you will describe with the `example_securitygroup.yaml` template is shown next:

![StackSetsSecurityGroup](/static/intermediate/operations/stacksets/stacksetsecuritygroup.png)

Let’s get started:

1. Navigate to the `code/workspace/stacksets` directory.
1. Open the `example_securitygroup.yaml` template in your favorite text editor.
1. Familiarize with the configuration for the example security group in the template. In the example, your intents are to:
    1. create a security group for the VPC you created earlier in each of the two regions with a single create operation using CloudFormation StackSets. You will reference the VPC ID using the `Fn::ImportValue` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html);
    2. export the `SecurityGroupId` output. Exports are region-specific

In this next step, you will use the AWS CloudFormation console to create a stack set from the `example_securitygroup.yaml` template:
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Let's **Create StackSets** by using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-security \
--template-body file://example_securitygroup.yaml
:::
1. Create stack instances to your stackset by using the following AWS CLI command. This command requires you specify the 12-digit AWS Account ID for the account you are using for this Lab. You can find this value by choosing the user/role drop-down menu in the top-right corner. For regions, choose to deploy in US East (N. Virginia) and US West (Oregon).
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-security \
--accounts 123456789012 \
--regions us-east-1 us-west-2
:::
1. CloudFormation returns the following output.
:::code{language=json showLineNumbers=false showCopyAction=false}
"OperationId": "d7995c31-83c2-xmpl-a3d4-e9ca2811563f"
:::
1. Verify that the stack instances were created successfully. Run `DescribeStackSetOperation` with the `operation-id` that is returned as part of the output of step 3.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-set-operation \
--stack-set-name cfn-workshop-security \
--operation-id operation_ID
:::
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/). From the panel on the left of the page, select the **StackSets** tab.
1. Select `cfn-workshop-security`,Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Select the **StackSets** tab. Choose **Create StackSets**.
1. In the **Permissions** section: choose **Self-service permissions**; for **IAM Admin role ARN**, select **IAM role name** from the drop-down menu, and set it to **AWSCloudFormationStackSetAdministrationRole**; set **IAM execution role name** to **AWSCloudFormationStackSetsExecutionRole**.
1. From **Prepare template**, choose **Template is ready**.
1. For **Template source**, choose **Upload a template file**. Select **Choose file** and supply the CloudFormation template `example_securitygroup.yaml` mentioned earlier, and then choose **Next**.
1. In **Specify StackSet details** page, provide name, description, and set parameters:
   1. Specify a **StackSet name**. For example, choose `cfn-workshop-security`.
   1. Provide a **StackSet description**. For example, choose `Provisions a security group, and associates it to the existing VPC`.
   1. Accept default values for **Parameters**. Choose **Next**.
1. On **Configure StackSet options**, leave **Execution Configuration** as is. Choose **Next**.
1. In **Set deployment options** page, in **Add stacks to stack set** section, choose to **Deploy new stacks**.
   1. Under **Accounts**, choose **Deploy stacks in accounts** option.
   1. From **Add stacks to stackset**, choose **Deploy new stacks**.
   1. In the **Account numbers** text box, enter the 12-digit AWS account ID for the account you are using for this lab.
   1. For **Specify regions**, choose to deploy in **US East (N. Virginia)** and **US West (Oregon)**.
   1. Accept default values for **Deployment options**. Ensure **Maximum concurrent accounts** is set to **1**, **Failure tolerance** to **0** and **Region Concurrency** to **Sequential**. Choose **Next**.
   1. On the **Review** page, review the contents of the page, and choose **Submit**.
   1.  Refresh the StackSet creation page until you see the **Status** of the **CREATE** operation as `SUCCEEDED`.
   1.  Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`.
::::
:::::

Navigate to **Exports**. You should see a new export named `AWS-CloudFormationWorkshop-SecurityGroupId`.

![StackSetsSecurityGroupExports](/static/intermediate/operations/stacksets/exportssecuritygroup.png)

Congratulations! You have learned how export an output value from a stack set instance, and import it into another stack set instance.

### Challenge

In this exercise, you will use the knowledge gained from earlier parts of this lab. Your task is to create a new `cfn-workshop-ec2instance` stack set that will provision an [Amazon Elastic Compute Cloud (Amazon EC2)](https://docs.aws.amazon.com/ec2/?id=docs_gateway) instance in the existing VPC, and attach the security group you created earlier. Your task is also to update the `example_ec2instance.yaml` template to import the value for `SubnetId1` that you exported as part of Part 1 of this lab. When you create the stack set, choose to deploy StackSets operations in **Parallel**. The architecture diagram highlighting the EC2 instance you will describe as part of this challenge is shown next:

![StackSetsEc2instance](/static/intermediate/operations/stacksets/stacksetsec2instance.png)

::::expand{header="Need a hint?"}
* Make sure you are in the directory named `code/workspace/stacksets`.
* Open the `example_ec2instance.yaml` CloudFormation template in the text editor of your choice.

:::alert{type="info"}
[Amazon Machine Image (AMI)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) resources are unique in each region. To use region-specific AMI IDs, you use the following code snippet in the `Parameters` section of your template to query the ID of the latest AMI for a given region; you also reference `LatestAmiId` in the **Resources** section of your template in `ImageId`.
:::
:::code{language=yaml showLineNumbers=false showCopyAction=false}
LatestAmiId:
  Description: The ID of the region-specific Amazon Machine Image to use.
  Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
  Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
:::
* Edit the `Resources` section of the template to import the value for `SubnetId1` that you exported in Part 1. You can import the parameter of your choice the same way you imported the ID of the VPC, from `example_network.yaml` to `example_securitygroup.yaml`.
::::

::::::expand{header="Want to see the solution?"}
You can find the full solution in the `code/solutions/stacksets/example_ec2instance.yaml` template.

Append the following to the EC2 instance properties: `SubnetId: !ImportValue AWS-CloudFormationWorkshop-SubnetId1`.
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Change the directory to `cfn101-workshop/code/solutions/stacksets`.
1. Use the updated template, and create a new **StackSet** using the following AWS CLI command.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-set \
--stack-set-name cfn-workshop-ec2instance \
--template-body file://example_ec2instance.yaml
:::
1. Create stack instances to your stackset by using the following AWS CLI command. To deploy StackSets operations in parallel, choose **Parallel** for `RegionalConcurrencyType` from `--operation-preferrences`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack-instances \
--stack-set-name cfn-workshop-ec2instance \
--accounts 123456789012 \
--regions us-east-1 us-west-2 \
--operation-preferences RegionConcurrencyType=PARALLEL
:::
::::
::::tab{id="local" label="Local development"}
Use the updated template, and create a new `cfn-workshop-ec2instance` stack set to deploy the EC2 instance resources in the 2 regions you chose earlier.  To deploy StackSets operations in parallel, from **Deployment Options** choose **Parallel**. This will deploy StackSets operations in both regions in parallel, thus saving time.
::::
:::::
::::::

### Cleanup

You will now tear down the resources you created. To delete a stack set, you will first delete its stack set instances, and then delete the empty stack set.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. Delete the **StackSet** Instances before you delete the StackSets from AWS CLI.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack-instances \
--stack-set-name cfn-workshop-ec2instance \
--accounts 123456789012 \
--regions us-east-1 us-west-2 \
--no-retain-stacks
:::
1. Wait for `DELETE-STACK-INSTANCE` operation to complete and run the following command to delete the **StackSets**
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack-set \
--stack-set-name cfn-workshop-ec2instance
:::
1. Follow the steps 1-2 for other two stack sets, and in the following order: `cfn-workshop-security`, and `cfn-workshop-network`.
1. Delete the IAM Roles that you created during this lab by running the following AWS CLI command
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--stack-set-name StackSetAdministratorRole
:::
1. Repeat the step 4 to **Delete** the execution role stack `StackSetAdministratorRole`.
::::
::::tab{id="local" label="Local development"}

**How to delete AWS CloudFormation stacks within stack set**

1. Navigate to the [AWS CloudFormation StackSets console.](https://console.aws.amazon.com/cloudformation/home#/stacksets)
1. Select the CloudFormation stack set you want to delete the stacks from. Choose the last stack set you created, i.e., `cfn-workshop-ec2instance`.
1. From top-right section of the page, select **Actions**, and choose **Delete stacks from StackSet**.
1. Under **Accounts**, select **Deploy stacks in accounts** under **Deployment locations**.
1. Under **Account numbers** enter the 12-digit AWS account ID for the account you are using for this lab.
1. For **Specify regions** select **Add all regions**. This will automatically select the AWS Regions that the StackSet deployed stacks into. Choose **Next**.
1. On the **Review** page, review the contents of the page, and choose **Submit**.
1. The **Status** changes to `PENDING`.
1. Refresh until the **Status** changes to `SUCCEEDED`.
1. Follow steps 2 through 8 for the other two stack sets, and in the following order: `cfn-workshop-security`, and `cfn-workshop-network`.

Now that you have deleted stacks within each StackSet, you will now choose to delete the empty StackSet.

**How to delete an AWS CloudFormation stack set**

1. Navigate to [AWS CloudFormation StackSets console](https://console.aws.amazon.com/cloudformation/home#/stacksets).
1. Select the stack set you wish to delete.
1. Choose **Actions**, and then **Delete**.
1. In the popup that appears, confirm you want to delete this stack set by choosing **Delete StackSet**.
1. On refresh, your StackSet should no longer be listed.
1. Follow steps 2 through 5 for the two other stack sets.

**How to delete an AWS CloudFormation stacks**

1. Navigate to [AWS CloudFormation Stacks console](https://console.aws.amazon.com/cloudformation/home#/stacks).
1. Select the stack `StackSetAdministratorRole`, choose **Delete**.
1. In the popup that appears, confirm you want to delete this stack set by choosing **Delete**.
1. On refresh, your stack `StackSetAdministratorRole` should no longer be listed.
1. Follow steps 2 through 4 for the other stack `StackSetExecutionRole` that you created during this lab .
::::
:::::

### Conclusion

Great work! You learned how you can use CloudFormation StackSets to deploy templates in multiple AWS Regions using a single operation, and how to export output parameters from one stack set instance and import them into another stack set instance.
