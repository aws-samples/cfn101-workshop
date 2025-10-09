---
title: "Write Guard rules for Hook"
weight: 610
---

### Write Guard Rules

To ensure that our AWS Guard Hook is functional, we need to create Guard rules that will validate the S3 bucket configurations. These rules will check attributes such as versioning and public access settings before a CloudFormation stack is created or updated.

This guide will walk you through creating Guard rules that enforce S3 security best practices.

Before creating the rules, ensure you have access to the Guard rules directory:

```sh
# clone our repo if you have not already done so.
git clone https://github.com/aws-samples/cfn101-workshop.git

# Navigate to the directory where the Guard rules will be stored
cd cfn101-workshop/code/workspace/hooks/guard_hook
```

#### **Step 1: Understanding Guard Rule Syntax**

Guard rules use a domain-specific language (DSL) to define validation logic. The basic syntax includes:

- **Resources**: Target specific AWS resource types
- **Properties**: Access resource properties for validation
- **Operators**: Use comparison operators like `==`, `!=`, `exists`, etc.
- **Logical operators**: Combine conditions with `and`, `or`, `not`

#### **Step 2: Create S3 Security Guard Rules**

Create a new file called `s3-security-rules.guard` with the following content:

```guard
# S3 Security Guard Rules for CloudFormation Hook
# These rules ensure S3 buckets follow security best practices

# Rule 1: S3 buckets must have versioning enabled
rule s3_versioning_enabled {
    Resources.*[ Type == 'AWS::S3::Bucket' ] {
        Properties {
            VersioningConfiguration exists
            VersioningConfiguration.Status == "Enabled"
        }
    }
}

# Rule 2: S3 buckets must have public access blocked
rule s3_public_access_blocked {
    Resources.*[ Type == 'AWS::S3::Bucket' ] {
        Properties {
            PublicAccessBlockConfiguration exists
            PublicAccessBlockConfiguration.BlockPublicAcls == true
            PublicAccessBlockConfiguration.BlockPublicPolicy == true
            PublicAccessBlockConfiguration.IgnorePublicAcls == true
            PublicAccessBlockConfiguration.RestrictPublicBuckets == true
        }
    }
}

# Rule 3: S3 buckets should have server-side encryption enabled
rule s3_encryption_enabled {
    Resources.*[ Type == 'AWS::S3::Bucket' ] {
        Properties {
            BucketEncryption exists
            BucketEncryption.ServerSideEncryptionConfiguration exists
            BucketEncryption.ServerSideEncryptionConfiguration[*].ServerSideEncryptionByDefault exists
            BucketEncryption.ServerSideEncryptionConfiguration[*].ServerSideEncryptionByDefault.SSEAlgorithm in ["AES256", "aws:kms"]
        }
    }
}

# Rule 4: S3 buckets should not allow public read access
rule s3_no_public_read {
    Resources.*[ Type == 'AWS::S3::Bucket' ] {
        Properties {
            # Ensure no public read permissions in ACL
            when AccessControl exists {
                AccessControl != "PublicRead"
                AccessControl != "PublicReadWrite"
            }
        }
    }
}
```

#### **Step 3: Understanding the Guard Rules**

Let's break down what each rule does:

**Rule 1: S3 Versioning Enabled** - Ensures all S3 buckets have versioning enabled for data protection by checking that `VersioningConfiguration.Status` is set to "Enabled", which protects against accidental deletion or modification of objects.

**Rule 2: Public Access Blocked** - Prevents S3 buckets from being publicly accessible by verifying all four public access block settings are enabled, preventing data breaches from misconfigured public access.

**Rule 3: Encryption Enabled** - Ensures data at rest is encrypted by checking for server-side encryption configuration with AES256 or KMS, protecting sensitive data stored in S3.

**Rule 4: No Public Read Access** - Provides an additional check to prevent public read permissions by ensuring ACL doesn't allow public read or read-write access, preventing unauthorized data access.

#### **Step 4: Test Guard Rules Locally (Optional)**

Before using the rules in a Hook, you can test them locally using the Guard CLI. First, install the Guard CLI for your operating system:

**For macOS and Linux:** Use the installation guide at the [AWS CloudFormation Guard documentation](https://docs.aws.amazon.com/cfn-guard/latest/ug/setting-up-linux.html).

::alert[For Windows installation, follow the detailed steps in the [Windows installation guide](https://docs.aws.amazon.com/cfn-guard/latest/ug/setting-up-windows.html) which includes installing Rust and Cargo, then running `cargo install cfn-guard`.]{type="info"}

Once Guard CLI is installed, create a test CloudFormation template (`test-s3-template.yaml`):

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  TestBucket:
    Type: "AWS::S3::Bucket"
    Properties:
      BucketName: test-bucket-compliant
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
```

3. **Test the rules**:

```bash
cfn-guard validate --rules s3-security-rules.guard --data test-s3-template.yaml
```

To see how Guard validation works with non-compliant resources, try editing the YAML file to make it non-compliant (for example, change `IgnorePublicAcls: true` to `IgnorePublicAcls: false`) and run the validation again. You'll see detailed error output showing exactly which rules failed and why:

```
/path/to/test-s3-template.yaml Status = FAIL
FAILED rules
s3-security-rules.guard/s3_public_access_blocked    FAIL
---
Evaluating data /path/to/test-s3-template.yaml against rules s3-security-rules.guard
Number of non-compliant resources 1
Resource = TestBucket {
  Type      = AWS::S3::Bucket
  Rule = s3_public_access_blocked {
    ALL {
      Check =  PublicAccessBlockConfiguration.IgnorePublicAcls EQUALS  true {
        ComparisonError {
          Error            = Check was not compliant as property value [Path=/Resources/TestBucket/Properties/PublicAccessBlockConfiguration/IgnorePublicAcls[L:11,C:26] Value=false] not equal to value [Path=[L:0,C:0] Value=true].
          PropertyPath    = /Resources/TestBucket/Properties/PublicAccessBlockConfiguration/IgnorePublicAcls[L:11,C:26]
          Operator        = EQUAL
          Value           = false
          ComparedWith    = true
          Code:
                9.      PublicAccessBlockConfiguration:
               10.        BlockPublicAcls: true
               11.        BlockPublicPolicy: true
               12.        IgnorePublicAcls: false
               13.        RestrictPublicBuckets: true
               14.      BucketEncryption:

        }
      }
    }
  }
}
```

This output shows that the `s3_public_access_blocked` rule failed because `IgnorePublicAcls` was set to `false` instead of the required `true` value. The detailed error message includes the exact line number and property path where the violation occurred, making it easy to identify and fix compliance issues.

#### **Step 5: Upload Guard Rules to S3**

Guard Hooks require the rules to be stored in Amazon S3. Before proceeding, ensure you have configured your local AWS credentials.

::alert[Set up your AWS credentials using `aws configure` or by setting up an AWS profile. For detailed guidance, see the [AWS CLI Configuration documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).]{type="info"}

1. **Create an S3 bucket**:

You can create the bucket using the AWS CLI or through the [Amazon S3 Console](https://s3.console.aws.amazon.com/s3/buckets).

**Bucket Naming Suggestion**: Use a unique name like `guard-hook-bucket-<your-name>` (e.g., `guard-hook-bucket-john-doe`)

**Using AWS CLI** (replace with your chosen bucket name):
```bash
export GUARD_BUCKET_NAME="guard-hook-bucket-<your-name>"
aws s3 mb s3://$GUARD_BUCKET_NAME --region us-east-1
```

**Using S3 Console**:
- Navigate to the [Amazon S3 Console](https://s3.console.aws.amazon.com/s3/buckets)
- Click "Create bucket"
- Enter your bucket name: `guard-hook-bucket-<your-name>`
- Select region: `us-east-1`
- **Best Practice**: Keep the default "Block all public access" settings enabled for security
- Click "Create bucket"

2. **Upload the Guard rules file**:

```bash
aws s3 cp s3-security-rules.guard s3://$GUARD_BUCKET_NAME/hooks/s3-security-rules.guard
```

3. **Note the S3 URI** for later use:

```
s3://$GUARD_BUCKET_NAME/hooks/s3-security-rules.guard
```

#### **Step 6: Review Guard Rule Structure**

The Guard rules we created follow this structure:

- **Rule Declaration**: Each rule has a unique name and is declared with the `rule` keyword
- **Resource Selection**: Uses `Resources.*[ Type == 'ResourceType' ]` to target specific resources
- **Property Validation**: Accesses resource properties using dot notation
- **Conditional Logic**: Uses `when` statements for conditional validation
- **Operators**: Employs various operators (`==`, `!=`, `exists`, `in`) for comparisons

These rules will be evaluated by the Guard Hook engine whenever a CloudFormation operation targets S3 buckets, ensuring compliance with your security policies before resources are provisioned.

Now that we've created our Guard rules, let's proceed to prepare the Hook execution role and activate the Guard Hook.

Choose **Next** to continue!
