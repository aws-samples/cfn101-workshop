---
title: "Prepare to create a Guard Hook"
weight: 620
---

### **Introduction**

Before you create a **Guard Hook** for validating **S3 configurations**, we need to complete the following steps to create an execution role with IAM permissions and a trust policy to allow CloudFormation to invoke a Guard Hook.

1. **Upload Guard Rules to S3** – The Guard rules must be stored in S3 for the Hook to access them.
2. **Deploy the CloudFormation Hook Execution Role** – This role allows CloudFormation Hooks to assume permissions for accessing S3 and reading Guard rules.
3. **Register the Hook in AWS CloudFormation** – The Hook will be configured to evaluate S3 resource changes before provisioning.
4. **Attach Hook to a CloudFormation Stack** – This ensures enforcement during stack deployments.

---

### **Step 1: Verify Guard Rules in S3**

Since the Guard rules **s3-security-rules.guard** should already be uploaded to S3, follow these steps to verify the **S3 URI**:

1. **Go to the AWS S3 Console**:

   - Open [AWS S3 Console](https://console.aws.amazon.com/s3).
   - Navigate to your bucket containing the Guard rules.
   - Locate the **s3-security-rules.guard** file.

2. **Copy the S3 URI**:
   - The S3 URI format will be:
     ```
     s3://your-guard-rules-bucket/hooks/s3-security-rules.guard
     ```
   - Copy this URI for use in the next step.

---

### **Step 2: Create CloudFormation for Guard Hook IAM Role**

To enable the **CloudFormation Guard Hook** to validate **S3 configurations** by accessing Guard rules from S3, we must create an IAM role that CloudFormation Hooks can assume. This role ensures that the hook has the necessary permissions to:

**Access S3 Objects**: The hook reads Guard rules from the specified S3 bucket and object.

**Write Output Reports**: Optionally, the hook can write validation reports to an S3 bucket.

By defining a dedicated **IAM role**, we ensure that CloudFormation Hooks can securely perform these operations without requiring excessive permissions across AWS services.

#### **Deploy the Hook Execution Role**

::alert[If you've cloned our repo then you can also find this yaml file in our _cfn101-workshop/code/workspace/hooks/guard-hook-role.yaml_ folder.]{type="info"}

1. Copy the **S3 URI of your Guard rules** from the AWS Management Console.
2. Open **guard-hook-role.yaml** file then replace `<s3-bucket-name>` with your actual bucket name and save the **guard-hook-role.yaml** file:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "IAM role configuration for Guard Hook"

Parameters:
  S3BucketName:
    Type: String
    Default: "<s3-bucket-name>"
    Description: "Name of the S3 bucket containing Guard rules"

Resources:
  GuardHookExecutionRole:
    Type: "AWS::IAM::Role"
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: hooks.cloudformation.amazonaws.com
            Action: "sts:AssumeRole"
      Policies:
        - PolicyName: GuardHookS3Access
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - "s3:ListBucket"
                  - "s3:GetObject"
                  - "s3:GetObjectVersion"
                Resource: 
                  - !Sub "arn:aws:s3:::${S3BucketName}"
                  - !Sub "arn:aws:s3:::${S3BucketName}/*"
              - Effect: Allow
                Action:
                  - "s3:PutObject"
                  - "s3:PutObjectAcl"
                Resource: 
                  - !Sub "arn:aws:s3:::${S3BucketName}/guard-output/*"

Outputs:
  GuardHookExecutionRoleArn:
    Description: "ARN of the Guard Hook execution role"
    Value: !GetAtt GuardHookExecutionRole.Arn
    Export:
      Name: !Sub "${AWS::StackName}-GuardHookExecutionRoleArn"
```

#### **3. Deploy the Hook Role via AWS Console**

1. **Open AWS CloudFormation Console**:

   - Navigate to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation).
   - Click **Create Stack** → **With new resources (standard)**.
   - Upload the modified `guard-hook-role.yaml` file (with the correct S3 bucket name).

2. **Provide Stack Details**:

   - Enter a **stack name** (e.g., `GuardHookExecutionRoleStack`).
   - Update the **S3BucketName** parameter with your actual bucket name.
   - Click **Next**.

3. **Configure Stack Settings**:

   - Leave the default values unless modifications are needed.
   - Click **Next**.

4. **Review and Create**:
   - Acknowledge that CloudFormation might create IAM resources.
   - Click **Create Stack**.

5. **Wait for Deployment Completion**:
   - Navigate to the **Outputs** tab.
   - Look for `GuardHookExecutionRoleArn` and **copy its value** for later use.

---

### **Step 3: Understanding Guard Hook Permissions**

The IAM role we created provides the following permissions:

#### **S3 Read Permissions**
- `s3:ListBucket`: Allows the Hook to list objects in the S3 bucket
- `s3:GetObject`: Enables reading the Guard rules file
- `s3:GetObjectVersion`: Supports versioned S3 objects

#### **S3 Write Permissions (Optional)**
- `s3:PutObject`: Allows writing Guard output reports
- `s3:PutObjectAcl`: Sets appropriate permissions on output files

#### **Trust Policy**
The role trusts the `hooks.cloudformation.amazonaws.com` service, allowing CloudFormation to assume this role when invoking Guard Hooks.

---

### **Step 4: Verify Prerequisites**

Before proceeding to activate the Guard Hook, ensure you have:

1. ✅ **Guard rules file uploaded to S3**
2. ✅ **S3 URI of the Guard rules file**
3. ✅ **IAM execution role created and deployed**
4. ✅ **Execution role ARN copied**

Now, all the preparation is done. The Guard rules are ready in S3, and we have the necessary IAM role for the Guard Hook to function properly.

Choose **Next** to continue!
