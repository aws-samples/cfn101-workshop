---
title: "AWS Cloud9 Setup (Recommended)"
weight: 200
---

_Lab Duration: ~10 minutes_

## Overview

[AWS Cloud9](https://aws.amazon.com/cloud9/) is a cloud-based IDE that lets you write, run, and debug your code with
just a browser. It includes a code editor, debugger, and terminal. Since your Cloud9 IDE is cloud-based, you can do labs
from your office, home, or anywhere using an internet-connected machine.

For the best experience with the workshop and minimal setup effort we recommend using it to run this workshop because it
comes with the necessary set of tools pre-installed. If you prefer to work locally, follow the
[Local Development Setup](/prerequisites/local-development) instead.

:::alert{type="info"}
We recommend using **us-east-1 (N. Virginia)** as the _AWS Region_ for the workshop.
:::

## Create a Cloud9 instance from AWS Console

1. Create a Cloud9 instance from the **AWS Console** by following the steps from the [Creating an EC2 Environment](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html) guide.
1. Once created, your instance should be listed on the AWS Cloud9 [Environments](https://console.aws.amazon.com/cloud9/home) page. Choose **Open** if not already.
1. You will see a terminal area at the bottom where you will run the commands as you progress through the workshop. In the main work area you will open and edit code and template files.
1. In a Cloud9 terminal, download and run a bootstrap script to upgrade SAM CLI to the most recent version and install few other tools:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    curl 'https://static.us-east-1.prod.workshops.aws/public/ca3cac3e-84b1-4b6a-bd2b-d4565df5a5db/static/bin/bootstrap.sh' | bash
    :::
1. Verify the new version
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    sam --version
    :::

:::alert{type="info"}
If you have issues using the Cloud9 environment, please see the [Troubleshooting AWS Cloud9](https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html) page in the user guide.
:::

### Clone lab resources using `git`
Clone the repository to your working directory. In the Cloud9 terminal run:

:::code{language=shell showLineNumbers=false showCopyAction=true}
git clone https://github.com/aws-samples/cfn101-workshop
:::

### Open workshop files
The templates and code you will work on is located in the **code** folder.
Expand the tree on the left to open the **code** folder:

![toggletree-png](/static/prerequisites/cloud9/toggletree.png)

---

Congratulations, your workshop development environment is now ready to use!
