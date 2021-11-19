---
title: 'Prerequisites'
date: 2021-11-16T20:50:53Z
weight: 310
---

### Resource Type Development Tools

Before proceeding to the next section, choose to install the following prerequisites on your machine:

* install the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-reference.html#serverless-sam-cli) by following notes for your operating system in links shown next. When you install the SAM CLI, follow also notes to install Docker (unless you have already installed it), that is needed for running contract tests:

  - [AWS SAM CLI on Linux](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html)
  - [AWS SAM CLI on Windows](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-windows.html)
  - [AWS SAM CLI on macOS](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-mac.html)

  For example, installing AWS SAM CLI and Docker on macOS using [Homebrew package manager](https://docs.brew.sh/).
  ```shell
  # install docker desktop
  $ brew install docker --cask

  # verify docker installation
  $ docker --version
  Docker version 20.10.8, build 3967b7d

  # install AWS SAM CLI
  $ brew tap aws/tap
  $ brew install aws-sam-cli

  # verify sam installation
  $ sam --version
  SAM CLI, version 1.35.0
  ```

* install the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) and plugin(s) for supported languages that you wish to use.

  Use `pip` to install the CloudFormation CLI and Python plugin:
  ```shell
  $ pip install cloudformation-cli cloudformation-cli-python-plugin
  ```
  For macOS, you can use Homebrew to install Python and the CloudFormation Command Line Interface:
  ```shell
  # install cloudformation-cli
  $ brew install cloudformation-cli

  # upgrade Python Plugin to CFN-CLI 2.0
  $ pip3 install cloudformation-cli-python-plugin

  # verify the installation
  $  cfn --version
  cfn 0.2.21
  ```

{{% notice note %}}
If you already have version 1.0 of the CloudFormation CLI installed, it is recommended to upgrade it to version 2.0, and to upgrade language plugin(s) you use as well. For the upgrade, you can use the `--upgrade` option for the `pip install` command shown previously, and include language plugins you use or plan to use. For more information, see *Upgrading to CFN-CLI 2.0* further down on this [page](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html#resource-type-setup).
{{% /notice %}}

* for the [Example in Python](example-in_python.html) lab, install following packages that are needed for running unit tests for the sample application:

  ```shell
  $ pip install pytest-cov cloudformation-cli-python-lib
  ```
