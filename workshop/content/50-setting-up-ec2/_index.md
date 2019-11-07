+++
title = "Provisioning EC2"
date = 2019-10-22T12:06:55+01:00
weight = 50
chapter = true
+++

### Chapter 2

![](./ec2-1.png)

In the previous chapter, you have covered CloudFormation fundamentals and learned about various _Template_ sections.

Yu have created empty EC2 instance with Elastic IP, however is is not very realistic scenario.

So in this chapter you will improve the existing template with these features:

+ Use the latest Amazon Linux 2 AMI and deploy in any region using SSM parameter Store.
+ Attach IAM role to the instance and login to it via SSM Session Manager.
+ Bootstrap instance with _UserData_.
+ Use `cfn-init` to handle some of the bootstrap tasks.
