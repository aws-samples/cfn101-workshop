---
title: "Activate a Guard Hook"
weight: 630
---

### Introduction

To use an AWS Guard Hook in your account, you must first activate the Hook for the account and Region where you want to use it. Activating a Hook makes it usable in stack operations in the account and Region where it's activated.

When you activate a Guard Hook, CloudFormation creates an entry in your account's registry for the activated Hook as a private Hook. This allows you to set any configuration properties the Hook includes. Configuration properties define how the Hook is configured for a given AWS account and Region.

#### Using AWS Console to Create a Guard Hook

##### **Open AWS CloudFormation Hooks**

1. Open **AWS CloudFormation Console**.
2. Navigate to the **Hooks** section.
3. Click on **With Guard** option in the **Create a Hook** dropdown list.

##### **Configure Hook Settings**

Use the following parameters when configuring the Guard hook:

1. **Hook Name** – `S3SecurityGuardHook`
2. **Guard Hook source** – Select **Store your Guard rules in S3**
3. **S3 URI** – Enter the **S3 URI of your Guard rules file** (e.g., `s3://your-guard-rules-bucket/hooks/s3-security-rules.guard`)
4. **Object version** – (Optional) If your S3 bucket has versioning enabled, you can specify a version
5. **Hook Targets** – Select **Resources**.
   ::alert[We choose **Resources** as the target because our Guard rules are designed to evaluate individual CloudFormation resources (specifically S3 buckets) rather than the entire template. This approach aligns with our Guard rules logic, which examines specific properties of S3 bucket resources like ***VersioningConfiguration*** and ***PublicAccessBlockConfiguration***. When the hook is triggered for each relevant resource during stack operations, it ensures granular validation of these individual resource configurations.]{type="info"}
6. **Hook Actions** – Select **Create**.
   ::alert[This implements evaluation during CloudFormation **CREATE** operation]{type="info"}
7. **Hook Mode** – Set to **Fail**.
   ::alert[With Hook Mode being Warn the hook will only emit a warning message when a hook fails, without stopping the provisioning operation. While with Fail mode the hook will stop the provisioning operation when a Hook fails.]{type="info"}
8. **Execution Role** – Choose **Existing Execution Role** and select the **GuardHookExecutionRole** created earlier in the **Prepare to create a Guard Hook** section.

::alert[You can find more information about the other configuration parameters on the [AWS document page](https://docs.aws.amazon.com/cloudformation-cli/latest/hooks-userguide/guard-hooks-activate-hooks.html)]{type="info"}

##### **Configure S3 Output Report (Optional)**

For **S3 bucket for Guard output report**, you can optionally specify an S3 bucket to store the Guard output report:

1. **S3 URI for output** – Enter an S3 path like `s3://your-guard-rules-bucket/guard-output/`
2. **Report format** – Choose between **JSON** or **YAML** format for the output report

This report will contain detailed results of your Guard rule validations, including which rules passed or failed and why.

Then click on **Next**.

##### **Apply Hook filters**

For **Hook filters** we will add **`AWS::S3::Bucket`** to filter the hook to just check for the creations of S3 buckets.

We will use the default options for the other configurations here so there is no need to update them.

##### **Review and Create Hook**

1. Click **Next**.
2. Review the settings:
   - **Hook Name**: S3SecurityGuardHook
   - **Guard Rules Source**: S3 URI pointing to your rules file
   - **Target**: Resources (AWS::S3::Bucket)
   - **Actions**: Create
   - **Mode**: Fail
   - **Execution Role**: GuardHookExecutionRole
3. Click **Create** to register the Hook.
4. Wait for a few seconds for the Hook to be created and activated.

### Alternative: Using AWS CLI to Activate Guard Hook

You can also activate the Guard Hook using the AWS CLI:

```bash
# First, activate the Hook type
aws cloudformation activate-type \
    --type HOOK \
    --type-name "AWS::CloudFormation::GuardHook" \
    --publisher-id "AWS" \
    --region us-east-1

# Then, set the Hook configuration
aws cloudformation set-type-configuration \
    --type HOOK \
    --type-name "AWS::CloudFormation::GuardHook" \
    --configuration '{
        "CloudFormationConfiguration": {
            "HookConfiguration": {
                "TargetStacks": "ALL",
                "FailureMode": "FAIL",
                "Properties": {
                    "GuardRuleS3Uri": "s3://your-guard-rules-bucket/hooks/s3-security-rules.guard",
                    "OutputS3Uri": "s3://your-guard-rules-bucket/guard-output/",
                    "ExecutionRoleArn": "arn:aws:iam::123456789012:role/GuardHookExecutionRole"
                }
            },
            "TargetOperations": ["CREATE"],
            "TargetFilters": {
                "Types": ["AWS::S3::Bucket"]
            }
        }
    }' \
    --region us-east-1
```

### Understanding Guard Hook Configuration

The Guard Hook configuration includes several important settings:

#### **Guard Rules Source**
- **S3 URI**: Points to your Guard rules file in S3
- **Versioning**: Optionally specify a specific version for consistency
- **Access**: The execution role must have read permissions to this S3 location

#### **Target Configuration**
- **Resources**: Targets individual resource operations
- **Filters**: Limits evaluation to specific resource types (AWS::S3::Bucket)
- **Actions**: Specifies when to run (CREATE, UPDATE, DELETE)

#### **Execution Settings**
- **Failure Mode**: FAIL stops operations on rule violations, WARN allows them to continue
- **Execution Role**: IAM role with necessary S3 permissions

#### **Output Configuration**
- **Output S3 URI**: Optional location for detailed validation reports
- **Report Format**: JSON or YAML format for output reports

### Conclusion

Once the Hook is activated, it will automatically evaluate CloudFormation stack changes based on the defined Guard rules. By enforcing S3 security best practices, the Guard Hook ensures that only compliant S3 bucket configurations are deployed. You can now proceed to the test section and monitor the Hook's behavior in your stack operations using the activated hook.

The Guard Hook will evaluate your S3 resources against the rules we defined:
- ✅ Versioning must be enabled
- ✅ Public access must be blocked
- ✅ Server-side encryption must be configured
- ✅ No public read access allowed

Choose **Next** to test the Guard Hook functionality!
