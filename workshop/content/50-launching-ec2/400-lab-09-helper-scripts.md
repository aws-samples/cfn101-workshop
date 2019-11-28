---
title: "Lab 09: Helper Scripts"
date: 2019-11-25T15:08:39Z
weight: 400
---

### Overview
In this lab we will look into CloudFormation [Helper Scripts](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html). 
What you have learned in previous lab is a great starting point. However as you may noticed from your `UserData` example,
procedural scripting is not ideal. You have deployed simple PHP application, but imagine trying to write much more 
complicated app in userdata. That would be very tricky.

To solve this problem, CloudFormation provides Python based helper scripts. These helper scripts make CloudFormation 
a lot more powerful and enable you to fine tune templates to better fit your use case.

The helper scripts come preinstalled on Amazon Linux and can be updated periodically by using `yum install -y aws-cfn-bootstrap`

### Helper Scripts covered
+ [cfn-init](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html) - Used to retrieve and 
  interpret resource metadata, install packages, create files, and start services.

+ [cfn-hup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-hup.html) - Used to check for updates to 
  metadata and execute custom hooks when changes are detected.
  
+ [cfn-signal](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html) - Used to signal when the
  resource or application is ready.


**Let's start...**

#### Configure _Metadata_ section
You need to use `AWS::CloudFormation::Init` type to include metadata on an Amazon EC2 instance. When your template calls 
the `cfn-init` script, the script will look for resources in metadata section. Let's add the metadata to your template:
```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    # Configure Metadata
    Metadata:
      AWS::CloudFormation::Init:
```

#### Configure cfn-init
The configuration of `cfn-init` is separated into sections. The configuration sections are processed in the following
order: packages, groups, users, sources, files, commands, and then services.

{{% notice note %}}
 If you require a different order, separate your sections into different config keys, and then use a [configset](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html?shortFooter=true#aws-resource-init-configsets)
 that specifies the order in which the config keys should be processed.
{{% /notice %}}

##### 1. Install HTTPD and PHP packages
Your instance is running Amazon Linux 2, which is based on the RedHat distribution. You will use `yum` package manager
 to install the packages. 
```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    # Configure Metadata
    Metadata:
      AWS::CloudFormation::Init:
        # Install HTTPD and PHP packages
        config:
          packages:
            yum:
              httpd: []
              php: []
```

##### 2. Create index.php file
Use the _files_ key to create files on the EC2 instance. The content can be either inline in the template or the content 
can be pulled from a URL.
```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    # Configure Metadata
    Metadata:
      AWS::CloudFormation::Init:
        # Install HTTPD and PHP packages
        config:
          packages:
            yum:
              httpd: []
              php: []
          # Create /var/www/html/index.php file
          files:
            /var/www/html/index.php:
              content: |
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
              mode: 000644
              owner: apache
              group: apache
```

##### 3. Enable and start Apache web server
You can use the `services` key to define which services should be enabled or disabled when the instance is launched. On Linux
 systems, this key is supported by using `sysvinit`.
```yaml
  WebServerInstance:
    Type: AWS::EC2::Instance
    # Configure Metadata
    Metadata:
      AWS::CloudFormation::Init:
        # Install HTTPD and PHP packages
        config:
          packages:
            yum:
              httpd: []
              php: []
          # Create /var/www/html/index.php file
          files:
            /var/www/html/index.php:
              content: {...}
              mode: 000644
              owner: apache
              group: apache
          # Enable and start Apache web server
          services:
            sysvinit:
              httpd:
                enabled: true
                ensureRunning: true
```

##### 4. Call `cfn-init` script
The metadata scripts are not executed by default, you need to call `cfn-init` helper script in UserData section to execute it.
In the code below, first update `aws-cfn-bootstrap` to ensure to get latest version of helper scripts. Then, install
the files and packages from metadata.
```yaml
      UserData:
        Fn::Base64:
          !Sub |
            #!/bin/bash -xe
            # Update aws-cfn-bootstrap to the latest
            yum install -y aws-cfn-bootstrap
            # Call cfn-init script to install files and packages
            /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
```
{{% notice note %}}
The intrinsic function `!Sub` will dynamically replace values in `${AWS::StackName}` and `${AWS::Region}` variables.
{{% /notice %}}

#### Configure cfn-hup
It is a good practice to include a `cfn-hup` helper script, with which you can make configuration updates to running 
instances by updating the stack template. For example, you could change the sample PHP application and then run a stack
update to deploy the change. (To see this in action, please refer to the exercise section of this lab.)

1. Add two files to the `files` section of the  `AWS::CloudFormation::Init`:

+ /etc/cfn/cfn-hup.conf
+ /etc/cfn/hooks.d/cfn-auto-reloader.conf

```yaml
          # Create /var/www/html/index.php file
          files:
            /var/www/html/index.php:
              content: {...}
              mode: 000644
              owner: apache
              group: apache
          # Create /etc/cfn/cfn-hup.conf
            /etc/cfn/cfn-hup.conf:
              content: !Sub |
                [main]
                stack=${AWS::StackId}
                region=${AWS::Region}
                interval=1
              mode: 000400
              owner: root
              group: root
          # Create /etc/cfn/hooks.d/cfn-auto-reloader.conf
            /etc/cfn/hooks.d/cfn-auto-reloader.conf:
              content: !Sub |
                [cfn-auto-reloader-hook]
                triggers=post.update
                path=Resources.WebServerInstance.Metadata.AWS::CloudFormation::Init
                action=/opt/aws/bin/cfn-init -s ${AWS::StackName} -r WebServerInstance --region ${AWS::Region}
                runas=root
```

2. Enable and start `cfn-hup` in `services` section of the template.
```yaml
          # Enable and start Apache web server
          services:
            sysvinit:
              httpd:
                enabled: true
                ensureRunning: true
          # Enable and start cfn-hup service
              cfn-hup:
                enabled: true
                ensureRunning: true
                files:
                  - /etc/cfn/cfn-hup.conf
                  - /etc/cfn/hooks.d/cfn-auto-reloader.conf
```

#### Configure cfn-signal and CreationPolicy attribute
Finally, you need a way to instruct AWS CloudFormation to complete stack creation only after all the services 
(such as Apache and cfn-hup) are running and not after all the stack resources are created. 

In other words, AWS CloudFormation sets the status of the stack as _CREATE\_COMPLETE_ after it successfully creates all 
the resources. However, if one or more services failed to start, AWS CloudFormation still sets the stack status as 
_CREATE\_COMPLETE_.

To prevent this you can add a [CreationPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html)
attribute to the instance. In conjunction with the creation policy, you need to run the `cfn-signal` helper 
script to signal AWS CloudFormation when all the applications are installed and configured.

1. Add Creation policy to `WebServerInstance` resource
```yaml
      UserData:
        Fn::Base64:
          !Sub |
            #!/bin/bash -xe
            # Update aws-cfn-bootstrap to the latest
            yum install -y aws-cfn-bootstrap
            # Call cfn-init script to install files and packages
            /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
    # Add Creation policy
    CreationPolicy:
      ResourceSignal:
        Count: 1
        Timeout: PT10M
```

2. Call cfn-signal from UserData parameter
```yaml
      UserData:
        Fn::Base64:
          !Sub |
            #!/bin/bash -xe
            # Update aws-cfn-bootstrap to the latest
            yum install -y aws-cfn-bootstrap
            # Call cfn-init script to install files and packages
            /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
            # Call cfn-signal script to send a signal with exit code 
            /opt/aws/bin/cfn-signal --exit-code $? -s ${AWS::StackName} -r WebServerInstance --region ${AWS::Region}

    CreationPolicy:
      ResourceSignal:
        Count: 1
        Timeout: PT10M
```

#### Update the stack
TODO
To update the stack and apply the changes you have done in `UserData` property, the EC2 instance needs to be replaced. 

1. Create `AvailabilityZone` parameter in the template.
```yaml
Parameters:
  AvailabilityZone:
    Type: AWS::EC2::AvailabilityZone::Name
```

2. Check the availability zone of the deployed Web Server instance.
 
  + Go to https://console.aws.amazon.com/ec2
  + In the left hand pane click _Instances_.
  + Select the `<enviroment Web Server` instance and make a note of the _Availability zone_ value. For example `eu-west-2a`.

3. Update the stack using different availability zone than the current one.

![az-update](/50-launching-ec2/az-update-1.png)

#### Exercise
This exercise will demonstrate, how `cfn-hup` updates the application when you update the stack. You will update index.php file
 to show AMI ID on the page.

##### 1. Modify index.php file 

Locate the `/var/www/html/index.php` in the _files_ section of the EC2 metadata

Add code below to the `<\?php {...} ?>` block:
```php
                    # Get the instance AMI ID and store it in the $ami_id variable
                    $url = "http://169.254.169.254/latest/meta-data/ami-id";
                    $ami_id = file_get_contents($url);
```
Add code bellow to html `<h2>` tags:
```html
                    <h2>AMI ID: <?php echo $ami_id ?></h2>
```
##### 2. Update the stack with a new template:
`cfn-hup` will detect changes in metadata section, and will automatically deploy the new version. 

##### 3. Verify that changes has been deployed successfully
Open a new browser window in private mode and enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).
You should see AMI ID added to the page, simillar to the picture bellow.

![ami-id](/50-launching-ec2/ami-id-1.png)

---

Congratulations, you have successfully bootstrapped an EC2 instance using CloudFormation Helper Scripts. 