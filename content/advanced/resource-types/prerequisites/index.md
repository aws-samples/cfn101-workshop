---
title: "Prerequisites"
weight: 310
---

### Resource Type Development Tools
Before proceeding to the next section, choose to install the following prerequisites on your machine:

* install the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-reference.html#serverless-sam-cli) by following notes for your operating system in links shown next. When you install the SAM CLI, follow also notes to install Docker (unless you have already installed it), that is needed for running contract tests:

  - [AWS SAM CLI on Linux](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html)
  - [AWS SAM CLI on Windows](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-windows.html)
  - [AWS SAM CLI on macOS](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-mac.html)

* install the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html) and plugin(s) for supported languages that you wish to use.

  Use `pip` to install the CloudFormation CLI and Python plugin:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  pip install cloudformation-cli cloudformation-cli-java-plugin cloudformation-cli-go-plugin cloudformation-cli-python-plugin cloudformation-cli-typescript-plugin
  :::

::alert[If you already have version 1.0 of the CloudFormation CLI installed, it is recommended to upgrade it to version 2.0, and to upgrade language plugin(s) you use as well. For the upgrade, you can use the `--upgrade` option for the `pip install` command shown previously, and include language plugins you use or plan to use. For more information, see *Upgrading to CFN-CLI 2.0* further down on this [page](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html#resource-type-setup).]{type="info"}

* for the [Example in Python](../example-in-python) lab, install following packages that are needed for running unit tests for the sample application:

  :::code{language=shell showLineNumbers=false showCopyAction=true}
  pip install pytest-cov cloudformation-cli-python-lib
  :::
