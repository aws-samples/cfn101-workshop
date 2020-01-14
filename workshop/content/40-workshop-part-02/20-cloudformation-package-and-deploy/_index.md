+++
title = "CloudFormation Package and Deploy"
date = 2019-10-22T12:19:24+01:00
weight = 70
chapter = true
+++

# Package and Deploy

{{% notice warning %}} 
Hi there, thank you for the interest in the CFN201 - Workshop. Currently the Part 02 of the workshop is under development.
{{% /notice %}}

So far, you have deployed CloudFormation templates using the Console. It is also possible to use the AWS CLI to deploy a CloudFormation template. In this chapter, you will use the AWS CLI to deploy a CloudFormation template.

The CloudFormation template you have built is completely standalone – one single YAML file and that’s it. It is easy to deploy via AWS Console. 

CFN templates can refer to other files, or artifacts. For example Lambda source code, a ZIP file, nested CloudFormation Template file, or an API definition for API Gateway. 
These files have to be available in S3 before you can deploy the main CloudFormation template.

In this chapter, you will learn how to package, validate and deploy CloudFormation template using the AWS CLI. 
