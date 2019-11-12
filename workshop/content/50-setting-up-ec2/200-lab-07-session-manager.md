---
title: "Lab 07: SSM - Session Manager"
date: 2019-11-08T11:23:07Z
weight: 200
---

#### Overview

[Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) is a fully managed 
AWS Systems Manager capability that lets you manage your Amazon EC2 instances through an interactive one-click 
browser-based shell or through the AWS CLI.

Session Manager has several benefits over the SSH using Bastion host:
+ No need to manage SSH keys.
+ No need to open up any inbound ports in Security Groups.
+ Use IAM policies and users to control access to your instances, and don’t need to distribute SSH keys.
+ Commands and responses can be logged to Amazon CloudWatch and to an S3 bucket.

#### How it works?

1. The administrator authenticates against IAM.
1. IAM authorizes to start a session for an EC2 instance (IAM policy).
1. The administrator uses the AWS Management Console or the terminal (AWS CLI and additional plugin required) to 
   start a session via the Systems Manager.
1. An agent running on the EC2 instance (already installed on Amazon Linux) connects to the Systems Manager’s backend 
   and executes commands on the machine. Therefore, the EC2 instance needs access to the Internet or a VPC endpoint.
1. The Session Manager sends audit logs to CloudWatch Logs or S3.

![ssm](/50-setting-up-ec2/ssm-sm-1.png)

#### Configuration

##### 1. Install the AWS Systems Manager agent on EC2 instance
  You can proceed to the next step as SSM Agent is pre-installed on Amazon Linux AMI. For other operating systems 
  please refer to AWS Documentation - [Working with SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)

##### 2. Create an IAM role for the EC2 instance which grants access to the AWS Systems Manager
  The AWS managed policy, `AmazonSSMManagedInstanceCore`, enables an instance to use AWS Systems Manager service core functionality.
  
  ```yaml
  SSMIAMRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ec2.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  ```
##### 3. Create an IAM Instance Profile
  
```yaml
  EC2InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: /
      Roles:
        - !Ref SSMIAMRole
```

##### 3. Attach an IAM Instance Profile to an Amazon EC2 Instance

```yaml
      IamInstanceProfile: !Ref EC2InstanceProfile
```

{{% notice note %}}
You can attach the instance profile to new Amazon EC2 instances when you launch them, or to existing Amazon EC2 instances.
{{% /notice %}}
  
##### 3. Use IAM policies to restrict which IAM user or role can start a session with an EC2 instance.
##### 4. Configure audit logs.
##### 5. Use IAM policies to make sure engineers are not able to modify the audit log settings.


