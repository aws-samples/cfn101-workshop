---
title: 'Lab 08: User Data'
date: 2019-11-13T16:52:42Z
weight: 300
---

>You can use AWS CloudFormation to automatically install, configure, and start applications on Amazon EC2 instances. 
Doing so enables you to easily replicate deployments and update existing installations without connecting directly to 
the instance, which can save you a lot of time and effort.

#### Lab Overview
This lab introduces the concept of `UserData`. In this lab you will deploy an Apache Web server with a simple PHP 
application. 

First, you will bootstrap EC2 instance to install web server and content. Then you will create 
an EC2 _Security Group_ and allow access on port 80 to the instance. Finally, you will view the content served by the web 
server.

{{% notice note %}}
The EC2 instance in the CloudFormation stack will be _replaced_ as a result of modifying the _Security Group_ property.
You can find the properties where updates require [Replacement](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html#update-replacement) 
of EC2 instances [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html?shortFooter=true#aws-properties-ec2-instance-properties).
{{% /notice %}}

The following diagram provides a high-level overview of the architecture you will implement.

![](../userdata.png)

**Let's go!**

##### 1. Amend your template

Open your editor with the template from the previous lab, or alternatively you can use the skeleton template provided in `code/50-launching-ec2/05-lab08-UserData.yaml`.

##### 2. Create Security Group
Begin by creating a Security Group:
```yaml
  # Add Security Group resource here
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Enable HTTP access via port 80'
      # Add ingress rule to the Security Group
```

As the Apache web server will serve content on port 80, you will need to create an ingress rule in the security group to allow access from the Internet:
```yaml
# Add Security Group resource here
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Enable HTTP access via port 80'
      # Add ingress rule to the Security Group
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
```

Finally, associate the security group with the EC2 instance:
```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      IamInstanceProfile: !Ref EC2InstanceProfile
      ImageId: !Ref AmiID
      InstanceType: !FindInMap [Environment, InstanceType, !Ref EnvType]
      # Attach SecurityGroup here
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      Tags:
        - Key: Name
          Value: !Join [ ' ', [ !Ref EnvType, Web Server ] ]
```

##### 3. Install Apache web server on the instance

You will write a bash script to install the application. 
  
  {{% notice note %}}
  User data scripts are executed as the _root_ user, so there is no need to use `sudo` commands in the script.\
  _UserData_ must be Base64 encoded when passed from CloudFormation to EC2 instance. Use `Fn::Base64` intrinsic 
  function to encode the input string.
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

##### 4. Add the **WebsiteURL** to CloudFormation _Outputs_

Copy and paste the code below to the _Outputs_ section of the CloudFormation template.

```yaml
    WebsiteURL:
      Value: !Sub http://${WebServerEIP}
      Description: Application URL

```

##### 5. Update CloudFormation stack
Similar to previous labs, update the stack with the updated template. Once CloudFormation completes updating the stack,
you can then check to see that your script has setup a web server on the EC2 instance.

In a web browser, enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).

![outputs](../outputs-1.png)

You should see a page similar to the picture below:

![php-page](../php.png)

---

Congratulations, you have successfully bootstrapped an EC2 instance. In the next section you will learn a different way
to install software and start services on Amazon EC2 - CloudFormation _Helper Scripts_.
