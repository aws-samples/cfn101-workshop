---
title: "Outputs"
weight: 700
---

_Lab Duration: ~10 minutes_

---

### Overview

In this lab you will learn about **[Outputs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)**.
_Outputs_ enable you to get access to information about resources within a stack. For example, you can output an EC2
instance's Public DNS name once it is created.

Furthermore, output values can be imported into other stacks. These are known as cross-stack references.

##### YAML Syntax:
The _Outputs_ section consists of the key name `Outputs`, followed by a colon.

:::code{language=yaml showLineNumbers=false showCopyAction=false}
Outputs:
  Logical ID:
    Description: Information about the value
    Value: Value to return
    Export:
      Name: Value to export
:::

::alert[For the maximum number of outputs you can declare in your template, see Outputs in [AWS CloudFormation quotas](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html).]{type="info"}

### Topics Covered
In this Lab, you will:

+ Create an Output section in your template and return Public DNS name of the instance.
+ Create Elastic IP resource and attach it to the EC2 instance.
+ Learn how to view outputs from within CloudFormation in AWS console.

### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `outputs.yaml` file.
1. Copy the code as you go through the topics below.
1. To get the _PublicDnsName_ of the instance, you will need to use `Fn::GetAtt` intrinsic function. Let's first check
 the [AWS Documentation](https://docs.aws.amazon.com/en_pv/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values) for available attributes. You can see that _PublicDnsName_ is valid return value for `Fn::GetAtt` function.

    Add the section below to your template:
    ```yaml
    Outputs:
      EC2PublicDNS:
        Description: 'Public DNS of EC2 instance'
        Value: !GetAtt WebServerInstance.PublicDnsName
    ```

1. Create the stack with new template.

:::::tabs{variant="container"}

::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **MyAmiId** with  the value you have hardcoded in `resources.yaml` file earlier.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-outputs --template-body file://outputs.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-outputs/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Choose **Create stack** (_With new resources (Standard)_ from the top-right side of the page.
1. In **Prepare template**, choose **Template is ready**.
1. In **Specify template**, choose **Upload a template file**.
1. Select the **Choose file** button and navigate to your workshop directory.
1. Select the file `outputs.yaml` and click **Next**.
1. Provide a **Stack name**. For example `cfn-workshop-outputs`.
1. Choose to accept default values for **Configure stack options**; choose **Next**.
1. On the **Review <stack_name>** page, scroll to the bottom and choose **Submit**.
1. Use the **refresh** button to update the page as needed, until you see the stack has the **CREATE_COMPLETE** status.
::::
:::::

View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.


### Challenge

In this exercise, you should assign an Elastic IP to your EC2 instance. Then, add an output of the Elastic IP to the
_Outputs_ section of the template. You should continue using the `outputs.yaml` template.

1. Create an `AWS::EC2::EIP` resource and attach it to your existing EC2 instance.
1. Create a logical ID called `ElasticIP` and add it to the Outputs section of the template.
1. Update the stack to test changes in your template.

::expand[Check out the AWS Documentation for [AWS::EC2::EIP resource](https://docs.aws.amazon.com/en_pv/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-eip.html)]{header="Need a hint?"}

::::::expand{header="Want to see the solution?"}
  ```yaml
  Resources:
    WebServerInstance:
      Type: AWS::EC2::Instance
      Properties:
        ImageId: !Ref AmiID
        InstanceType: !FindInMap [EnvironmentToInstanceType, !Ref EnvironmentType, InstanceType]
        Tags:
          - Key: Name
            Value: !Join [ '-', [ !Ref EnvironmentType, webserver ] ]

    WebServerEIP:
      Type: 'AWS::EC2::EIP'
      Properties:
        Domain: vpc
        InstanceId: !Ref WebServerInstance

  Outputs:
    WebServerPublicDNS:
      Description: 'Public DNS of EC2 instance'
      Value: !GetAtt WebServerInstance.PublicDnsName

    WebServerElasticIP:
      Description: 'Elastic IP assigned to EC2'
      Value: !Ref WebServerEIP
  ```
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace
  :::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **MyAmiId** with  the value you have hardcoded in `resources.yaml` file earlier.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation update-stack --stack-name cfn-workshop-outputs --template-body file://outputs.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
  :::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-outputs/739fafa0-e4d7-11ed-a000-12d9009553ff"
  :::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
1.  View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-outputs**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Template is ready**.
1. In **Specify template**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `outputs.yaml` and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.
1. View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.
::::
:::::
::::::

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-outputs`.
1. In the top right corner, select **Delete**.
1. In the pop-up window, select **Delete stack**.
1. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---

### Conclusion
Great work! You have now successfully learned how to use **Outputs** in CloudFormation template.
