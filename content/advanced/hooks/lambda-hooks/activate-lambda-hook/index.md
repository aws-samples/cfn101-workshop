---
title: "Activate a Lambda Hook"
weight: 530
---

### Introduction

To use an AWS Lambda Hook in your account, you must first activate the Hook for the account and Region where you want to use it. Activating a Hook makes it usable in stack operations in the account and Region where it's activated.

When you activate a Lambda Hook, CloudFormation creates an entry in your account's registry for the activated Hook as a private Hook. This allows you to set any configuration properties the Hook includes. Configuration properties define how the Hook is configured for a given AWS account and Region.

#### Using AWS Console to Create a Lambda Hook

##### **Open AWS CloudFormation Hooks**

1. Open **AWS CloudFormation Console**.
2. Navigate to the **Hooks** section.
3. Click on **With Lambda** option in the **Create a Hook** dropdown list.

##### **Configure Hook Settings**

![hook-detail.png](/static/advanced/hook/hook-detail.png "hook-detail")
Use the following parameters when configuring the lambda hook:

1. **Hook Name** – `DynamoDBConfigValidationHook`
2. **Lambda Function ARN** – Enter the **ARN copied earlier**.
3. **Hook Targets** – Select **Resources**.
   ::alert[We choose **Resources** as the target because our Lambda function is designed to evaluate individual CloudFormation resources (specifically DynamoDB tables) rather than the entire template. This approach aligns with our Lambda function's logic, which examines specific properties of DynamoDB table resources like ***PointInTimeRecoveryEnabled*** and ***ProvisionedThroughput***. When the hook is triggered for each relevant resource during stack operations, it ensures granular validation of these individual resource configurations.]{type="info"}
4. **Hook Actions** – Select **Create**.
   ::alert[This implements evaluation during CloudFormation **CREATE** operation]{type="info"}
5. **Hook Mode** – Set to **Fail**.
   ::alert[With Hook Mode being Warn the hook will only emit a warning message when a hook fails, without stopping the provisioning operation. While with Fail mode the hook will stop the provisioning operation when a Hook fails.]{type="info"}
6. **Execution Role** – Choose **Existing Execution Role** and select the **HookExecutionRole** created earlier in the **Prepare to create a Lambda Hook** section.

::alert[You can find more information about the other configuration parameters on the [AWS document page](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/lambda-hooks-activate-hooks.html)]{type="info"}
Then click on **Next**.

##### **Apply Hook filters**

For **Hook filters** we will add **`AWS::DynamoDB::Table`** to filter the hook to just check for the creations of DynamoDB tables.

![hook-filters.png](/static/advanced/hook/hook-filters.png "hook-filters")

We will use the default options for the other configurations here so there is no need to update them.

##### **Review and Create Hook**

1. Click **Next**.
2. Review the settings.
3. Click **Create** to register the Hook.
   ![hook-review.png](/static/advanced/hook/hook-review.png "hook-review")
4. Then wait for a few seconds for the Hook to be created.
   ![hook-activate-after-creation.png](/static/advanced/hook/hook-activate-after-creation.png "hook-activate-after-creation")

### Conclusion

Once the Hook is activated, it will automatically evaluate CloudFormation stack changes based on the defined targets and actions. By enforcing best practices and compliance requirements, the Lambda Hook ensures that only approved configurations are deployed. You can now proceed to the test section and monitor the Hook's behavior in your stack operations using the activated hook.
