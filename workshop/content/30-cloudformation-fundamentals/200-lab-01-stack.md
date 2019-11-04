---
title: "Lab 01: Template and Stack"
date: 2019-10-25T17:41:16+01:00
weight: 200
---

Lets deploy our first stack. In this Lab, you will write simple template which will deploy S3 bucket. 

The bucket will be used later on when we introduce _Nested Stacks_.

{{% notice note %}} 
The code samples will use the YAML format. This is to reduce the length of code and increase readability compared to JSON. 
{{% /notice %}}

#### Demo

Here's an example of deploying a CloudFormation template using the console.

![](/30-cloudformation-fundamentals/template-example.gif)

**Now try it yourself:**

1. Go to `code/30-cloudformation-fundementals/` directory.
1. Open the `01-lab01-StackExample.yaml` file.
1. Here is a sample CloudFormation template defining an S3 Bucket. It has a single Output, containing the bucket name. Copy the code below and save to the `01-lab01-StackExample.yaml` file.

```yaml
  Resources:
      S3Bucket:
        Type: AWS::S3::Bucket

  Outputs:
      CFNWorkshopS3Bucket:
        Description: S3 bucket for CFN workshop
        Value: !Ref S3Bucket
```

1. Log in to your AWS account and go to [CloudFormation](https://console.aws.amazon.com/cloudformation).
1. Click on _Create stack_ and choose _Upload template file_.
1. Select the file `01-lab01-StackExample.yaml` referenced in step 1.
1. Click _Next_.
1. Provide a _Stack name_.
  * The _Stack name_ identifies the stack. Use a name to help you distinguish the purpose of this stack
1. Click _Next_ and _Create stack_.

---

Great work! You have deployed your first CloudFormation template.
Deploying the template creates a single S3 Bucket in your account. In the Outputs tab, it will output the bucket name.
