---
title: "Test Guard Hook"
weight: 640
---

### **Introduction**

Now that we have deployed the **S3SecurityGuardHook**, we need to test it to ensure it correctly validates S3 configurations before CloudFormation provisions resources.

We will test the hook with two different CloudFormation stacks.

1. **A non-compliant S3 bucket** that violates the Guard rules and fails the CloudFormation Stack deployment.
2. **A compliant S3 bucket** that meets all Guard rule criteria which results into successful deployment of CloudFormation stack.

---

::alert[To get started, ensure that you are in `cfn101-workshop/code/workspace/hooks/guard_hook` directory.]{type="info"}

#### **Scenario 1: Non-Compliant S3 Bucket (Validation Failure)**

Locate and open the `noncompliant-s3.yaml` file.
The CloudFormation template in this file **violates several Guard rules** that the Guard Hook is currently validating.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  NonCompliantS3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: noncompliant-test-bucket
      # Missing VersioningConfiguration - violates s3_versioning_enabled rule
      # Missing PublicAccessBlockConfiguration - violates s3_public_access_blocked rule
      # Missing BucketEncryption - violates s3_encryption_enabled rule
      AccessControl: PublicRead  # Violates s3_no_public_read rule
```

Next, from the directory where the file above is, use the AWS CLI to create a stack, in the us-east-1 region, with that template:

:::code{language=shell showLineNumbers=false showCopyAction=true}

aws cloudformation create-stack \
 --stack-name s3-noncompliant-stack \
 --template-body file://noncompliant-s3.yaml \
 --region us-east-1
:::

The cloudformation `create-stack` command will return an output in JSON format like this:

```JSON
{
    "StackId": "arn:aws:cloudformation:us-east-1:xxxxxxxxxxxx:stack/s3-noncompliant-stack/b2xxxxxxx-fxx-11xxf-9xx4-xxxxxxxxxxx7"
}
```

Then let's check the stack events and hook evaluation results using the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-events \
 --stack-name s3-noncompliant-stack \
 --query 'StackEvents[?HookType!=`null` && contains(HookType, `S3SecurityGuardHook`)]' \
 --region us-east-1
:::

##### Checking for Hook Status Messages

When executing the above command, you need to look for the HookStatus field in the response. Initially, you might see `"HOOK_IN_PROGRESS"` status, which means the hook is still evaluating the template.

You should continue running the command repeatedly (every few seconds) until you see either:

- "HookStatus": **_"HOOK_COMPLETE_FAILED"_** (for non-compliant templates)
- "HookStatus": **_"HOOK_COMPLETE_SUCCEEDED"_** (for compliant templates)

Since the stack contains an S3 bucket definition that is non-compliant according to the Guard rules in the Guard Hook, the stack will fail to create. The `describe-stack-events` command will show the hook evaluation results similar to the following:

```json
[
  {
    "StackId": "arn:aws:cloudformation:region:account-id:stack/s3-noncompliant-stack/stack-id",
    "EventId": "NonCompliantS3Bucket-example-id-1",
    "StackName": "s3-noncompliant-stack",
    "LogicalResourceId": "NonCompliantS3Bucket",
    "PhysicalResourceId": "",
    "ResourceType": "AWS::S3::Bucket",
    "Timestamp": "2025-03-14T01:31:49.324000+00:00",
    "ResourceStatus": "CREATE_IN_PROGRESS",
    "HookType": "Private::Guard::S3SecurityGuardHook",
    "HookStatus": "HOOK_COMPLETE_FAILED",
    "HookStatusReason": "Hook failed with message: Guard rule validation failed. Multiple rules violated: s3_versioning_enabled, s3_public_access_blocked, s3_encryption_enabled, s3_no_public_read",
    "HookInvocationPoint": "PRE_PROVISION",
    "HookFailureMode": "FAIL"
  },
  {
    "StackId": "arn:aws:cloudformation:region:account-id:stack/s3-noncompliant-stack/stack-id",
    "EventId": "NonCompliantS3Bucket-example-id-2",
    "StackName": "s3-noncompliant-stack",
    "LogicalResourceId": "NonCompliantS3Bucket",
    "PhysicalResourceId": "",
    "ResourceType": "AWS::S3::Bucket",
    "Timestamp": "2025-03-14T01:31:48.536000+00:00",
    "ResourceStatus": "CREATE_IN_PROGRESS",
    "HookType": "Private::Guard::S3SecurityGuardHook",
    "HookStatus": "HOOK_IN_PROGRESS",
    "HookStatusReason": "Invoking hook",
    "HookInvocationPoint": "PRE_PROVISION",
    "HookFailureMode": "FAIL"
  }
]
```

The stack events show the progression and failure of the non-compliant stack deployment:

1. Initially, the hook starts its evaluation (HOOK_IN_PROGRESS) during the PRE_PROVISION phase
2. The hook then fails (HOOK_COMPLETE_FAILED) with specific Guard rule violations:
   - s3_versioning_enabled: Versioning configuration is missing
   - s3_public_access_blocked: Public access block configuration is missing
   - s3_encryption_enabled: Bucket encryption is not configured
   - s3_no_public_read: Public read access is explicitly allowed
3. Because the hook's HookFailureMode is set to FAIL, the stack creation is halted and rolled back

This demonstrates how the Guard Hook effectively prevents the deployment of S3 buckets that don't meet the specified security requirements, ensuring consistent configuration standards across your AWS infrastructure.

**Understand CloudFormation Stack Failure**

In order to understand the detailed reason for stack failure in the AWS Console, follow the steps below.

- Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
- Locate the latest deployment for `s3-noncompliant-stack` Stack.
- Navigate to the Events section.
- Locate the `S3SecurityGuardHook` under the Hook invocations section. This entry will contain details about the status of Hook as _Fail_ and Hook status reason with a detailed error message showing which Guard rules failed.

---

### **Scenario 2: Compliant S3 Bucket**

Locate and open the `compliant-s3.yaml` file.
The CloudFormation template in this file **meets all the required Guard rules** that the Guard Hook is currently validating.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  CompliantS3Bucket:
    Type: 'AWS::S3::Bucket'
    Properties:
      BucketName: compliant-test-bucket
      # Compliance: Versioning must be enabled
      VersioningConfiguration:
        Status: Enabled
      # Compliance: Public access must be blocked
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      # Compliance: Server-side encryption must be enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      # Compliance: No public read access (default behavior, no explicit ACL)
```

Next, from the directory where the file above is, use the AWS CLI to create a stack, in the us-east-1 region, with that template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
 --stack-name s3-compliant-stack \
 --template-body file://compliant-s3.yaml \
 --region us-east-1
:::

To monitor the stack creation progress and view the hook evaluation results, use the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation describe-stack-events \
 --stack-name s3-compliant-stack \
 --query 'StackEvents[?HookType!=`null` && contains(HookType, `S3SecurityGuardHook`)]' \
 --region us-east-1
:::

##### Checking for Hook Status Messages

As with the non-compliant stack, you need to run the describe-stack-events command repeatedly until you see the final hook status:

- If you initially see the only event with "HookStatus": `"HOOK_IN_PROGRESS"`, wait a few seconds and run the command again
- Continue checking until you see "HookStatus": "HOOK_COMPLETE_SUCCEEDED", which indicates the Guard rule validation passed.

For a compliant stack, you should see events similar to this:

```json
[
  {
    "StackId": "arn:aws:cloudformation:region:account-id:stack/s3-compliant-stack/stack-id",
    "EventId": "CompliantS3Bucket-example-id-1",
    "StackName": "s3-compliant-stack",
    "LogicalResourceId": "CompliantS3Bucket",
    "PhysicalResourceId": "",
    "ResourceType": "AWS::S3::Bucket",
    "Timestamp": "2025-03-14T01:37:48.528000+00:00",
    "ResourceStatus": "CREATE_IN_PROGRESS",
    "HookType": "Private::Guard::S3SecurityGuardHook",
    "HookStatus": "HOOK_COMPLETE_SUCCEEDED",
    "HookStatusReason": "Hook succeeded with message: All Guard rules passed validation",
    "HookInvocationPoint": "PRE_PROVISION",
    "HookFailureMode": "FAIL"
  },
  {
    "StackId": "arn:aws:cloudformation:region:account-id:stack/s3-compliant-stack/stack-id",
    "EventId": "CompliantS3Bucket-example-id-2",
    "StackName": "s3-compliant-stack",
    "LogicalResourceId": "CompliantS3Bucket",
    "PhysicalResourceId": "",
    "ResourceType": "AWS::S3::Bucket",
    "Timestamp": "2025-03-14T01:37:47.833000+00:00",
    "ResourceStatus": "CREATE_IN_PROGRESS",
    "HookType": "Private::Guard::S3SecurityGuardHook",
    "HookStatus": "HOOK_IN_PROGRESS",
    "HookStatusReason": "Invoking hook",
    "HookInvocationPoint": "PRE_PROVISION",
    "HookFailureMode": "FAIL"
  }
]
```

Unlike the non-compliant stack, these stack events show the successful progression of the compliant stack deployment:

1. The hook begins its evaluation (`"HOOK_IN_PROGRESS"`) during the PRE_PROVISION phase
2. The hook then completes successfully (HOOK_COMPLETE_SUCCEEDED), confirming that:
   - All Guard rules passed validation
   - The S3 bucket configuration meets all security requirements
   - The hook validation allows the stack creation to proceed

To verify the complete stack creation, you can navigate to the AWS CloudFormation Console and check that the stack status is CREATE_COMPLETE.

::alert[While the hook validation succeeded, the final stack creation still depends on other factors such as IAM permissions and service quotas.]{type="info"}

**Review CloudFormation Stack Creation in the AWS Console**

You can review stack and Hook execution status in the AWS Console, by following the steps below.

- Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
- Locate the latest deployment for `s3-compliant-stack` Stack.
  - If the status is `CREATE_COMPLETE`, it means the S3 bucket configuration met all Guard rule checks enforced by the Guard Hook, and the stack deployment was successful.
  - If not check the Events output for errors.
- Navigate to the Events section.
- Locate the `S3SecurityGuardHook` under the Hook invocations section. This entry will contain details about the status of the Hook and **Hook status reason** with a successful execution message.

---

### View Guard Output Reports in S3

If you configured an S3 output location during Hook activation, you can view detailed Guard validation reports:

1. Open **Amazon S3 Console**.
2. Navigate to your configured output bucket and prefix (e.g., `s3://your-guard-rules-bucket/guard-output/`).
3. Look for report files with timestamps corresponding to your stack operations.
4. Download and review the reports to see detailed Guard rule evaluation results:

**Example successful validation report (JSON format)**:
```json
{
  "summary": {
    "status": "PASS",
    "rules_evaluated": 4,
    "rules_passed": 4,
    "rules_failed": 0
  },
  "rules": [
    {
      "rule_name": "s3_versioning_enabled",
      "status": "PASS",
      "message": "S3 bucket has versioning enabled"
    },
    {
      "rule_name": "s3_public_access_blocked",
      "status": "PASS", 
      "message": "S3 bucket has public access blocked"
    },
    {
      "rule_name": "s3_encryption_enabled",
      "status": "PASS",
      "message": "S3 bucket has server-side encryption enabled"
    },
    {
      "rule_name": "s3_no_public_read",
      "status": "PASS",
      "message": "S3 bucket does not allow public read access"
    }
  ]
}
```

**Example failed validation report**:
```json
{
  "summary": {
    "status": "FAIL",
    "rules_evaluated": 4,
    "rules_passed": 1,
    "rules_failed": 3
  },
  "rules": [
    {
      "rule_name": "s3_versioning_enabled",
      "status": "FAIL",
      "message": "S3 bucket does not have versioning enabled"
    },
    {
      "rule_name": "s3_public_access_blocked",
      "status": "FAIL",
      "message": "S3 bucket does not have public access blocked"
    },
    {
      "rule_name": "s3_encryption_enabled",
      "status": "FAIL",
      "message": "S3 bucket does not have server-side encryption enabled"
    },
    {
      "rule_name": "s3_no_public_read",
      "status": "PASS",
      "message": "S3 bucket does not allow public read access"
    }
  ]
}
```

**Congratulations! You have successfully tested and validated your Guard Hook for S3 configurations.**

The Guard Hook demonstrates how policy-as-code can be implemented using declarative Guard rules instead of custom Lambda functions, providing a more maintainable and readable approach to infrastructure compliance validation.
