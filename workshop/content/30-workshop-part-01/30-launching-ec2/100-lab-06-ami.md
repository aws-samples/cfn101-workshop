---
title: 'Lab 06: Multi Region Latest AMI'
date: 2019-11-07T13:46:21Z
weight: 100
---

### Use Case
Consider the use case of deploying your current template in different regions. You will have to manually change `AmiID`
property in your template to match the AMI ID for that particular AWS Region. Similarly, if there is an update to the 
Amazon Machine Image, and you would like to use the latest image, the same manual process would apply.

### Solution
To fix this, you can use the existing _Parameters_ section of your CloudFormation template and define Systems Manager 
parameter type. A Systems Manager parameter type allows you to reference parameters held in the System Manager Parameter Store.

1. Go to the `code/50-launching-ec2/` directory.

1. Open the `01-lab06-SSM.yaml` file.

1. Update the `AmiID` parameter to:
    ```yaml
        AmiID:
          Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
          Description: The ID of the AMI.
          Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
    ```

1. Go to the AWS console and update your stack with a new template.
{{% notice info %}}
If CloudFormation console is using _ami-xxxxxxx_ as an `Amazon Machine Image ID` copy and paste default value `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2`
to the text box. ![](/50-launching-ec2/ssm-1.png)
{{% /notice %}}

{{%expand "How do I update a Stack?" %}}
![](/50-launching-ec2/update-2.gif)
{{% /expand %}}

#### Exercise
Deploy the template in different AWS Region to the one you have been using.

{{%expand "Solution" %}}
![](/50-launching-ec2/new-region-1.gif)
{{% /expand %}}

{{% notice note %}}
Notice, that you did not have to update AMI ID parameter. By using CloudFormation's integration with Systems 
Manager Parameter Store, your templates are now more generic and reusable.
{{% /notice %}}


