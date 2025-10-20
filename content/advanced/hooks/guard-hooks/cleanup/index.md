---
title: "Cleanup"
weight: 650
---

### Introduction

### Clean Up Resources

After testing is completed, please delete the resources we created during this Lab.

#### Using AWS CLI

Run the following commands to delete the test CloudFormation stacks:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name s3-noncompliant-stack --region us-east-1
:::

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack --stack-name s3-compliant-stack --region us-east-1
:::

#### Disable The Guard Hook

To disable a Hook in your account:

1. Sign in to the AWS Management Console and open the AWS [CloudFormation console](https://console.aws.amazon.com/cloudformation).

2. On the navigation bar at the top of the screen, choose the AWS Region where the Hook is located.

3. From the navigation pane, choose **Hooks**.

4. Choose the name of the Hook you want to **disable** (e.g., `S3SecurityGuardHook`).

5. On the Hook details page, to the right of the Hook's name, choose the **Disable** button.

6. When prompted for confirmation, choose **Disable Hook**.

#### Remove Guard Rules from S3

To clean up the Guard rules stored in S3:

1. **Delete the Guard rules file**:
```bash
aws s3 rm s3://your-guard-rules-bucket/hooks/s3-security-rules.guard
```

2. **Delete any output reports** (if configured):
```bash
aws s3 rm s3://your-guard-rules-bucket/guard-output/ --recursive
```

3. **Optionally delete the S3 bucket** (if created specifically for this lab):
```bash
# First ensure the bucket is empty
aws s3 rb s3://your-guard-rules-bucket --force
```

#### Remove Hook Execution Role

Please use the stack name provided in [Prepare to create a Guard Hook](../prepare-guard-hook/#deploy-the-hook-execution-role) Section:

```bash
aws cloudformation delete-stack --stack-name GuardHookExecutionRoleStack --region us-east-1
```

#### Alternative: Using AWS CLI to Deactivate Guard Hook

You can also deactivate the Guard Hook using the AWS CLI:

```bash
# Deactivate the Guard Hook
aws cloudformation deactivate-type \
    --type HOOK \
    --type-name "AWS::CloudFormation::GuardHook" \
    --region us-east-1
```

#### Verify Cleanup

Verify that the following resources are deleted if they are no longer needed:

- ✅ **Test CloudFormation stacks** (s3-noncompliant-stack, s3-compliant-stack)
- ✅ **Guard Hook** (S3SecurityGuardHook)
- ✅ **Guard rules file in S3** (s3-security-rules.guard)
- ✅ **Guard output reports in S3** (if configured)
- ✅ **IAM execution role** (GuardHookExecutionRole)
- ✅ **S3 bucket** (if created specifically for this lab)

#### Understanding the Cleanup Process

The cleanup process removes:

1. **Test Resources**: The CloudFormation stacks and any S3 buckets they created
2. **Hook Configuration**: The activated Guard Hook and its configuration
3. **Guard Rules**: The policy files stored in S3
4. **IAM Permissions**: The execution role and associated policies
5. **Output Reports**: Any validation reports generated during testing

This ensures that no residual resources remain that could incur costs or interfere with future testing.

Almost done! Choose **Next** to continue!
