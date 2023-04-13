---
title: "Install and configure the AWS CLI | Cloud9 IDE"
weight: 200
---

:::::tabs{variant="container"}
::::tab{id="cli" label="AWS CLI"}
 The [AWS CLI](https://aws.amazon.com/cli/) allows you to interact with AWS services from a terminal session.
 Make sure you have the latest version of the AWS CLI installed on your system.

See the [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
page for installation instructions for your operating system.

## Configure your credentials

Open a terminal window and run `aws configure` to set up your environment.

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws configure
:::

Type the **access key ID** and **secret key** you created in [the previous step](/prerequisites/account) and choose a default region (for example you can use `us-east-1`). Preferably use a region that doesn't have any resources already deployed into it.

:::code{language=shell showLineNumbers=false showCopyAction=false}
AWS Access Key ID [None]: <type key ID here>
AWS Secret Access Key [None]: <type access key>
Default region name [None]: <choose region (e.g. "us-east-1", "eu-west-1")>
Default output format [None]: <leave blank>
:::
::::

::::tab{id="cloud9" label="Cloud 9"}
## What is Cloud9

AWS Cloud9 is a cloud-based IDE that also offers a command-line terminal. It already comes with AWS CLI, Node.js, AWS CDK Toolkit, and Git installed by default. That's why we strongly recommend you to consider AWS Cloud9 to run this workshop.

## Create a Cloud9 instance

1. Download cloud9 template file from [Cloud9 Template](https://github.com/aws-samples/cfn101-workshop/tree/cloud9-cfn-template/code/cloud9/cloud9_instance_stack.yaml)
1. In the CloudFormation console, select **Create stack**, **With new resources (standard)**.
1. In **Prepare template**, select **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Choose the `cloud9_instance_stack.yaml` template downloaed in step 1.
1. Click on Next.
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

::::
:::::
