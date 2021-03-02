---
title: 'Lab 08: User Data'
date: 2019-11-13T16:52:42Z
weight: 300
---

### Overview

You can use AWS CloudFormation to automatically install, configure, and start applications on Amazon EC2 instances. Doing so enables you to easily replicate deployments and update existing installations without connecting directly to the instance, which can save you a lot of time and effort.

### Topics Covered
In this lab you will deploy an Apache Web server with a simple PHP application via **[UserData](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)** property.

+ First, you will bootstrap EC2 instance to install web server and content.
+ Then you will create an EC2 **Security Group** and allow access on port 80 to the instance.
+ Finally, you will view the content served by the web server.

The following diagram provides a high-level overview of the architecture you will implement.

![user-data-png](300-lab-08-user-data/userdata.png)

### Start Lab

1. Go to the `code/30-launching-ec2/` directory.
1. Open the `05-lab08-UserData.yaml` file.
1. Copy the code as you go through the topics below.

#### 1. Create Security Group

Begin by creating a Security Group.

```yaml
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Enable HTTP access via port 80'
```
As the Apache web server will serve content on port 80, you will need to create an ingress rule `SecurityGroupIngress` in the security group to allow access from the Internet.

```yaml
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Enable HTTP access via port 80'
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
```

Finally, associate the security group with the EC2 instance.

```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      IamInstanceProfile: !Ref EC2InstanceProfile
      ImageId: !Ref AmiID
      InstanceType: !FindInMap [Environment, InstanceType, !Ref EnvType]
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      Tags:
        - Key: Name
          Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]
```

{{% notice note %}}
The EC2 instance in the CloudFormation stack will be _replaced_ as a result of modifying the _Security Group_ property. You can find the properties where updates require [Replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) of EC2 instances [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties).
{{% /notice %}}

#### 2. Install Apache web server on the instance

Now, let's write a bash script to install the Apache and the PHP application.

{{% notice note %}}
User data scripts are executed as the **root** user, so there is no need to use `sudo` commands in the script.\
**UserData** must be Base64 encoded when passed from CloudFormation to EC2 instance. Use `Fn::Base64` intrinsic function to encode the input string.
{{% /notice %}}

```yaml
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
```

#### 3. Add the **WebsiteURL** to CloudFormation _Outputs_

Copy and paste the code below to the _Outputs_ section of the CloudFormation template.

```yaml
  WebsiteURL:
    Value: !Sub http://${WebServerEIP}
    Description: Application URL
```

#### 4. Update the Stack

Similar to previous labs, update the stack with the updated template. Once CloudFormation completes updating the stack, you can then check to see that your script has set up a web server on the EC2 instance.

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-ec2**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `05-lab08-UserData.yaml` and click **Next**.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** leave the selected environment in.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Update stack**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.

In a web browser, enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).

![outputs](300-lab-08-user-data/outputs-1.png)

You should see a page similar to the picture below:

![php-page](300-lab-08-user-data/php.png)

---

### Conclusion

Congratulations, you have successfully bootstrapped an EC2 instance! In the next section you will learn a different way
to install software and start services on Amazon EC2 - CloudFormation _Helper Scripts_.
