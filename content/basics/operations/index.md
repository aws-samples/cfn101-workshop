---
title: "Operations"
weight: 20
---

![ec2-png](/static/basics/operations/ec2-1.png)

In the previous chapter, you learnt the CloudFormation fundamentals and about various _Template_ sections.

You have created an EC2 instance with Elastic IP. This is a simplistic scenario.

In this chapter you will improve the existing template with the following features:

+ Use Systems Manager Parameter Store to deploy the latest Amazon Linux 2 AMI in any region.
+ Attach an IAM role to the instance and login to it using SSM Session Manager.
+ Bootstrap the instance using a _UserData_ script.
+ Use `cfn-init` to assist bootstrapping an EC2 instance.

---

### Workshop topics covered:

::children
