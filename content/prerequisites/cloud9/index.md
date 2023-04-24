---
title: "Use Cloud9 IDE"
weight: 200
---

## What is Cloud9

[AWS Cloud9](https://aws.amazon.com/cloud9/) is a cloud-based IDE that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal. Since your Cloud9 IDE is cloud-based, you can do labs from your office, home, or anywhere using an internet-connected machine. Cloud9 comes prepackaged with all the essential tools required for running this workshop:

* Python
* pip
* awscli

For the best experience with the workshop and minimal setup effort we recommend using it to run this workshop because it comes with the necessary set of tools pre-installed. If you prefer to work locally, the next section includes details on how to setup your local development environment.

## Create a Cloud9 instance from AWS Console

1. Create a Cloud9 instance from the **AWS Console** by following the steps from the [Creating an EC2 Environment](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html) guide.
:::alert{type="info"}
We recommend using **us-east-1 (N. Virginia)** as the _AWS Region_ for the workshop.
:::
1. Once created, your instance should be listed on the AWS Cloud9 [Environments](https://console.aws.amazon.com/cloud9/home) page. Click **Open** if not already.
1. You will see a terminal area at the bottom where you will run the commands as you progress through the workshop. In the main work area you will open and edit code and template files.
1. There is one tool to update, run below command on terminal to update the **pip** version:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    pip install --upgrade pip
    :::
1. Run below command to test aws cli is working:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws s3 ls
    :::
    Above command should returns list of s3 buckets in your account

1. Your workshop development environment is now ready to use!

:::alert{type="info"}
If you have issues using the Cloud9 environment, please see the [Troubleshooting AWS Cloud9](https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html) page in the user guide.
:::

## Clone lab resources using git
Clone the repository to your working directory:

:::code{language=shell showLineNumbers=false showCopyAction=true}
git clone https://github.com/aws-samples/cfn101-workshop
:::

## Or Download ZIP file manually (optional)
1. Download the ZIP file from [the GitHub repository page](https://github.com/aws-samples/cfn101-workshop):

![git-download-png](/static/prerequisites/git/git-download.png)

1. Extract the contents of the zip file.
1. Upload the zip file to your environment selecting the **File** menu, **Upload Local Files...** and **Selecting folder** that you extracted.
1. Wait for the upload to complete, the progress should be displayed in the lower-left corner.

## Open workshop files
The templates and code you will work on is located in the **code** folder.
Expand the tree on the left to open the **code** folder:

![toggletree-png](/static/prerequisites/cloud9/toggletree.png)
