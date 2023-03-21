---
title: "Orchestrating with StackSets"
weight: 700
---

_Lab Duration: ~45 minutes_

---

### Overview

You can deploy the same infrastructure in multiple AWS [Regions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html) and/or multiple AWS accounts using [AWS CloudFormation StackSets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html). With CloudFormation StackSets, you can create, update or delete stacks across multiple accounts and AWS regions with a single operation. From an administrator account, you can define and manage a CloudFormation template, and use the template as a basis for provisioning stacks into target accounts or regions of your choice. You can also share parameters between stack sets by [exporting and importing output values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html), and establish dependencies in your stack sets.

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
3. Choose **Create Stack** and select **With new resources**.
4. Leave the **Prepare template** setting as is.
    1. For **Template source**, select **Upload a template file**.
    2. Select **Choose file** and supply the CloudFormation template you downloaded: *AWSCloudFormationStackSetAdministrationRole.yml*. Choose **Next**.
5. For **Stack name**, use `StackSetAdministratorRole`. Choose **Next**.
6. In **Configure stack options** you may choose to configure tags, which are key-value pairs, that can help you identify your stacks and the resources they create. For example, enter *Owner* in the left column which is the tag key, and your email address in the right column which is the tag value. Accept default values for the other settings in the page. Choose **Next**.
7. Under **Review,** review the contents of the page. At the bottom of the page, select **I acknowledge that AWS CloudFormation might create IAM resources with custom names**.
8.  Choose **Submit**.

Wait until the stack creation completes with a `CREATE_COMPLETE` **Status**.

You created the administrator role for StackSets; next, you will create the execution role.

1. Download the execution role CloudFormation template: https://s3.amazonaws.com/cloudformation-stackset-sample-templates-us-east-1/AWSCloudFormationStackSetExecutionRole.yml
2. Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation) and select **Create Stack** and choose **With new resources**.
3. Leave the **Prepare template** setting as is.
    1. For **Template source**, select **Upload a template file**.
    2. Select **Choose file** and supply the CloudFormation template you downloaded: *AWSCloudFormationStackSetExecutionRole.yml*. Choose **Next**.
4. In the **Specify stack details** page: for **Stack name**, use `StackSetExecutionRole`.
5. In **Parameters**, enter the 12-digit account ID for the AWS account you are using for this lab. Choose **Next**.
6. For **Configure stack options** you may choose to configure tags, as mentioned earlier. For example, enter *Owner* for the tag key, and your email address for the tag value. Accept default values for the other settings in the page. Choose **Next**.
7. Under **Review**, review the contents of the page. At the bottom of the page, select **I acknowledge that AWS CloudFormation might create IAM resources with custom names**.
8. Select **Create stack**.

Wait until the stack creation completes with a `CREATE_COMPLETE` **Status**.

Now that you created necessary permissions, you will proceed with Part 1 of the lab.

**Part 1**

In part 1 of this lab, you will use an example CloudFormation template: `example_network.yaml`, and you'll use this template to create stacks in two Regions of the same account using StackSets. In part 2 of this lab, you'll use another example CloudFormation template, `example_securitygroup.yaml`, and create a security group for each network that you created earlier. The architecture diagram of resources you'll describe with `example_network.yaml` is shown next:

![StackSetsNetworkStack](/static/intermediate/operations/stacksets/stacksetsnetworkstack.png)

To get started, follow steps shown next:


1. Change directory to the `code/workspace/stacksets` directory.
2. Open the `example_network.yaml` CloudFormation template in the text editor of your choice.
3. Familiarize with the configuration for the example resources in the template. In the example, your intents are to:
    1. create an [Amazon Virtual Private Cloud](https://docs.aws.amazon.com/vpc/?id=docs_gateway), Internet Gateway, two public subnets, route table, and two routes to the Internet: you will choose to deploy these resources in multiple regions using a single create operation via CloudFormation StackSets;

    2. [export](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) the VPC ID and Subnet IDs outputs. Exports are region-specific.


You will use the `example_network.yaml` template, that contains the network resources mentioned earlier, to deploy the template in two regions (`us-east-1` and `us-west-2`) of the same account.

In this next step, you will use the AWS CloudFormation Console to create a stack set from the `example_network.yaml` template:


1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From the left hand panel, select the **StackSets** tab. Choose **Create StackSets**.
3. In the **Permissions** section: leave the value for **IAM Admin role ARN** empty; set **IAM execution role name** to **AWSCloudFormationStackSetsExecutionRole**.
5. From the **Prerequisite**-**Prepare template** section, choose **Template is ready**.
6. Under **Specify template**, select **Template source** and choose **Upload a template file**. Select **Choose file** and supply the CloudFormation template `example_network.yaml` mentioned earlier, and then choose **Next**.
7. In **Specify StackSet details** page, provide name, description and set parameters:
    1. Specify a **StackSet** name. For example, choose `example-network-workshop`.
    2. Provide a **StackSet description**. For example, choose `Provisions VPC, internet gateway, two public subnets, and two routes`.
    3. For **Parameters**, keep them as is. Choose **Next**.
8. On **Configure StackSet options**, leave **Execution configuration** as is. Choose **Next**.
9. In **Set deployment options** page, in **Add stacks to stack set** section, choose to **Deploy new stacks**
10. Under **Accounts**, choose **Deploy stacks in accounts**.
11. In the **Account numbers** text box, enter the 12-digit AWS account ID for the account you are using for this lab. You can find this value by choosing the user/role drop-down menu on the top-right corner.

![StackSetsDeploymentOptions](/static/intermediate/operations/stacksets/stacksetsdeploymentoptions.png)
1. For **Specify regions**, choose to deploy in **US East (N. Virginia)** and **US West (Oregon)**.
2. Accept default values for **Deployment options**.
3. On the **Review** page, review the contents of the page and choose **Submit**.
4. Refresh the StackSet creation page until you see **CREATE** status as `SUCCEEDED`.

![StackSetCompletion](/static/intermediate/operations/stacksets/createstacksetcompletion.png)

5. Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`.

![StackInstances](/static/intermediate/operations/stacksets/stackinstances.png)
6. Navigate to **Exports**. You should see 3 exports named `AWS-CloudFormationWorkshop-SubnetId1`, `AWS-CloudFormationWorkshop-SubnetId2,` and `AWS-CloudFormationWorkshop-VpcId`. These exports are created in each region where you deployed your stack sets (`us-east-1` and `us-west-2`).

![StackSetExports](/static/intermediate/operations/stacksets/exports.png)

Congratulations! You have deployed your infrastructure to multiple AWS Regions using a single operation.

**Part 2**

In this part of the lab, you will use a new CloudFormation template, `example_securitygroup.yaml`, describing a security group that you will associate to the VPC you created earlier in a given region. You will also export the output for the **Security Group ID**, so that you can consume it later in the *Challenge* portion of this workshop lab. The architecture diagram highlighting the security group resource you will describe with the `example_securitygroup.yaml` template is shown next:

![StackSetsSecuritygroup](/static/intermediate/operations/stacksets/stacksetsecuritygroup.png)

Let’s get started:

1. Make sure you are in the following directory: `code/workspace/stacksets`.
2. Open the `example_securitygroup.yaml` template in your favorite text editor.
3. Familiarize with the configuration for the example security group in the template. In the example, your intents are to:
    1. create a security group: you will choose to deploy your security group in the same VPC you created earlier and in multiple regions using a single create operation using CloudFormation StackSets. You will reference the VPC ID using the `Fn::ImportValue` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html).
    2. export the `SecurityGroupId` output. Exports are region-specific.


In this next step, you will use the AWS CloudFormation console to create a stack set from the `example_securitygroup.yaml` template:


1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From the left hand panel, select the **StackSets** tab. Choose **Create StackSets.**
3. In the **Permissions** section: for **IAM Admin role ARN**, select **IAM role name** from the drop-down menu, and set it to **AWSCloudFormationStackSetAdministrationRole**; set **IAM execution role name** to **AWSCloudFormationStackSetsExecutionRole**.
4. From **Prepare template**, choose **Template is ready**.
5. For **Template source**, choose **Upload a template file**. Select **Choose file** and supply the CloudFormation template `example_securitygroup.yaml` mentioned earlier, and then choose **Next**.
6. In **Specify StackSet details** page, provide name, description and set parameters.
    1. Specify a **StackSet name**. For example, choose `example-securitygroup-workshop`.
    2. Provide a **StackSet description**. For example, choose `Provisions a security group, and associates it to the existing VPC`.
    3. For **Parameters**, keep them as is. Choose **Next**.
7. On **Configure StackSet options**, leave **Execution Configuration** as is. Choose **Next**.
8. In **Set deployment options** page, in **Add stacks to stack set** section, choose to **Deploy new stacks**.
    1. Under **Accounts**, choose **Deploy stacks in accounts** option.
    2. From **Add stacks to stackset**, choose **Deploy new stacks**.
    3. In the **Account numbers** text box, enter the 12-digit AWS account ID for the account you are using for this lab.
    4. For **Specify regions**, choose to deploy in **US East (N. Virginia)** and **US West (Oregon)**.
    5. Accept default values for **Deployment options**. Ensure **Maximum concurrent accounts** is set to **1**, **Failure tolerance** to **0** and **Region Concurrency** to **Sequential**. Choose **Next**.
9. On the **Review** page, review the contents of the page, and choose **Submit**.
10. Refresh the StackSet creation page until you see the **Status** of the **CREATE** operation as `SUCCEEDED`.
11. Under **Stack instances**, you should see two stacks deployed. One in `us-east-1` and another in `us-west-2`.
12. Navigate to **Exports**. You should see a new export named `AWS-CloudFormationWorkshop-SecurityGroupId`.

![StackSetsSecuritygroupexports](/static/intermediate/operations/stacksets/exportssecuritygroup.png)

Congratulations! You have learned how export an output value from a stack set instance, and import it into another stack set instance.


### Challenge

In this exercise, you will use the knowledge gained from earlier parts of this lab. Your task is to create a new `example-ec2instance-workshop` stack set that will provision an [Amazon Elastic Compute Cloud (Amazon EC2)](https://docs.aws.amazon.com/ec2/?id=docs_gateway) instance in the existing VPC, and attach the security group you created earlier. Your task is also to update the `example_ec2instance.yaml` template to import the value for `SubnetId1` that you exported as part of Part 1 of this lab. When you create the stack set, choose to deploy StackSets operations in **Parallel**. The architecture diagram highlighting the EC2 instance you will describe as part of this challenge is shown next:

![StackSetsEc2instance](/static/intermediate/operations/stacksets/stacksetsec2instance.png)

:::expand{header="Need a hint?"}

* Make sure you are in the directory named `code/workspace/stacksets`.
* Open the `example_ec2instance.yaml` CloudFormation template in the text editor of your choice.

::alert[Note: [Amazon Machine Image (AMI) IDs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) are different for instances in different regions. To use region-specific AMI IDs, understand the following code snippet in the Parameters section of your template queries the latest AMI ID for that region and this is also referenced (`LatestAmiId`) in **Parameters** section of your template.]{type="info"}

```yaml
  LatestAmiId:
    Description: The ID of the region-specific Amazon Machine Image to use.
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```
* Edit the Resources section of the template to import the value for SubnetId1 that was exported in Part 1. You can import the parameter of your choice the same way you imported VPC ID from `example_network.yaml` to `example_securitygroup.yaml`.
:::

:::expand{header="Want to see the solution?"}
* You can find the full solution in the `code/solutions/stacksets/example_ec2instance.yaml` template.
* To deploy stack sets in parallel, when creating a new stack set, in **Deployment Options**, choose to deploy as **Parallel**. This will deploy StackSets operation in both the regions in **parallel**, thus saving time.
:::
### Cleanup

You will now tear down the resources you created. To delete stack set, you will first delete stacks within them and then delete the empty stack set.

**How to delete AWS CloudFormation stacks within stack set**

1. Navigate to the [AWS CloudFormation StackSets console.](https://console.aws.amazon.com/cloudformation/home#/stacksets)
2. Select the CloudFormation stack set you want to delete the stacks from. Choose the last stack set you created, i.e. `example_ec2instance` stack set.
3. From top right section of the page, select **Actions** and choose **Delete stacks from StackSet**.
4. Under **Accounts**, select **Deploy stacks in accounts** under **Deployment locations**.
5. Under **Account numbers** enter the 12-digit AWS account ID for the account you are using for this lab. You can find this by selecting the user/role drop down you have logged into the account with on the top right corner.
6. For **Specify regions** select **Add all regions**. This will automatically select the AWS Regions that the StackSet deployed stacks into. Choose **Next**.
7. The **Status** changes to `PENDING`.
8. Refresh until the **Status** changes to `SUCCEEDED`.
9. Follow steps 2 through 8 for the other two stack sets (i.e. example_securitygroup and example_network).


Now that you have deleted stacks within each StackSet, you will now choose to delete the empty StackSet.

**How to delete an AWS CloudFormation stack set**


1. Navigate to [AWS CloudFormation StackSets console](https://console.aws.amazon.com/cloudformation/home#/stacksets).
2. Select the stack set you wish to delete.
3. Choose **Actions** and then **Delete StackSet**.
4. Under **Accounts**, select **Deploy stacks in accounts** under **Deployment locations**.
5. In the popup that appears, confirm you want to delete this stack set by choosing **Delete StackSet**.
6. On refresh, your StackSet should no longer be listed.
7. Follow steps 2 through 6 for other two stack sets.

### Conclusion

Great work! You learned how you can use CloudFormation StackSets to deploy templates in multiple AWS Regions using a single operation, and how to export output parameters from one stack set and import them into the another stack set.
