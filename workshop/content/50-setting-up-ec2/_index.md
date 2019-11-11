+++
title = "Setting up an EC2 Instance"
date = 2019-10-22T12:06:55+01:00
weight = 50
chapter = true
+++

### Chapter 2

![](./ec2-1.png)

In the previous chapter, you learnt the CloudFormation fundamentals and about various _Template_ sections.

You have created empty EC2 instance with Elastic IP, however is is not very realistic scenario.

In this chapter you will improve the existing template with these features:

+ Use the latest Amazon Linux 2 AMI and deploy in any region using SSM parameter Store.
+ Attach an IAM role to the instance and login to it using SSM Session Manager.
+ Bootstrap the instance using a _UserData_ script.
+ Use `cfn-init` to handle some of the bootstrap tasks.

{{% children showhidden="false" %}}
