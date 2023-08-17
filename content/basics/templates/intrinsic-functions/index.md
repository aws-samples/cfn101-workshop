---
title: "Intrinsic functions"
weight: 400
---

_Lab Duration: ~10 minutes_

---

### Overview

This lab shows how to use **[Intrinsic Functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)** in your template.

Intrinsic functions are built-in functions that help you manage your stacks. Without them, you will be limited to very
basic templates, similar to the S3 template you have seen in a **[Lab01](../template-and-stack)**.

### Topics Covered

In this Lab, you will:

+ Use the **[Ref](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html)** function to dynamically assign parameter values to a resource property.
+ Tag an instance with **[Fn::Join](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html)** function.
+ Add a tag to the instance using **[Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** function.

### Start Lab

1. Go to the `code/workspace` directory.
1. Open the `intrinsic-functions.yaml` file.
1. Copy the code as you go through the topics below.

:::alert{type="info"}
Intrinsic functions can only be used in certain parts of a template. You can use intrinsic functions in
**resource properties, outputs, metadata attributes, and update policy attributes**.
:::

#### Ref

In the last lab you have "hard coded" an AMI ID directly into the EC2 Resource property. You will now amend this to make
your template more flexible. Let's convert `AmiID` to variable and pass it to resource property at the runtime.

1. First, create a new parameter called `AmiID` and put it in the `Parameters` section of your template.

    ```yaml
    AmiID:
      Type: AWS::EC2::Image::Id
      Description: 'The ID of the AMI.'
    ```

1. Use the intrinsic function `Ref` to pass the `AmiID` parameter input to the EC2 resource property.

    ```yaml
    Resources:
      WebServerInstance:
        Type: AWS::EC2::Instance
        Properties:
          # Use !Ref function in ImageId property
          ImageId: !Ref AmiID
          InstanceType: !Ref InstanceType
    ```

#### Fn::Join

To help you manage your AWS resources, you can optionally assign your own metadata to each resource in the form
of **tags**. Each tag is a simple label consisting of a customer-defined key, and an optional value that can help you
to categorize resources by purpose, owner, environment, or other criteria. Let's use the intrinsic function **Fn::Join** to name your instance.

1. Add property `Tags` to the `Properties` section.
1. Reference `InstanceType` parameter and add a word _webserver_, delimited with dash `-` to the tags' property.

    ```yaml
    Resources:
      WebServerInstance:
        Type: AWS::EC2::Instance
        Properties:
          ImageId: !Ref AmiID
          InstanceType: !Ref InstanceType
          Tags:
            - Key: Name
              Value: !Join [ '-', [ !Ref InstanceType, webserver ] ]
    ```

#### Create EC2 stack

Now it is time to create your stack.


:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **MyAmiId** with the value you have hardcoded in `resources.yaml` file earlier.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-intrinsic-functions --template-body file://intrinsic-functions.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-intrinsic-functions/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Select **Create stack** (_With new resources (Standard)_ if you have clicked in the top right corner).
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, choose **Upload a template file**.
1. Select **Choose file** button and navigate to your workshop directory.
1. Select the file `intrinsic-functions.yaml` and click **Next**.
1. Provide a **Stack name**. For example `cfn-workshop-intrinsic-functions`.
1. For **Type of EC2 Instance** leave the default value in.
1. For **Amazon Machine Image ID** copy and paste AMI ID you have hardcoded in `resources.yaml` file and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. You can click the **refresh** button a few times until you see in the status **CREATE_COMPLETE**.
::::
:::::


**To see the result of the stack creation:**

1. Open **[AWS EC2 console](https://console.aws.amazon.com/ec2)** link in a new tab of your browser.
1. In the left-hand pane, click on **Instances**.
1. Select the instance with a name **t2.micro-webserver**
1. Go to the **Tags** tab, you should see there a key `Name` with a value `t2.micro-webserver`.
   ![tags-png](/static/basics/templates/intrinsic-functions/tags.png)

### Challenge
Create another tag named `InstanceType` and use the `Fn::Sub` intrinsic function to return the type of the instance.

The syntax for the YAML short form of the `Fn::Sub` intrinsic function is `!Sub`.

::expand[Check out the AWS Documentation for **[Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** function.]{header="Need a hint?"}

::::::expand{header="Want to see the solution?"}
Add the `InstanceType` tag to your template.
```yaml
Resources:
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref AmiID
      InstanceType: !Ref InstanceType
      Tags:
        - Key: Name
          Value: !Join [ '-', [ !Ref InstanceType, webserver ] ]
        - Key: InstanceType
          Value: !Sub ${InstanceType}
```

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace
:::
1. Use the AWS CLI to update the stack. The required parameter `--template-body` have been pre-filled for you. Replace the `ParameterValue` **MyAmiId** with the value you have hardcoded in `resources.yaml` file earlier.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack --stack-name cfn-workshop-intrinsic-functions --template-body file://intrinsic-functions.yaml --parameters ParameterKey="AmiID",ParameterValue="MyAmiId"
:::
1. If the `update-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-intrinsic-functions/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **UPDATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Select the stack name, for example **cfn-workshop-intrinsic-functions**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Specify template**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `intrinsic-functions.yaml` and click **Next**.
1. For **Type of EC2 Instance** leave the default value in.
1. For **Amazon Machine Image ID** copy and paste AMI ID you have hardcoded in `resources.yaml` file and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Submit**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.
::::
:::::
To Verify, Go to the **Tags** tab on EC2 Console, verify that `InstanceType` tag has been created.
::::::

### Clean up

Follow these steps to clean up created resources:

1. In the **[CloudFormation console](https://console.aws.amazon.com/cloudformation)**, select the stack you have created in this lab. For example `cfn-workshop-intrinsic-functions`.
1. In the top right corner, select **Delete**.
1. In the pop-up window, select **Delete**.
1. Wait for the stack to reach the **DELETE_COMPLETE** status. You need to periodically select **Refresh** to see the latest stack status.

---

### Conclusion
Congratulations! You now have successfully used intrinsic functions in your template.
