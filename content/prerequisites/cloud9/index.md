---
title: "Setup Cloud9 Environment"
weight: 100
---

## What is Cloud9

AWS Cloud9 is a cloud-based IDE that also offers a command-line terminal. It already comes with AWS CLI, Node.js, AWS CDK Toolkit, and Git installed by default. That's why we strongly recommend you to consider AWS Cloud9 to run this workshop.

## Create a Cloud9 instance

1. Use [Create Cloud9 Environment](https://ap-south-1.console.aws.amazon.com/cloudformation/home?region=ap-south-1#/stacks/quickcreate?templateURL=https://cloudformation-templates-workshop-ap-south-1.s3.amazonaws.com/cloud9_instancestack.yaml&stackName=Cloud9Stack&param_C9InstanceVolumeSize=30) cloudformation template to create a cloud9 instance automatially.


1. Give a unique name to S3 bucket parameter like 'cfn-workshop-01-{AccountId}'

    ![cloud9_params-png](/static/prerequisites/cloud9/s3_bucket_name.png)

1. Leave all others parameters default.

    ![cloud9_params-png](/static/prerequisites/cloud9/cloud9_params.png)

1. Scroll Down to page and click on acknowledgement checkbox as per image below:

    ![acknowledgment-png](/static/prerequisites/cloud9/cloud9_stack_acknowledgement.png)


1. Click On Create Stack Button and wait for Cloud9 Stack creation. It usually takes 5-7 minutes.


1. When the the cloud formation stack creation is successfully completed, Search Cloud9 in AWS Console Services and click on CLoud9 from Search Results.

    ![cloud9_search-png](/static/prerequisites/cloud9/cloud9_search.png)


1.  On Cloud9 Enviornments Home Page, Click on Open for the enviornment which you have just created.

    ![cloud9_env-png](/static/prerequisites/cloud9/cloud9_env.png)


1. You will be presented with the cloud9 editor like below:

    ![cloud9_homepage-png](/static/prerequisites/cloud9/cloud9_homepage.png)


1. You see a terminal area in the bottom, where you will run the requirement commands as you move forward. In the main work area you will open and edit code. AWS Cloud9 already comes with the required command line tools (aws cli, node, cdk, and git)
