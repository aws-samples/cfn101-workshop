---
title: "Lab 07: SSM - Session Manager"
date: 2019-11-08T11:23:07Z
weight: 200
---

#### Overview

[Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) is a fully managed 
AWS Systems Manager capability that lets you manage your Amazon EC2 instances through an interactive one-click 
browser-based terminal or via the AWS CLI.

Session Manager has several benefits over using SSH:

+ No need to manage SSH keys.
+ No need to open up any inbound ports in Security Groups.
+ You can use IAM policies and users to control access to your instances.
+ Commands and responses can be logged to Amazon CloudWatch and to an S3 bucket.

#### How Session Manager works

1. The administrator authenticates against IAM.
1. IAM authorizes to start a session on an EC2 instance by evaluating applicable IAM policies.
1. The administrator uses the AWS Management Console or the terminal (AWS CLI and additional plugin required) to 
   start a session via Systems Manager.
1. The Systems Manager agent running on the EC2 instance connects to the AWS Systems Manager service
   and executes the commands on the instance.
1. The Session Manager sends audit logs to CloudWatch Logs or S3.

> The EC2 instance needs access to the internet or a VPC Endpoints for Session Manager to work. 

![ssm](/50-launching-ec2/ssm-sm-1.png)

#### Configuration

##### 1. Install the AWS Systems Manager agent on EC2 instance

You can proceed to the next step as SSM Agent is pre-installed on Amazon Linux AMIs. For other operating systems 
  please refer to the AWS documentation for [Working with SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)

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
You can attach the instance profile to new Amazon EC2 instances at launch time, or to existing Amazon EC2 instances.
{{% /notice %}}

##### 5. Update the Stack
  Go to the AWS console and update the _Stack_ with updated template.
  
#### Exercise

Log in to instance using SSM Session Manager and retrieve the AMI ID from instance metadata using `curl`

{{%expand "Need a hint?" %}}
Review the AWS documentation for [Instance Metadata and User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html?shortFooter=true#instancedata-data-retrieval).
{{% /expand %}}

{{%expand "Want to see the solution?" %}}
![ssm-sm](/50-launching-ec2/ssm-sm-1.gif)
{{% /expand %}}
  
**Congratulations! You have configured Session Manager and now have access to your EC2 instance.**

{{% notice warning %}}
Outside of this workshop you should take additional steps to configure and secure access to SSM Session Manager.
See recommendations and documentation links below for further details.
{{% /notice %}}

##### Recommendations:

+ Use IAM policies to restrict which IAM user or role can start a session on an EC2 instance.
+ Configure Amazon CloudWatch Logs and/or S3 bucket to audit logs.
+ Use IAM policies to make sure IAM users are not able to modify the audit log settings.

Please refer to the [Setting Up AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html)
documentation.


