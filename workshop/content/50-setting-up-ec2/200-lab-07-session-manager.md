---
title: "Lab 07: SSM - Session Manager"
date: 2019-11-08T11:23:07Z
weight: 200
---

#### Overview

[Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) is a fully managed 
AWS Systems Manager capability that lets you manage your Amazon EC2 instances through an interactive one-click 
browser-based shell or through the AWS CLI.

Session Manager has several benefits over using SSH:

+ No need to manage SSH keys.
+ No need to open up any inbound ports in Security Groups.
+ You can use IAM policies and users to control access to your instances.
+ Commands and responses can be logged to Amazon CloudWatch and to an S3 bucket.

#### How it works?

1. The administrator authenticates against IAM.
1. IAM authorizes to start a session for an EC2 instance (IAM policy).
1. The administrator uses the AWS Management Console or the terminal (AWS CLI and additional plugin required) to 
   start a session via the Systems Manager.
1. The Systems Manager agent running on the EC2 instance connects to the AWS Systems Manager service
   and executes commands on the machine. Therefore, the EC2 instance needs access to the Internet or a VPC endpoint.
1. The Session Manager sends audit logs to CloudWatch Logs or S3.

![ssm](/50-setting-up-ec2/ssm-sm-1.png)

#### Configuration

##### 1. Install the AWS Systems Manager agent on EC2 instance

You can proceed to the next step as SSM Agent is pre-installed on Amazon Linux AMIs. For other operating systems 
  please refer to AWS Documentation - [Working with SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)

##### 2. Create an IAM role for the EC2 instance which grants access to the AWS Systems Manager

The AWS managed policy, `AmazonSSMManagedInstanceCore`, allows an instance to use AWS Systems Manager service core functionality.
  
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

##### 4. Attach the IAM Instance Profile to an Amazon EC2 Instance

```yaml
      IamInstanceProfile: !Ref EC2InstanceProfile
```

{{% notice note %}}
You can attach the instance profile to new Amazon EC2 instances when you launch them, or to existing Amazon EC2 instances.
{{% /notice %}}
  
#### Exercise

Log in to instance using SSM Session manager. Retrieve AMI ID from instance metadata using `curl`

{{%expand "Need a hint?" %}}
Check out the AWS Documentation [Instance Metadata and User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html?shortFooter=true#instancedata-data-retrieval).
{{% /expand %}}

{{%expand "Want to see the solution?" %}}
![ssm-sm](/50-setting-up-ec2/ssm-sm-1.gif)
{{% /expand %}}
  
**Congratulations! You have configured Session Manager and now have access to your EC2 instance.**

{{% notice warning %}}
Further configuration should be done, if intended to use SSM Session Manager outside of this workshop. See recommendations
See recommendations and documentation links below for further details.
{{% /notice %}}

##### Recommendations:

+ Use IAM policies to restrict which IAM user or role can start a session with an EC2 instance.
+ Configure Amazon CloudWatch Logs and/or S3 bucket to audit logs.
+ Use IAM policies to make sure IAM users are not able to modify the audit log settings.

Please refer to [Setting Up AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html)
documentation.


