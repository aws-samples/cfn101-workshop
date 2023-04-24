---
title: "Use Cloud9 IDE"
weight: 200
---

## What is Cloud9

[AWS Cloud9](https://aws.amazon.com/cloud9/) is a cloud-based IDE that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal. Cloud9 comes prepackaged with essential tools for running this workshop. Since your Cloud9 IDE is cloud-based, you can do labs from your office, home, or anywhere using an internet-connected machine.

We recommend using it to run this workshop because it comes with the necessary set of tools pre-installed. If you prefer to work locally, the next section includes details on how to setup your local development environment.

## Create a Cloud9 instance from AWS Console

1. Create a Cloud9 instance from the **AWS Console** by following the steps from the [Creating an EC2 Environment](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html) guide.
:::alert{type="info"}
We recommend using **us-east-1 (N. Virginia)** as the _AWS Region_ for the workshop.
:::
1. Once created, your instance should be listed on the AWS Cloud9 [Environments](https://console.aws.amazon.com/cloud9/home) page. Click **Open** if not already.
1. You will see a terminal area at the bottom where you will run the commands as you progress through the workshop. In the main work area you will open and edit code and template files. AWS Cloud9 comes with the required command line tools (aws cli, python) pre-installed.
1. There is one tool to update, run below command on terminal to update the **pip** version:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    sudo pip install --upgrade pip
    :::
1. Your workshop development environment is now ready to use!

:::alert{type="info"}
If you have issues using the Cloud9 environment, please see the [Troubleshooting AWS Cloud9](https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html) page in the user guide.
:::
