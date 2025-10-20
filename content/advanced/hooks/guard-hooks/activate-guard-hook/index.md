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

![Create Hook with Guard](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-start-dropdown-option.png)

##### **Step 1: Provide your Guard rules**

Configure the Guard Hook source with your S3-stored rules:

![Provide Guard Rules](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-provide-your-guard-rules.png)

Use the following parameters:

1. **Guard Hook source** – Select **Store your Guard rules in S3**
2. **S3 URI** – Enter the **S3 URI of your Guard rules file** (e.g., `s3://guard-hook-bucket-<your-name>/hooks/s3-security-rules.guard`)

::alert[If you need to find your S3 URI, refer back to the [Write Guard rules for Hook](../write-guard-rules/) section where you uploaded your Guard rules file.]{type="info"}

3. **Object version** – (Optional) If your S3 bucket has versioning enabled, you can specify a version
4. **S3 bucket for Guard output report** – (Optional) You can use the same bucket for output reports

Click **Next** to continue.

##### **Step 2: Hook details and settings**

Configure the Hook behavior and execution settings:

![Hook Details and Settings](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-hook-details-and-settings.png)

Use the following parameters:

1. **Hook Name** – `S3SecurityGuardHook`
2. **Hook Targets** – Select **Resources**.
   ::alert[We choose **Resources** as the target because our Guard rules are designed to evaluate individual CloudFormation resources (specifically S3 buckets) rather than the entire template.]{type="info"}
3. **Hook Actions** – Select **Create**.
   ::alert[This implements evaluation during CloudFormation **CREATE** operation]{type="info"}
4. **Hook Mode** – Set to **Fail**.
   ::alert[With Hook Mode being Warn the hook will only emit a warning message when a hook fails, without stopping the provisioning operation. While with Fail mode the hook will stop the provisioning operation when a Hook fails.]{type="info"}
5. **Execution Role** – Choose **Existing Execution Role** and select the **GuardHookExecutionRole** created earlier.

::alert[To find your execution role, look for a role name similar to `GuardHookExecutionRoleStack-GuardHookExecutionRole-<random-string>` that was created in the [Prepare to create a Guard Hook](../prepare-guard-hook/) section.]{type="info"}

Click **Next** to continue.

##### **Step 3: Apply Hook filters (Optional)**

Configure which resources the Hook should target:

![Apply Hook Filters](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-apply-hook-filters.png)

For **Hook filters** we will add **`AWS::S3::Bucket`** to filter the hook to just check for the creations of S3 buckets.

We will use the default options for the other configurations here so there is no need to update them.

Click **Next** to continue.

##### **Step 4: Review and activate**

Review all your settings before creating the Hook:

![Review and Activate](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-review-and-activate.png)

Review the settings:
- **Hook Name**: S3SecurityGuardHook
- **Guard Rules Source**: S3 URI pointing to your rules file
- **Target**: Resources (AWS::S3::Bucket)
- **Actions**: Create
- **Mode**: Fail
- **Execution Role**: GuardHookExecutionRole

Click **Create** to register the Hook and wait for a few seconds for the Hook to be created and activated.

![Successful Hook Creation](/static/advanced/hook/advanced-hook-create-a-hook-with-guard-successful-creation.png)

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
