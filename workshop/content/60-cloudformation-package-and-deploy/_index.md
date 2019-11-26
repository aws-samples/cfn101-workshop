+++
title = "CloudFormation Package and Deploy"
date = 2019-10-22T12:19:24+01:00
weight = 60
chapter = true
+++

### Package and Deploy

So far, you have deployed CloudFormation templates using the Console. It is also possible to use the AWS CLI to deploy a CloudFormation template. In this chapter, you will use the AWS CLI to deploy a CloudFormation template.

So far, you have deployed a CloudFormation template that is completely standalone – one single YAML file and that’s it. Easy to deploy via AWS Console. However in some cases CFN templates refer to other files, or artifacts. For example Lambda source or ZIP file, nested CloudFormation Template file, or an API definition for API Gateway. These files have to be available in S3 before you can deploy the main CloudFormation template.

In this chapter, you will learn how to package, validate and deploy CloudFormation template using the AWS CLI. 
