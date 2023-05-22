---
title: "User data"
weight: 300
---

_Lab Duration: ~10 minutes_

---

### Overview

You can use AWS CloudFormation to automatically install, configure, and start applications on Amazon EC2 instances. Doing
so enables you to easily replicate deployments and update existing installations without connecting directly to the
instance, which can save you a lot of time and effort.

### Topics Covered
In this lab you will deploy an Apache Web server with a simple PHP application via **[UserData](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)** property.

+ First, you will bootstrap EC2 instance to install web server and content.
+ Then you will create an EC2 **Security Group** and allow access on port 80 to the instance.
+ Finally, you will view the content served by the web server.

The following diagram provides a high-level overview of the architecture you will implement.

![user-data-png](/static/basics/operations/user-data/userdata.png)

### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `user-data.yaml` file.
1. Copy the code as you go through the topics below.

#### 1. Create Security Group

Begin by creating a Security Group.

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=75}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
:::

As the Apache web server will serve content on port 80, you will need to create an ingress rule `SecurityGroupIngress`
in the security group to allow access from the Internet.

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=79 highlightLines=83-87}
WebServerSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: 'Enable HTTP access via port 80'
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
:::

Finally, associate the security group with the EC2 instance.

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=63 highlightLines=69-70}
WebServerInstance:
  Type: AWS::EC2::Instance
  Properties:
    IamInstanceProfile: !Ref EC2InstanceProfile
    ImageId: !Ref AmiID
    InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
    SecurityGroupIds:
      - !Ref WebServerSecurityGroup
    Tags:
      - Key: Name
        Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
:::

:::alert{type="info"}
The EC2 instance in the CloudFormation stack will be _replaced_ as a result of modifying the _Security Group_ property.
You can find the properties where updates require [Replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement)
of EC2 instances [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties).
:::

#### 2. Install Apache web server on the instance

Now, let's write a bash script to install the Apache and the PHP application.

:::alert{type="info"}
User data scripts are executed as the **root** user, so there is no need to use `sudo` commands in the script.\
**UserData** must be Base64 encoded when passed from CloudFormation to EC2 instance. Use `Fn::Base64` intrinsic function to encode the input string.
:::

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=74}
UserData:
  Fn::Base64: |
    #!/bin/bash
    yum update -y
    yum install -y httpd php
    systemctl start httpd
    systemctl enable httpd
    usermod -a -G apache ec2-user
    chown -R ec2-user:apache /var/www
    chmod 2775 /var/www
    find /var/www -type d -exec chmod 2775 {} \;
    find /var/www -type f -exec chmod 0664 {} \;
    # PHP script to display Instance ID and Availability Zone
    cat << 'EOF' > /var/www/html/index.php
      <!DOCTYPE html>
      <html>
      <body>
        <center>
          <?php
          # Get the instance ID from meta-data and store it in the $instance_id variable
          $url = "http://169.254.169.254/latest/meta-data/instance-id";
          $instance_id = file_get_contents($url);
          # Get the instance's availability zone from metadata and store it in the $zone variable
          $url = "http://169.254.169.254/latest/meta-data/placement/availability-zone";
          $zone = file_get_contents($url);
          ?>
          <h2>EC2 Instance ID: <?php echo $instance_id ?></h2>
          <h2>Availability Zone: <?php echo $zone ?></h2>
        </center>
      </body>
      </html>
    EOF
:::

#### 3. Add the **WebsiteURL** to CloudFormation _Outputs_

Copy and paste the code below to the _Outputs_ section of the CloudFormation template.

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=132}
WebsiteURL:
  Value: !Sub http://${WebServerEIP}
  Description: Application URL
:::

#### 4. Create the Stack

Similar to previous labs, create the stack with the updated template. Once CloudFormation completes creating the stack,
you can then check to see that your script has set up a web server on the EC2 instance.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to create the stack. The required parameters `--stack-name`, `--template-body` and `--capabilities` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name cfn-workshop-user-data \
--template-body file://user-data.yaml \
--capabilities CAPABILITY_IAM
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=json showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-user-data/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Choose **Create stack** _With new resources (Standard)_ from the top-right side of the page.
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, choose **Upload a template file**.
1. Choose the **Choose file** button and navigate to your workshop directory.
1. Select the file `user-data.yaml` and click **Next**.
1. Provide a **Stack name**. For example `cfn-workshop-user-data`.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** leave the selected environment in.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Submit**.
1. Wait for stack status to reach the **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
::::
:::::

In a web browser, enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).

![outputs](/static/basics/operations/user-data/outputs-1.png)

You should see a page similar to the picture below:

![php-page](/static/basics/operations/user-data/php.png)

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-user-data`.
1. In the top right corner, select **Delete**.
1. In the pop-up window, select **Delete**.
1. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---

### Conclusion

Congratulations, you have successfully bootstrapped an EC2 instance! In the next section you will learn a different way
to install software and start services on Amazon EC2 - CloudFormation _Helper Scripts_.
