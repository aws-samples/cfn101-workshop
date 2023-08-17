---
title: "Multi region latest AMI"
weight: 100
---

_Lab Duration: ~10 minutes_

---

### Overview
Consider the use case of deploying your current template in different regions. You would need to manually change `AmiID`
property in your template to match the AMI ID for each AWS Region. Similarly, if there is an update to the Amazon Machine
Image, and you would like to use the latest image, the same manual process would apply.

To fix this, you can use the existing _Parameters_ section of your CloudFormation template and define Systems Manager parameter
type. A Systems Manager parameter type allows you to reference parameters held in the System Manager Parameter Store.

### Topics Covered
In this Lab, you will learn:

+ How to query **[AWS Systems Manager Parameter Store](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)** in CloudFormation to get the latest Amazon Linux AMI ID.

### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `multi-region-latest-ami.yaml` file.
1. Update the `AmiID` parameter to:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
AmiID:
  Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
  Description: The ID of the AMI.
  Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
:::

Go to the AWS console and create the stack with a new template.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-multi-region-latest-ami \
--template-body file://multi-region-latest-ami.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-multi-region-latest-ami/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Choose **Create stack (With new resources (Standard))** from the top-right side of the page.
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `multi-region-latest-ami.yaml` and click **Next**.
1. Provide a **Stack name**. For example `cfn-workshop-multi-region-latest-ami`.
1. For **Amazon Machine Image ID** copy and paste in `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2`
1. For **EnvironmentType** select the environment from drop down list, for example **Test** and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. You can click the **refresh** button a few times until you see in the status **CREATE_COMPLETE**.
::::
:::::

### Challenge
Deploy the template in different AWS Region to the one you have been using.

::::::expand{header="Solution"}
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
Change the value of `--region` flag to the different region you have created your first stack in. For example, if you created the first stack in `us-east-1` change region to `us-east-2`.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-multi-region-latest-ami \
--template-body file://multi-region-latest-ami.yaml \
--region us-east-2
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-2:123456789012:stack/cfn-workshop-multi-region-latest-ami/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
![new-region-](/static/basics/operations/multi-region-latest-ami/new-region-1.gif)
::::
:::::
:::alert{type="info"}
Notice, that you did not have to update AMI ID parameter. By using CloudFormation's integration with Systems
Manager Parameter Store, your templates are now more generic and reusable.
:::
::::::

### Cleanup
Follow the steps below to [delete the stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html) you created as a part of this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. On the **Stacks** page in the CloudFormation console, select the `cfn-workshop-multi-region-latest-ami` stack.
1. In the stack details pane, choose **Delete** to delete the stack, and then choose **Delete** to confirm.
1. Repeat above steps for all the regions you have used to deploy CloudFormation stacks in.

---
### Conclusion

Congratulations! You have now successfully updated your template to use the latest Amazon Linux AMI. Furthermore, your
template can now be deployed in any region, without appending AMI ID parameter.
