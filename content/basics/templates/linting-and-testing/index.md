---
title: "Linting and testing"
weight: 900
---

_Lab Duration: ~15 minutes_

_Challenge: ~3 minutes._
---

### Overview
It is a best practice to lint and test your CloudFormation templates in early phases of the Software Development Life Cycle (SDLC). First, you run linting and testing actions for your templates on your workstation; next, you add template linting and testing practices to the Continuous Integration (CI) phase of your pipelines: you use the CI phase as an initial gating step for code promotion.

In this lab, you will focus on an example linting and testing workflow you will run from your workstation. You will familiarize with tools such as [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) to validate your template against the [AWS CloudFormation Resource Specification](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html), and with [taskcat](https://github.com/aws-ia/taskcat), a tool that gives you the ability to test your templates by creating stacks off, of your templates, in regions you specify.

### Topics Covered
By the end of this lab, you will be able to:

* Use `cfn-lint` to validate your templates.
* Understand how to detect and fix validation issues.
* Use `taskcat` to test your template by creating stacks in regions you specify.

### Prerequisites

#### Prerequisites for linting
Choose to [install](https://github.com/aws-cloudformation/cfn-lint#install) `cfn-lint` with a method of your choice. For example, you can install `cfn-lint` with `pip`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-lint
:::

::alert[In this lab, you will invoke `cfn-lint` via the command line. You can also install an IDE plugin for `cfn-lint` from the ones listed on this [page](https://github.com/aws-cloudformation/cfn-lint#editor-plugins), to get feedback from `cfn-lint` in the supported editor.]{type="info"}

After you have completed the installation, verify you can run `cfn-lint`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint --version
:::

#### Prerequisites for testing

[Install](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html) `taskcat` with `pip`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install taskcat
:::

::alert[As per this [note](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html#windows), `taskcat` is not supported on Windows. If you are using Windows 10, follow instructions on this [page](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html#windows) to install `taskcat` inside a [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about) (WSL) environment.]{type="info"}

After you have completed the installation, verify you can run `taskcat`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
taskcat --version
:::

### Start Lab

#### Template linting

In this section, you will run `cfn-lint` against an example CloudFormation template to validate your configuration. Your goal is to validate, very early in the development life cycle, your template content against the [AWS CloudFormation Resource Specification](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) to check for valid values you can specify, and to also have an opportunity to validate the template against a number of best-practice checks:

1. Change directory to the `code/workspace/linting-and-testing` directory.
2. Open the `vpc-and-security-group.yaml` CloudFormation template in your favorite text editor. The sample template describes an example VPC and an example VPC Security Group that references the VPC. _Note that to keep a simple scope in this lab, that focuses on example linting use cases, the example template does not describe other VPC-related resources such as subnets, Internet Gateway, route table, and route resources._
3. Run `cfn-lint` against the template:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint vpc-and-security-group.yaml
:::

In the output, you note an error:
:::code{language=shell showLineNumbers=false showCopyAction=false}
E3004 Circular Dependencies for resource SecurityGroup. Circular dependency with [SecurityGroup]
[...]
:::

The example template contains a circular dependency error: you get this type of error when you, in a resource property _value_, reference the [logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) of the resource itself. When you look at the sample template, you see it has a circular dependency for the `SecurityGroup` resource of the `AWS::EC2::SecurityGroup` [type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html), because the `SourceSecurityGroupId` property references the `SecurityGroup` resource itself, as shown in the following template excerpt:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
[...]
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Example Security Group
      SecurityGroupIngress:
        - Description: Example rule to allow tcp/443 traffic from SecurityGroup
          FromPort: 443
          ToPort: 443
          IpProtocol: tcp
          SourceSecurityGroupId: !Ref SecurityGroup
[...]
:::

To fix the circular dependency, move the `SecurityGroupIngress` related configuration of your Security Group into a new resource of the `AWS::EC2::SecurityGroupIngress` [type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html): for the `SourceSecurityGroupId` property value of this resource you will add to your template, you will reference the `SecurityGroup` resource. With the `vpc-and-security-group.yaml` template opened in your favorite text editor, replace the whole `SecurityGroup` resource declaration block with content below:

```yaml
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Example Security Group
      SecurityGroupEgress:
        - Description: Example rule limiting egress traffic to 127.0.0.1/32
          CidrIp: 127.0.0.1/32
          IpProtocol: "-1"
      VpcId: !Ref Vpc

  SecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      Description: Example rule to allow tcp/443 traffic from SecurityGroup
      FromPort: 443
      ToPort: 443
      GroupId: !Ref SecurityGroup
      IpProtocol: tcp
      SourceSecurityGroupId: !Ref SecurityGroup
```

When done, save the file and validate the template again with `cfn-lint` to verify you fixed the error:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint vpc-and-security-group.yaml
:::

> Congratulations! You have run the `cfn-lint` tool against your template, and you found and fixed an error detected by the tool!

#### Template testing
You will now use `taskcat` to test your template by creating stacks off of it, in AWS regions you choose. You can describe test configuration values you wish to use with `taskcat` by using [config files](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE.html#config-files), whose configuration properties you have the choice to specify:

* **[general](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema.html#general) scope:** a global scope for all of your projects. For this use case, you create a `~/.taskcat.yml` file in your home directory;
* **[project](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema.html#project)-specific scope:** you create a `.taskcat.yml` configuration file in your project's root directory. You can also use [tests](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema.html#tests) configuration directives at the project-level scope.

Start with configuring _project_ and _tests_ scopes in the `.taskcat.yml` file located in the `code/workspace/linting-and-testing` directory. Open this file with your favorite test editor, and specify name(s) of AWS [regions](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema.html#project_regions) where you want to test your `vpc-and-security-group.yaml` template, as shown in the file excerpt below:

:::code{language=shell showLineNumbers=false showCopyAction=false}
[...]
  regions:
  - us-east-1
  - us-east-2
[...]
:::

When done, save the file with your changes.

::alert[As part of [requirements](https://aws-ia.github.io/taskcat/docs/INSTALLATION.html#requirements) for `taskcat`, you will need Docker if you are building AWS Lambda functions with a `Dockerfile`. You will not need this functionality for this lab, and this functionality has been disabled with the `package_lambda` configuration [setting](https://aws-ia.github.io/taskcat/docs/schema/taskcat_schema.html#project_package_lambda) set to `false` in the `.taskcat.yml` file.]{type="info"}

Next, you will create a `~/.taskcat.yml` configuration file __in your home directory, that is outside your projects' version control path__. In this file you will store, for all of your projects, configuration settings that you do not want to add to version control. This also includes any sensitive values you might have: __do not store sensitive values in version control__.

::alert[For information on how to reference sensitive values from your CloudFormation templates, see [SSM secure string parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-ssm-secure-strings) and [Secrets Manager secrets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/dynamic-references.html#dynamic-references-secretsmanager).]{type="info"}

::alert[Values you pass to a given configuration setting you describe at a more specific scope (for example, in `tests`) will take [precedence](https://aws-ia.github.io/taskcat/docs/usage/GENERAL_USAGE.html#precedence) over less specific scopes (such as `project` and `general`), __with the exception to the `parameters` setting that works the opposite way__ (that is, a `parameters` setting you describe in the `general` scope will have precedence over more specific scopes). You will see how `parameters` is described in a `general` section next.]{type="info"}

**Create a new** `~/.taskcat.yml` file in your home directory. In this file, you will specify the name of your S3 bucket into which `taskcat` will upload your template to be tested, and an example value of `172.16.0.0/16` for the `VpcIpv4Cidr` example template parameter.
:::code{language=shell showLineNumbers=false showCopyAction=true}
touch ~/.taskcat.yml
:::

Add following content to the file you just created and, when you do so, make sure you replace the `YOUR_ACCOUNT_ID` example placeholder with your [AWS account ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html#FindingYourAWSId):
```yaml
general:
  s3_bucket: tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
  parameters:
    VpcIpv4Cidr: 172.16.0.0/16
```

Next, use the AWS CLI to create your bucket whose name you just specified in the file (replace `YOUR_ACCOUNT_ID` with your value here as well):
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3 mb s3://tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
:::

::alert[You can specify the `s3_bucket` configuration setting in _general_, _project_, and _tests_ scopes as needed. When you do not specify an `s3_bucket` property, `taskcat` will automatically create a bucket for you when you launch a test run.]{type="info"}

After you have created the bucket, run the following command to start testing:
:::code{language=shell showLineNumbers=false showCopyAction=true}
taskcat test run
:::

Once `taskcat` has finished running tests, you should find successful test results in reports available in the `code/workspace/linting-and-testing/taskcat_outputs/index.html` file.

You can find following workspace files (with updates, as needed): `vpc-and-security-group.yaml`, `.taskcat.yml`, and `.gitignore` in the `code/solutions/linting-and-testing` path.

> Congratulations! You have run tests for your CloudFormation template in one (or more regions) with `taskcat`!


#### Template testing: lab resources cleanup

You can use the [AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/) to remove resources you created in this lab for testing. First, **delete the template file object** that `taskcat` has uploaded for you into your S3 bucket, as in the following example (please note: replace `YOUR_ACCOUNT_ID` with your value):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-object --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID --key linting-and-testing-workshop/vpc-and-security-group.yaml
:::

In the same project workspace directory where you found the `vpc-and-security-group.yaml` example, there is another template (`sqs-queue.yaml`) that you will troubleshoot in the _Challenge_ section of this lab. As part of the test run you did earlier, `taskcat` has uploaded this file for you as well in your bucket: remove it from your bucket, as shown in the following example (replace `YOUR_ACCOUNT_ID` with your value):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-object --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID --key linting-and-testing-workshop/sqs-queue.yaml
:::

Next, **delete your bucket** you created for this lab. At this point, your bucket should not contain other objects. Run the following command, and make sure to replace `YOUR_ACCOUNT_ID` with your value:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws s3api delete-bucket --bucket tcat-linting-and-testing-workshop-YOUR_ACCOUNT_ID
:::

If needed, delete the `~/.taskcat.yml` file you created in your home directory as well.
:::code{language=shell showLineNumbers=false showCopyAction=true}
rm ~/.taskcat.yml
:::

### Challenge

Find and fix errors in an example template that describes an `AWS::SQS::Queue` [resource type](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html):

* locate the template file available at this path: `code/workspace/linting-and-testing/sqs-queue.yaml`;
* use `cfn-lint` to find errors in the template;
* fix issues, and verify with `cfn-lint` that you have fixed issues you found.

:::expand{header="Need a hint?"}
* From the `code/workspace/linting-and-testing` directory, run `cfn-lint sqs-queue.yaml` to find errors in the example template;
* refer to the `cfn-lint` command output, and to the SQS resource’s documentation [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-sqs-queue-delayseconds) for values you can specify for the `DelaySeconds` property;
* see names for available SQS queue [properties](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-properties);
* see names of available _attributes_ for SQS queue [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sqs-queues.html#aws-properties-sqs-queues-return-values).
:::

:::expand{header="Want to see the solution?"}
* Specify a value between `0` (default) and `900` for `DelaySeconds`;
* replace `Tag` with `Tags` in the SQS resource property section of the template;
* replace `Name` with `QueueName` as the attribute you specify for `Fn::GetAtt` to return the name of the queue;
* from the `code/workspace/linting-and-testing` directory, run `cfn-lint sqs-queue.yaml` to verify there are no more errors.

You can find the full solution in the `code/solutions/linting-and-testing/sqs-queue.yaml` example template.
:::

---
### Conclusion

Great work! You have performed validation of example templates on your workstation using `cfn-lint` and `taskcat`, by using the command line. You have also used `cfn-lint` to find errors in an example template, and used error information provided by `cfn-lint` to fix template issues. For a faster feedback loop, you can choose to integrate `cfn-lint` with a number of code editors, as shown on this [page](https://github.com/aws-cloudformation/cfn-lint#editor-plugins).
