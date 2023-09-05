---
title: "Finding return values"
weight: 800
---

_Lab Duration: ~10 minutes_

---

### Overview
You use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) to programmatically describe your resources in your templates. When you do so, you might also need to reference return values, for a given resource, from another resource or resources that you also describe in the same template, and that depend on the given resource.

You can also choose to display a given resource’s return value(s) in the `Outputs` [section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) of your template: when you do so, you also have the choice to make a given output value available to other stacks in the same region by [exporting](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) the output.

### Topics Covered
By the end of this lab, you will be able to:

* Understand the usage of return values.
* Learn how to search for return values for different resource types.
* Understand the difference between using `Ref`, `Fn::GetAtt`, and `Fn::Sub` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) when using return values.

Return values are documented in the [AWS resource and property types reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) for a given resource type: choose any resource type from the list, and then choose **Return Values** on the right side of the page to see which values you can use with [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) such as `Ref` and `Fn::GetAtt`.

Let’s take an [Amazon Simple Storage Service](https://aws.amazon.com/s3/) (Amazon S3) bucket resource type, `AWS::S3::Bucket`, as an example: choose **Amazon Simple Storage Service** from the list under [AWS resource and property types reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html). On the next page, choose **AWS::S3::Bucket** to view the reference documentation for the resource type: on the right pane of the page, choose **Return Values** to view available return values for the `AWS::S3::Bucket` resource type.

Follow through the document to understand what available values are returned when you use `Ref` or `Fn::GetAtt` intrinsic functions. For example, if you want to reference the bucket name, use `Ref` followed by the [logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) of your bucket resource; if you wish to retrieve the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) of your bucket, use `Fn::GetAtt` with the `Arn` attribute.

In this lab, you will learn how to reference, from a given resource type you describe in your template, return values for another resource type that you also describe in the same template.

### Start Lab
* Change directory to `code/workspace/resource-return-values`.
* Open the `resource-return-values.yaml` file.
* Update the content of the template as you follow along steps on this lab.

In this lab, you will:

* Learn how to utilize return values of a resource in other resource described in the same template.
* Learn how you can define stack outputs based on the resource return values using `Ref`,  `Fn::GetAtt` and `Fn::Sub` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).

::alert[The example shown next does not include the `BucketName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#cfn-s3-bucket-name) for the Amazon S3 bucket. In this case, CloudFormation will generate a unique name for the given resource.]{type="info"}

The bucket policy in the example shown next denies access to the Amazon S3 bucket when a request meets the `aws\:SecureTransport: false` condition. The policy below uses the `Deny` effect when a request is made via HTTP instead of HTTPS.

Copy and append the example template snippet shown next to the `resource-return-values.yaml` file:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Purpose
          Value: AWS CloudFormation Workshop

  S3BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref S3Bucket
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Action:
              - s3:*
            Effect: Deny
            Resource:
              - !GetAtt S3Bucket.Arn
              - !Sub '${S3Bucket.Arn}/*'
            Principal: '*'
            Condition:
              Bool:
                aws:SecureTransport: false

Outputs:
  S3BucketDomainName:
    Description: IPv4 DNS name of the bucket.
    Value: !GetAtt S3Bucket.DomainName
:::

There are two resources in the template snippet you pasted into your template: an Amazon S3 [bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html) and a bucket [policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-policy.html). Note the following:

* The [logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html#resources-section-structure-resource-fields) of the bucket resource (i.e., `S3Bucket` in the above example), is referenced with the `Ref` intrinsic function in the `Bucket` property of the `S3BucketPolicy` resource. The `Bucket` property requires the name of the Amazon S3 bucket to which the policy applies. The bucket resource returns the name of the bucket when you specify the logical ID of the bucket resource with the `Ref` function. For more information, see Amazon S3 bucket [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values).
* Note the `Resource` section for the `PolicyDocument` property of `S3BucketPolicy`: `Resource` requires the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) of the bucket. Refer to the Amazon S3 bucket [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values), and note that the `AWS::S3::Bucket` resource type returns the ARN of the bucket when you use the `Fn::GetAtt` intrinsic function, along with the logical ID of the bucket and the `Arn` attribute.
* Refer to the Amazon S3 bucket [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values): note that there are a number of values being returned by the `AWS::S3::Bucket` resource type when you specify the required attribute along with the `Fn::GetAtt` intrinsic function. As an example, see the `S3BucketDomainName` output described in the `Outputs` [section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) of the template snippet shown above. Here, the intent is to output the DNS name of the bucket you describe in your template. The IPv4 DNS name of the bucket is returned when you specify the logical ID of the bucket resource, along with the `DomainName` attribute for the `Fn::GetAtt` intrinsic function.
* Now, let’s discuss the `Fn::Sub` intrinsic function, used above in the `Resource` attribute of the `PolicyDocument` property for the `S3BucketPolicy` resource. The `Fn::Sub` intrinsic function can be used to retrieve values that `Ref` and `Fn::GetAtt` return for a specified resource using the same format of logical ID and return value attribute. The main purpose of using `Fn::Sub` with return values is to concatenate string(s) to the returned value(s). In the above example, you use `Fn::Sub` to concatenate `/*` to the returned bucket ARN: the reason for adding `/*` at the end of the bucket ARN is to make sure the actions defined in the policy are applied to all the objects in the bucket.

Let’s create a stack using the `resource-return-values.yaml` template, and see the above in action!

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/resource-return-values`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/resource-return-values
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-resource-return-values --template-body file://resource-return-values.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-return-values/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. In the CloudFormation console, select **Create stack With new resources (standard)**.
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Upload the `resource-return-values.yaml` template, and choose **Next**.
1. Enter a stack name. For example, `cfn-workshop-resource-return-values`. When ready, choose **Next**.
1. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
1. In the review page, scroll to the bottom and choose **Submit**.
1. Refresh the page until you see the `CREATE_COMPLETE` status for your stack.
::::
:::::

 Now, let’s review the stack events and outputs. Your stack events should look similar to the image shown next:
![resource-return-values.png](/static/basics/templates/resource-return-values/resource-return-values.png)

Looking at the stack events, you can see the bucket and the bucket policy are created successfully. Now, navigate to the **Resources** pane for your stack, note the Physical ID value for `S3Bucket`, and follow the link: this will bring you to the details page for your bucket in the [Amazon S3 Console](https://console.aws.amazon.com/s3/). Next, in the bucket view, choose **Permissions** and review the bucket policy in the **Bucket policy** section: see how the return values have been substituted in the `Resource` section of the bucket policy. Next, navigate to the **Outputs** pane of your stack in the AWS CloudFormation Console, and note the value of the IPv4 DNS name displayed for the Amazon S3 bucket you created in the stack.

Congratulations! You have now learned how to find return values for a specified resource, and how to use them in your templates with other resources using `Ref`, `Fn::GetAtt` and `Fn::Sub` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).

### Challenge
In this section of the lab, you are tasked with updating an existing, example template that describes an Amazon EC2 [instance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html) and a [security group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html). You will need to reference the security group’s logical ID in the `SecurityGroups` property of the Amazon EC2 instance resource. Also, you need to update the `Outputs` section of the template to output the following values:

* Instance ID of the Amazon EC2 instance created in the stack.
* Public IP of the Amazon EC2 instance created.
* ID of the security group created in the stack.

To get started, open the `resource-return-values-challenge.yaml` template, that you can find in the `code/workspace/resource-return-values` directory, with your favorite code editor. Follow example requirements above, and update the template accordingly.

When ready, create a new stack, called `resource-return-values-challenge`, with your updated `resource-return-values-challenge.yaml` template, and verify if the requirements are met.

:::expand{header="Need a hint?"}
* How can you [reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) your security group in the `SecurityGroups` property of your Amazon EC2 instance?
* When you reference your security group, also note that the `Type` of the `SecurityGroups` property value is a *List of String*. How do you represent this value in YAML format?
* Review Amazon EC2 instance [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#aws-properties-ec2-instance-return-values) and security group [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-return-values), and see what values are returned when you use `Ref` or `Fn::GetAtt` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).
:::

::::::expand{header="Want to see the solution?"}
* Reference the Security Group’s logical ID as a list item under the `SecurityGroups` instance resource property, by using `Ref` intrinsic function.
* Modify the Amazon EC2 instance resource definition as next:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Ec2Instance:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: !Ref LatestAmiId
    InstanceType: t2.micro
    SecurityGroups:
      - !Ref InstanceSecurityGroup
    Tags:
      - Key: Name
        Value: Resource-return-values-workshop
:::

* Use `Ref` intrinsic function, and pass the logical ID of the Amazon EC2 instance resource to retrieve the instance ID; similarly, pass the logical ID of the Amazon EC2 instance resource, along with the `PublicIp` attribute to the `Fn::GetAtt` function, to retrieve the public IP of the instance.
* Pass the logical ID of the security group resource, along with the `GroupId` attribute, to the `Fn::GetAtt` function to retrieve the ID of the security group.
* Modify the `Outputs` section of the template as shown next:

:::code{language=yaml showLineNumbers=false showCopyAction=true}
Outputs:
  InstanceID:
    Description: The ID of the launched instance
    Value: !Ref Ec2Instance

  PublicIP:
    Description: Public IP of the launched instance
    Value: !GetAtt Ec2Instance.PublicIp

  SecurityGroupId:
    Description: ID of the security group created
    Value: !GetAtt InstanceSecurityGroup.GroupId
:::
:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/resource-return-values`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/resource-return-values
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-resource-return-values-challenge --template-body file://resource-return-values-challenge.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-return-values-challenge/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
1. View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. In the CloudFormation console, select **Create stack With new resources (standard)**.
1. In **Prepare template**, choose **Template is ready**.
1. In **Template source**, select **Upload a template file**.
1. Upload the `resource-return-values-challenge.yaml` template, and choose **Next**.
1. Enter a stack name. For example, `cfn-workshop-resource-return-values-challenge`. When ready, choose **Next**.
1. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
1. In the review page, scroll to the bottom and choose **Submit**.
1. Refresh the page until you see the `CREATE_COMPLETE` status for your stack.
1. View the output value on the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), in the _Outputs_ tab.
::::
:::::
::::::

The full solution for this challenge is available in the `code/solutions/resource-return-values/resource-return-values-challenge.yaml` template.

### Cleanup
Follow the steps below to [delete the stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html) you created as a part of this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. On the **Stacks** page in the CloudFormation console, select the `cfn-workshop-resource-return-values` stack.
3. In the stack details pane, choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.
4. Repeat steps above to delete the `cfn-workshop-resource-return-values-challenge` stack you created.

---
### Conclusion
Great work! You have now learned how to find return values for a specified resource, and how to use them in your templates in other resources using `Ref`, `Fn::GetAtt`, and `Fn::Sub` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html).
