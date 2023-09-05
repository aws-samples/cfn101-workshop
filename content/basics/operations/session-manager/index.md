---
title: "Session manager"
weight: 200
---

_Lab Duration: ~15 minutes_

---

### Overview

[Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) is a fully managed
AWS Systems Manager capability that lets you manage your Amazon EC2 instances through an interactive one-click browser-based terminal or via the AWS CLI.

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

::alert[The EC2 instance needs access to the internet, or a VPC Endpoint for Session Manager to work.]{type="info"}

![ssm](/static/basics/operations/session-manager/ssm-sm-1.png)

### Topics Covered
In this Lab, you will learn:

+ How to create IAM role for the EC2 instance which grants access to the AWS Systems Manager.
+ Attach the IAM role to the EC2 instance.
+ Log in to instance using SSM Session Manager.

### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `session-manager.yaml` file.
1. Copy the code as you go through the topics below.

#### 1. Install the AWS Systems Manager agent on EC2 instance

You can proceed to the next step as SSM Agent is pre-installed on Amazon Linux AMIs. For other operating systems, please
refer to the AWS documentation for [Working with SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)

#### 2. Create an IAM role for the EC2 instance
The AWS managed policy, `AmazonSSMManagedInstanceCore`, allows an instance to use AWS Systems Manager service core
functionality. This will allow you to connect to the EC2 instance using Systems Manager Session Manager.

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

#### 3. Create an IAM Instance Profile

Create Instance profile resource.

```yaml
WebServerInstanceProfile:
  Type: AWS::IAM::InstanceProfile
  Properties:
    Path: /
    Roles:
      - !Ref SSMIAMRole
```

#### 4. Attach the IAM Instance Profile to an Amazon EC2 Instance

Attach the role to the instance with `IamInstanceProfile` property.

```yaml
WebServerInstance:
  Type: AWS::EC2::Instance
  Properties:
    IamInstanceProfile: !Ref WebServerInstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

::alert[You can attach the instance profile to the new Amazon EC2 instances at launch time, or to existing Amazon EC2 instances.]{type="info"}

#### 5. Update the Stack

Go to the AWS console and update your stack with a new template.

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-ec2**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `session-manager.yaml` and click **Next**.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** select the different environment than is listed. For example if you have **Dev** selected, choose **Test** and click **Next**.
:::alert{type="info"}
For System Manager to work, the instance need to meet following conditions:
  \- **Access to the internet, or a VPC Endpoint.** \
  \- **Role attached with correct permission.** \
By changing the environment, instance will be stopped and started again. This will help to start `ssm-agent` which may have timed-out as the role wasn't attached in a previous lab.
:::

1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Update stack**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.

### Challenge

Log in to instance using SSM Session Manager and retrieve the AMI ID from instance metadata using `curl`

::expand[Review the AWS documentation for [Instance Metadata and User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html?shortFooter=true#instancedata-data-retrieval).]{header="Need a hint?"}

:::expand{header="Want to see the solution?"}
Paste the following command inside the instance terminal:

::code[curl http://169.254.169.254/latest/meta-data/ami-id]{language=shell showLineNumbers=false showCopyAction=true}

![ssm-sm](/static/basics/operations/session-manager/ssm-sm-1.gif)
:::

:::alert{type="warning"}
Outside this workshop you should take additional steps to configure and secure access to SSM Session Manager. See
recommendations and documentation link below for further details.
:::

##### Recommendations:

+ Use IAM policies to restrict which IAM user or role can start a session on an EC2 instance.
+ Configure Amazon CloudWatch Logs and/or S3 bucket to audit logs.
+ Use IAM policies to make sure IAM users are not able to modify the audit log settings.

Please refer to the [Setting Up AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html)
documentation.

---
### Conclusion

Congratulations! You have configured Session Manager and now have remote access to your EC2 instance.
