---
title: "Helper scripts"
weight: 400
---

_Lab Duration: ~15 minutes_

---

### Overview
In this lab we will look into CloudFormation [Helper Scripts](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html).
What you have learned in a previous lab is a great starting point. However, as you may notice from your `UserData`
example, procedural scripting is not ideal. You have deployed a simple PHP application, but imagine trying to write much
more complicated app in userdata. That would be very tricky.

To solve this problem, CloudFormation provides helper scripts. These helper scripts make CloudFormation a lot more
powerful and enable you to fine tune templates to better fit your use case. For example, you can update application
configuration without recreating an instance.

The helper scripts come pre-installed on Amazon Linux and can be updated periodically by using `yum install -y aws-cfn-bootstrap`

### Topics Covered

In this lab you will learn:

+ How to retrieve and interpret resource metadata, install packages, create files, and start services with [cfn-init](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html)

+ How to check for updates to metadata and execute custom hooks when changes are detected with [cfn-hup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-hup.html)

+ How to send a signal to CloudFormation when the resource or application is ready with [cfn-signal](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html)


### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `helper-scripts.yaml` file.
1. Copy the code as you go through the topics below.

#### 1. Configure _Metadata_ section

You need to use the `AWS::CloudFormation::Init` type to include metadata for an Amazon EC2 instance. When your template
calls the `cfn-init` script, the script will look for resources in metadata section. Let's add the metadata to your template:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
  WebServerInstance:
    Type: AWS::EC2::Instance
    Metadata:
      AWS::CloudFormation::Init:
:::

#### 2. Configure cfn-init
The configuration of `cfn-init` is separated into sections. The configuration sections are processed in the following
order: packages, groups, users, sources, files, commands, and then services.

:::alert{type="info"}
If you require a different order, separate your sections into different config keys, and then use a
[configset](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html?shortFooter=true#aws-resource-init-configsets)
that specifies the order in which the config keys should be processed.
:::

:::alert{type="info"}
It is important to preserve indentation as shown in the code samples below. You can cross-reference your template
against the solution code `code/solutions/helper-scripts.yaml` file.
:::

##### 1. Install HTTPD and PHP packages

Your instance is running Amazon Linux 2, so you will use `yum` package manager to install the packages.

Add the code from `packages` key to your template.

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages:
          yum:
            httpd: []
            php: []
:::

##### 2. Create `index.php` file
Use the _files_ key to create files on the EC2 instance. The content can either be a specified inline in the template,
or as a URL that is retrieved by the instance.

Add the code from `files` key to your template.

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages: \
          {...}
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
:::

##### 3. Enable and start Apache web server

You can use the `services` key to define which services should be enabled or disabled when the instance is launched. On
Linux systems, this key is supported by using the `sysvinit` key.

Add the code from `services` key to your template.

:::code{language=yaml showLineNumbers=false showCopyAction=true}
WebServerInstance:
  Type: AWS::EC2::Instance
  Metadata:
    AWS::CloudFormation::Init:
      config:
        packages:
          {...}
        files:
          {...}
        services:
          sysvinit:
            httpd:
              enabled: true
              ensureRunning: true
:::

##### 4. Call `cfn-init` script

The metadata scripts are not executed by default, you need to call `cfn-init` helper script in UserData section to execute it.

In the code below, CloudFormation will first update the `aws-cfn-bootstrap` package to retrieve the latest version of the
helper scripts. Then, it will install the files and packages from metadata.

Add the code from `UserData` property to your template.

:::code{language=yaml showLineNumbers=false showCopyAction=true}
UserData:
  Fn::Base64:
    !Sub |
      #!/bin/bash -xe
      # Update aws-cfn-bootstrap to the latest
      yum install -y aws-cfn-bootstrap
      # Call cfn-init script to install files and packages
      /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
:::

::alert[The intrinsic function `!Sub` will dynamically replace values in `${AWS::StackName}` and `${AWS::Region}` variables.]{type="info"}

#### 3. Configure cfn-hup

Installing the `cfn-hup` helper script enables existing EC2 instances to apply template updates of _UserData_.
For example, you could change the sample PHP application in the template and deploy this by updating the existing stack.
Without using `cfn-hup`, you would need to either replace the EC2 instance or manually apply the update outside of
CloudFormation. (To see this in action, please refer to the exercise section of this lab.)

1. Add two files to the `files` section of the  `AWS::CloudFormation::Init`:

    + /etc/cfn/cfn-hup.conf
    + /etc/cfn/hooks.d/cfn-auto-reloader.conf

1. Copy the code from both files to your template.

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   WebServerInstance:
     Type: AWS::EC2::Instance
     Metadata:
       AWS::CloudFormation::Init:
         config:
           packages:
             {...}
           files:
             /var/www/html/index.php:
               {...}
             /etc/cfn/cfn-hup.conf:
               content: !Sub |
                 [main]
                 stack=${AWS::StackId}
                 region=${AWS::Region}
                 interval=1
               mode: 000400
               owner: root
               group: root
             /etc/cfn/hooks.d/cfn-auto-reloader.conf:
               content: !Sub |
                 [cfn-auto-reloader-hook]
                 triggers=post.update
                 path=Resources.WebServerInstance.Metadata.AWS::CloudFormation::Init
                 action=/opt/aws/bin/cfn-init --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
                 runas=root
           services:
             {...}
   :::

1. Enable and start `cfn-hup` in `services` section of the template.

   Add the code from `services` key to your template.

   :::code{language=yaml showLineNumbers=false showCopyAction=true}
   WebServerInstance:
     Type: AWS::EC2::Instance
     Metadata:
       AWS::CloudFormation::Init:
         config:
           packages:
             {...}
           files:
             /var/www/html/index.php:
               {...}
             /etc/cfn/cfn-hup.conf:
                 {...}
             /etc/cfn/hooks.d/cfn-auto-reloader.conf:
                 {...}
           services:
             sysvinit:
               httpd:
                 enabled: true
                 ensureRunning: true
               cfn-hup:
                 enabled: true
                 ensureRunning: true
                 files:
                   - /etc/cfn/cfn-hup.conf
                   - /etc/cfn/hooks.d/cfn-auto-reloader.conf
    :::

#### 4. Configure cfn-signal and CreationPolicy attribute
Finally, you need a way to instruct AWS CloudFormation to complete stack creation only after all the services
(such as Apache and cfn-hup) are running and not after all the stack resources are created.

In other words, AWS CloudFormation sets the status of the stack as _CREATE\_COMPLETE_ after it successfully creates all
the resources. However, if one or more services failed to start, AWS CloudFormation still sets the stack status as _CREATE\_COMPLETE_.

To prevent this you can add a [CreationPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html)
attribute to the instance. In conjunction with the creation policy, you need to run the `cfn-signal` helper script to
notify AWS CloudFormation when all the applications are installed and configured.

1. Add Creation policy to `WebServerInstance` resource property.

    :::code{language=yaml showLineNumbers=false showCopyAction=true}
   CreationPolicy:
     ResourceSignal:
       Count: 1
       Timeout: PT10M
    :::

1. Add the `cfn-signal` to the UserData parameter.

    :::code{language=yaml showLineNumbers=false showCopyAction=true}
   UserData:
    Fn::Base64:
      !Sub |
        #!/bin/bash -xe
        # Update aws-cfn-bootstrap to the latest
        yum install -y aws-cfn-bootstrap
        # Call cfn-init script to install files and packages
        /opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
        # Call cfn-signal script to send a signal with exit code
        /opt/aws/bin/cfn-signal --exit-code $? --stack ${AWS::StackName} --resource WebServerInstance --region ${AWS::Region}
    :::

#### 5. Create the stack
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
  aws cloudformation create-stack --stack-name cfn-workshop-helper-scripts \
  --template-body file://helper-scripts.yaml \
  --capabilities CAPABILITY_IAM
  :::
  1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-helper-scripts/96d87030-e809-11ed-a82c-0eb19aaeb30f"
  :::
  1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
  1. Verify the new instance was deployed and is functional. In a web browser, enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. In the CloudFormation console, select *Create stack With new resources (standard)*.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Select the file `helper-scripts.yaml` and click **Next**.
1. Enter a **Stack name**. For example, choose to specify `cfn-workshop-helper-scripts`.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** select the environment from drop down list, for example **Test** and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Submit**.
1. Wait for stack status to reach **CREATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
1. Verify the new instance was deployed and is functional. In a web browser, enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).
::::
:::::

#### Challenge

This exercise will demonstrate how `cfn-hup` updates the application when you update the stack. You will update `index.php` file
 to show AMI ID on the page.

##### 1. Modify `index.php` file

Locate the `/var/www/html/index.php` in the _files_ section of the EC2 metadata

Add the code below to the `<\?php {...} ?>` block:

:::code{language=php showLineNumbers=false showCopyAction=true}
# Get the instance AMI ID and store it in the $ami_id variable
$url = "http://169.254.169.254/latest/meta-data/ami-id";
$ami_id = file_get_contents($url);
:::

Add the code below to html `<h2>` tags:

:::code{language=html showLineNumbers=false showCopyAction=true}
<h2>AMI ID: <?php echo $ami_id ?></h2>
:::

##### 2. Update the stack with a new template:

`cfn-hup` will detect changes in metadata section, and will automatically deploy the new version, updating the current EC2 instance.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to update the stack. The required parameters have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name cfn-workshop-helper-scripts \
--template-body file://helper-scripts.yaml \
--capabilities CAPABILITY_IAM
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-helper-scripts/96d87030-e809-11ed-a82c-0eb19aaeb30f"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and wait for stack status to reach **UPDATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status. This should be quick as a new EC2 instance is not being launched.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example `cfn-workshop-helper-scripts`.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `helper-scripts.yaml` and click **Next**.
1. For **Amazon Machine Image ID** leave the default value in.
1. For **EnvironmentType** leave the selected environment in.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and tick **I acknowledge that AWS CloudFormation might create IAM resources** check box, then click on **Submit**.
1. Wait for stack status to reach **UPDATE_COMPLETE**. You need to periodically select Refresh to see the latest stack status.
::::
:::::

##### 3. Verify that changes have been deployed successfully

Open a new browser window in private mode and enter the `WebsiteURL` (you can get the WebsiteURL from the _Outputs_ tab of the CloudFormation console).
You should see the AMI ID added to the page, similar to the picture below.

![ami-id](/static/basics/operations/helper-scripts/ami-id-1.png)

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-helper-scripts`.
1. In the top right corner, click on **Delete**.
1. In the pop-up window click on **Delete**.
2. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select Refresh to see the latest stack status.

---

### Conclusion

Congratulations, you have successfully bootstrapped an EC2 instance using CloudFormation Helper Scripts.
