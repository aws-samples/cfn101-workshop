---
title: "Use Cloud9 IDE"
weight: 200
---

## What is Cloud9

AWS Cloud9 is a cloud-based IDE that also offers a command-line terminal. It already comes with AWS CLI, Node.js, AWS CDK Toolkit, and Git installed by default. That's why we strongly recommend you to consider AWS Cloud9 to run this workshop. You can configure a cloud watch instance from aws console as well using aws cloud formation.

## Create a Cloud9 instance from AWS Console

Create a cloud9 instance from console by following step from [Create Cloud9 Enviornment using AWS Console](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html) guide.

## Create a Cloud9 instance from cloudformation

1. Download cloud9 template file from [Cloud9 Template](https://github.com/aws-samples/cfn101-workshop/tree/cloud9-cfn-template/code/cloud9/cloud9_instance_stack.yaml)
1. In the CloudFormation console, select **Create stack**, **With new resources (standard)**.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `cloud9_instance_stack.yaml` template downloaed in step 1.
1. Click on Next.
1. Give a unique name to S3 bucket parameter like 'cfn-workshop-01-{AccountId}
1. Leave all others parameters default.
1. Scroll Down to page and click on acknowledgement checkbox.
1. Click On Create Stack Button and wait for Cloud9 Stack creation. It usually takes 5-7 minutes.
1. When the the cloud formation stack creation is successfully completed, Search Cloud9 in AWS Console Services and click on CLoud9 from Search Results.
1. On Cloud9 Enviornments Home Page, Click on Open for the enviornment which you have just created.
1. You will see a terminal area in the bottom, where you will run the requirement commands as you move forward. In the main work area you will open and edit code. AWS Cloud9 already comes with the required command line tools (aws cli, python)
1. Run below command on terminal to update pip version:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    sudo pip install --upgrade pip
    :::
