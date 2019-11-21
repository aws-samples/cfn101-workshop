---
title: "Lab 08: User Data"
date: 2019-11-13T16:52:42Z
weight: 300
---

>You can use AWS CloudFormation to automatically install, configure, and start applications on Amazon EC2 instances. 
Doing so enables you to easily duplicate deployments and update existing installations without connecting directly to 
the instance, which can save you a lot of time and effort.

#### Lab Overview
This lab introduces the concept of `UserData`. In this lab you will deploy an Apache Web server with a simple PHP 
application. 

First, you will bootstrap existing EC2 instance to install web server and content. Next, you will create 
an EC2 _Security Group_ and allow access on port 80 to the instance. Finally, you will view the content served by the web 
server.

The following diagram provides high-level overview of the architecture you will implement.

![](/50-launching-ec2/userdata.png)

**Let's go!**

##### 1. Amend your template

Go to your template from previous lab, or you can use the one provided in `code/50-launching-ec2/05-lab08-UserData.yaml`.

##### 2. Create Security Group
  + Lets start by creating a Security Group:
  ```yaml
      # Add Security Group resource here
      WebServerSecurityGroup:
        Type: AWS::EC2::SecurityGroup
        Properties:
          GroupDescription: 'Enable HTTP access via port 80'
          # Add ingress rule to the Security Group
```

  + As the Apache web server will serve content on port 80, add an ingress rule to the security group and open it up to the 
  world:
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

  + finally, associate the security group with the EC2 instance:
  ```yaml
      MyEC2Instance:
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

##### 3. Install Apache web server on the instance:

You will write a bash script to install the application. 
  
  {{% notice note %}}
  Scripts entered as user data are executed as _root_, so do not use `sudo` command in the script.\
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

##### 4. Update CloudFormation stack
Similar to previous labs, update the stack with an updated template. Once the CloudFormation finishes updating the stack,
you can then check to see that your script has completed the tasks.

In a web browser, enter the URL of the instance associated Elastic IP address (you can get the Elastic IP from the
 _Outputs_ tab of the CloudFormation console).

`http://WebServerElasticIP`

You should see the page similar to the picture bellow:

![php-page](/50-launching-ec2/php.png)

Congratulations, you have successfully bootstrap an EC2 instance. In a next section you will look into a different way
to install software and start services on Amazon EC2 - CloudFormation _Helper Scripts_.
