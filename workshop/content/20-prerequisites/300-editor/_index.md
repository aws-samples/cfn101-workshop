---
title: 'Install a code editor'
date: 2019-10-18T14:28:46+01:00
weight: 300
---

You may use any code editor or IDE of your choice that supports editing [YAML](https://yaml.org/) but for this workshop we will assume the use of [Visual Studio Code](https://code.visualstudio.com/) as it works well on macOS, Linux, and Windows.

To install VS Code, use your operating system's package manager (e.g. `brew cask install visual-studio-code` on macOS) or follow [the instructions on the VS code website](https://code.visualstudio.com/).

## CloudFormation Linter

We recommend you install the [AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-python-lint).  A [linter](https://en.wikipedia.org/wiki/Lint_(software)) will proactively flag basic errors in your CloudFormation templates before you deploy them.

If you are using Visual Studio Code, you should install the [cfn-lint](https://marketplace.visualstudio.com/items?itemName=kddejong.vscode-cfn-lint) plugin.

{{% notice tip %}}
Note that `cfn-lint` is not installed automatically with the Visual Studio Code  `cfn-lint` extension.
Install it separately following the [installation instructions](https://github.com/aws-cloudformation/cfn-python-lint#install)
{{% /notice %}}
