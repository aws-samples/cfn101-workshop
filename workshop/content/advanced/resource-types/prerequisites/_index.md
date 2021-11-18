---
title: 'Prerequisites'
date: 2021-11-16T20:50:53Z
weight: 310
---

### Resource Type Development Tools

Before proceeding to the next section, choose to install the following prerequisites on your machine:

* follow instructions for your operating system to install the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html): as part of this process, follow also notes to install Docker (unless you have already installed it), that is needed for running contract tests for your resource type;
* follow [steps](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html#resource-type-setup) to install the [CloudFormation Command Line Interface (CLI)](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/what-is-cloudformation-cli.html): this includes installing/checking the version of Python installed on your machine, the installation of the CloudFormation CLI and language plugins. You will use the CloudFormation Command Line Interface for operations that include generating a new project for your resource type with source code stubs, validating your resource type specification against the [resource type schema](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-schema.html), running contract tests and submitting your resource type to the CloudFormation registry;
* for the [resource type example in Python](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python) described in the next lab, follow [notes](https://github.com/aws-cloudformation/aws-cloudformation-samples/tree/main/resource-types/awssamples-ec2-importkeypair/python#unit-tests) to install, with `pip`, the `pytest-cov` and `cloudformation-cli-python-lib` packages that are needed for running unit tests for the sample application.
