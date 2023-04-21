---
title: "Use local development"
weight: 200
---


## Install AWS CLI

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

## Setting up Editor

You may use any code editor or IDE of your choice that supports editing [YAML](https://yaml.org/) but for this workshop
we will assume the use of [Visual Studio Code](https://code.visualstudio.com/) as it works well on macOS, Linux, and Windows.

To install VS Code, use your operating system's package manager (e.g. `brew cask install visual-studio-code` on macOS)
or follow [the instructions on the VS code website](https://code.visualstudio.com/).

## CloudFormation Linter

We recommend you install the [AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-python-lint).
A [linter](https://en.wikipedia.org/wiki/Lint_(software)) will proactively flag basic errors in your CloudFormation templates before you deploy them.

If you are using Visual Studio Code, you should install the [cfn-lint](https://marketplace.visualstudio.com/items?itemName=kddejong.vscode-cfn-lint) plugin.

:::alert{type="info"}
Note that `cfn-lint` is not installed automatically with the Visual Studio Code  `cfn-lint` extension.
Install it separately following the [installation instructions](https://github.com/aws-cloudformation/cfn-python-lint#install)
:::
