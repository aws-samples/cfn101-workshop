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

  + finally, associate security group with EC2 instance:
  ```yaml
      MyEC2Instance:
        Type: AWS::EC2::Instance
        Properties:
          IamInstanceProfile: !Ref EC2InstanceProfile
          ImageId: !Ref AmiID
          InstanceType: !FindInMap [Environment, InstanceType, !Ref EnvType]
          # Attach SecurityGroup here
          SecurityGroups:
            - !Ref WebServerSecurityGroup
          Tags:
            - Key: Name
              Value: !Join [ ' ', [ !Ref EnvType, Web Server ] ]
```

##### 3. Install Apache web server on the instance:

You will write bash script to install the application. 
  
  {{% notice note %}}
  Scripts entered as user data are executed as `root`, so do not use `sudo` command in the script.
  The _UserData_ needs to be Base64 encoded.
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
      echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
```

The script above configures the following:
**TODO**

  {{% notice warning %}}
  In order to replace an instance, you need to modify a property that forces it to replace it. 
  If you trying to update stack only after changing a "userdata" property it will not replace an instance, hence the 
  instance will not be bootstrapped with it.
  Look for "replacement" here.
  http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html
  {{% /notice %}}
  
#### Exercise
**TODO**
Create /var/www/html/index.html file and display instance ID by using curl and instance metadata.

Congratulations, you have successfully bootstrap an EC2 instance. In a next section you will look into CloudFormation 
helper scripts to improve your bash script further.


  
