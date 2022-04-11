---
title: "Intrinsic functions"
weight: 400
---

### Overview

This lab shows how to use **[Intrinsic Functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)** in your template.

Intrinsic functions are built-in functions that help you manage your stacks. Without them, you will be limited to very
basic templates, similar to the S3 template you have seen in a **[Lab01](../../template-and-stack)**.

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

#### Update EC2 stack

Now it is time to update your stack. Go to the AWS console and update your CloudFormation Stack.

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-ec2**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `intrinsic-functions.yaml` and click **Next**.
1. For **Type of EC2 Instance** leave the default value in.
1. For **Amazon Machine Image ID** copy and paste AMI ID you have hardcoded in `resources.yaml` file and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Update stack**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.

::expand[![update-gif](/static/basics/templates/intrinsic-functions/update-1.gif)]{header="Want to see how to update the stack?"}

**To see the result of the stack update:**

1. Open **[AWS EC2 console](https://console.aws.amazon.com/ec2)** link in a new tab of your browser.
1. In the left-hand pane, click on **Instances**.
1. Select the instance with a name **t2.micro-webserver**
1. Go to the **Tags** tab, you should see there a key `Name` with a value `t2.micro-webserver`.
   ![tags-png](/static/basics/templates/intrinsic-functions/tags.png)

### Challenge
Crete another tag named `InstanceType` and use intrinsic function **Fn::Sub** to return type of the instance.

The syntax for the short form is `!Sub`

::expand[Check out the AWS Documentation for **[Fn::Sub](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html)** function.]{header="Need a hint?"}

:::expand{header="Want to see the solution?"}
1. Add the `InstanceType` tag to your template.

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

1. Go to the AWS console and update your CloudFormation Stack.
1. In the EC2 console, verify that `InstanceType` tag has been created.
:::

---
### Conclusion
Congratulations! You now have successfully used intrinsic functions in your template.
