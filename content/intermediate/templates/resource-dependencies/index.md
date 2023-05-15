---
title: "Resource Dependencies"
weight: 200
---

_Lab Duration: ~15 minutes_

---

### Overview

You use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) to programmatically provision resources you describe in your templates. There are cases where a resource depends on one or more resources; for example, an [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instance depends on a Security Group that you wish to use for your Amazon EC2 instance: you describe both resources in a way that you reference the Security Group in the EC2 instance, so that your CloudFormation stack creates the Security Group first, and your Amazon EC2 instance next.

If there are no dependencies between resources you define in a template, CloudFormation initiates the creation of all resources in parallel. There are cases where you either want to, or are [required](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html#gatewayattachment) to define the order in which resources will be created: in these cases, CloudFormation creates some resources before other ones.

In this lab, you will learn how to use the `DependsOn` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html) to explicitly define resource creation order. You will also learn how to use `Ref` and `Fn::GetAtt` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) to have CloudFormation handle the creation order when there are dependencies established.

### Topics Covered

By the end of this lab, you will be able to:

* Understand the usage of the `DependsOn` [resource attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html) to explicitly define resource creation order.
* Use `Ref` and `Fn::GetAtt` [intrinsic functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) to create dependencies between resources.

### Start Lab

#### Lab 1

* Change directory to `code/workspace/resource-dependencies`.
* Open the `resource-dependencies-without-dependson.yaml` file.
* Update the content of the template as you follow along steps on this lab.

In this part of the lab, you will:

* Learn how CloudFormation handles resource creation order when no dependencies are defined.
* Learn how you can explicitly define resource creation order.


Let’s now see how CloudFormation handles the resource creation order when there are no dependencies between resources.

Note the two resources in the template excerpt shown next: an [Amazon Simple Storage Service](https://aws.amazon.com/s3/) (Amazon S3) [bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html), and an [Amazon Simple Notification Service](https://aws.amazon.com/sns/) (Amazon SNS) [topic](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html). Both resources have no dependencies defined between each other.

::alert[The example shown next does not include the `BucketName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#cfn-s3-bucket-bucketname) for the Amazon S3 bucket, and the `TopicName` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#cfn-sns-topic-topicname) for the Amazon SNS topic. In both cases, CloudFormation will generate a unique name for the given resource.]{type="info"}

Copy and append the example content shown next to the `resource-dependencies-without-dependson.yaml` file. Next, you will create a stack, and review stack events to see in which order resources will be created.

```yaml
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop
```

Use the AWS CloudFormation Console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) using the `resource-dependencies-without-dependson.yaml` template:

:::::tabs{variant="container"}

::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/resource-dependencies`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/resource-dependencies
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-resource-dependencies \
--template-body file://resource-dependencies-without-dependson.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-dependencies/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
 1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::

::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. Choose the **Template is ready** option. From **Specify template**, choose **Upload a template file**. Upload the `resource-dependencies-without-dependson.yaml` template, and choose **Next**.
4. Enter a stack name. For example, specify `cfn-workshop-resource-dependencies`. When ready, choose **Next**.
5. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
6. In the **Review** page, scroll to the bottom and choose **Submit**.
::::
:::::

Refresh the page until you see the `CREATE_COMPLETE` status for your stack. Now, let’s review stack events, that should look similar to the image shown next:

![resource-dependencies-lab.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab.png)

Looking at stack events, you can see the creation of the `SNSTopic` and `S3Bucket` resources was initiated at the same time. Since there are no dependencies between the two resources, CloudFormation initiated the creation of both resources in parallel.

Now, think of an example scenario where you want your Amazon S3 bucket to be created first, and only after the bucket is successfully created, the creation of your Amazon SNS topic should start. This is where the use of the `DependsOn` attribute comes into play: you use `DependsOn` to explicitly define a dependency in the `SNSTopic` resource, and provide the logical ID of your Amazon S3 bucket resource (i.e., `S3Bucket` in the example above) as a value for the `DependsOn` attribute. In doing so, CloudFormation will wait for the S3 bucket creation to be completed before initiating the creation of the topic. Let’s take a look!

* Make sure you are in the directory: `code/workspace/resource-dependencies`.
* Open the `resource-dependencies-with-dependson.yaml` file.
* Update the content of the template as you follow along steps on this lab.

Copy and paste the template snippet shown next in the `resource-dependencies-with-dependson.yaml` file; in the next step, you will create a stack and review stack events:

```yaml
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopic:
    Type: AWS::SNS::Topic
    DependsOn: S3Bucket
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop
```


Follow the same steps as above to create a new stack using the `resource-dependencies-with-dependson.yaml` template file. Make sure to provide a different stack name, for example `cfn-workshop-resource-dependencies-dependson`, and create the stack.

This time, your stack events should look different:

![resource-dependencies-lab-dependson.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab-dependson.png)

Now, let’s review the stack events for your new stack. You added the `DependsOn` attribute to the Amazon SNS topic described in the template, and specified the logical ID of the Amazon S3 bucket as a value for the attribute. This resulted in CloudFormation creating the `S3Bucket` resource first, and the `SNSTopic` resource next. Note that when you will delete the stack, the resource that was created first will be the last one to be deleted.

::alert[You can specify a string or a list of strings to the `DependsOn` attribute. For more information, see [DependsOn attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html).]{type="info"}

Congratulations! You have now learned how to explicitly define resource creation order using the `DependsOn` attribute.


#### Lab 2

In this lab, you will learn how CloudFormation handles resource dependencies when you describe a resource property that references the return value of another resource. You reference resource return values with intrinsic functions such as `Ref` and `Fn::GetAtt`, depending on your use case: for example, see which available return values are available for an Amazon SNS [topic](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#aws-properties-sns-topic-return-values) and for an Amazon S3 [bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#aws-resource-s3-bucket-return-values).

Let’s create a stack, and see the resource creation order in action!

* Make sure you are in the directory: `code/workspace/resource-dependencies`.
* Open the `resource-dependencies-with-intrinsic-functions.yaml` file.
* Update the content of the template as you follow along steps on this lab.

Copy, and append the example template snippet shown next to the `resource-dependencies-with-intrinsic-functions.yaml` file:

```yaml
Parameters:
  EmailAddress:
    Description: Enter an email address to subscribe to your Amazon SNS topic.
    Type: String

Resources:
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SNSTopicSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Endpoint: !Ref EmailAddress
      Protocol: email
      TopicArn: !Ref SNSTopic

  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Workshop Security Group
      Tags:
        - Key: Name
          Value: Resource-dependencies-workshop

  SecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupId: !GetAtt SecurityGroup.GroupId
      IpProtocol: tcp
      FromPort: 80
      ToPort: 80
      CidrIp: 0.0.0.0/0
```


There are four resources in the template snippet you pasted into your template: an Amazon SNS [topic](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html), an Amazon SNS [topic subscription](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sns-subscription.html), an Amazon EC2 [Security Group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html), and a [SecurityGroupIngress](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html) resource. Note the following:

* The logical ID of the topic resource, `SNSTopic`, is referenced with `Ref` in the `TopicArn` property of the `SNSTopicSubscription` resource. The `TopicArn` property requires the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) of the topic to which you want to subscribe: the `AWS::SNS::Topic` resource type returns the ARN of the topic when you use the `Ref` intrinsic function. For more information, see Amazon SNS topic [return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#aws-properties-sns-topic-return-values). This implies that CloudFormation waits for the creation of `SNSTopic` to complete before initiating the creation of `SNSTopicSubscription`.
* The logical ID of the security group resource, `SecurityGroup`, is referenced with `Fn::GetAtt` in the `SecurityGroupIngress` resource: your intent here is to specify the ID of the `SecurityGroup` resource for the `GroupId` property of the `SecurityGroupIngress` resource. The `AWS::EC2::SecurityGroup` resource type returns the ID of the security group when you use the `Fn::GetAtt` intrinsic function and pass the `GroupId` attribute to `Fn::GetAtt`. The `Ref` function, instead, returns either the resource ID, or in the case of EC2-Classic or default VPC, the resource name. For more information, see [EC2 Security Group return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-return-values).
* Once the `SecurityGroup` resource is in the `CREATE_COMPLETE` status, the creation of `SecurityGroupIngress` will start. Similarly, after the creation of `SNSTopic`, the `SNSTopicSubscription` resource creation will be initiated.
* Note that there are no dependencies between `SNSTopic` and `SecurityGroup` resources: this means that CloudFormation initiates the creation of both these resources in parallel.

Let’s create a stack, and verify the above behavior. Use the AWS CloudFormation Console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) using the `resource-dependency-with-intrinsic-functions.yaml` template:

:::::tabs{variant="container"}

::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/resource-dependencies`:
:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/resource-dependencies
:::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack --stack-name cfn-workshop-resource-dependencies-ref-getatt \
--template-body file://resource-dependencies-with-intrinsic-functions.yaml \
--parameters ParameterKey="EmailAddress",ParameterValue="your-email-address-here"

:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
:::code{language=shell showLineNumbers=false showCopyAction=false}
"StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-dependencies-ref-getatt/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::

::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. Choose the **Template is ready** option. From **Specify template**, choose **Upload a template file**. Upload the `resource-dependencies-with-intrinsic-functions.yaml` template, and choose **Next**.
4. Enter a stack name. For example, `cfn-workshop-resource-dependencies-ref-getatt`.
5. In the **Parameters** section, provide an email address for Amazon SNS topic subscription; when ready, choose **Next**.
6. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
7. In the review page, scroll to the bottom and choose **Submit**.
::::
:::::


Once the stack is created, your stack events should look like the following:

![resource-dependencies-lab-ref-getatt.png](/static/intermediate/templates/resource-dependencies/resource-dependencies-lab-ref-getatt.png)

Let’s review stack events for your `resource-dependencies-lab-ref-getatt` stack. Note the creation of `SNSTopic` and `SecurityGroup` resources started in parallel, as both resources had no dependencies between each other. Also, note the `SecurityGroupIngress` resource creation started only after the `SecurityGroup` resource was in the `CREATE_COMPLETE` status, and the `SNSTopicSubscription` creation started after the `SNSTopic` resource was successfully created.

When you will delete your stack, CloudFormation follows creation order in reverse: in this case, for example, `SNSTopicSubscription` and `SecurityGroupIngress` resources will be deleted first, followed by `SecurityGroup` and `SNSTopic`.

::alert[You should have received an email, sent to the email address you provided, for you to confirm the subscription to the Amazon SNS topic you created. Choose to follow the subscription link in the subscription confirmation email you received for the topic you created, to subscribe to your topic. Otherwise, when you delete the stack, the subscription will be left in pending state, and you cannot delete it: Amazon SNS will automatically delete the unconfirmed subscription after 3 days. For more information, see [Deleting an Amazon SNS subscription and topic](https://docs.aws.amazon.com/sns/latest/dg/sns-delete-subscription-topic.html).]{type="info"}

Congratulations! You have now learned how CloudFormation handles the resource creation order when you define resource dependencies with `Ref` or `Fn::GetAtt`.


### Challenge

In this section of the lab, you are tasked with updating an existing, example template that describes an Amazon EC2 [instance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html), a [security group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html), and an Amazon S3 [bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html). You will need to reference the security group's logical ID in the `SecurityGroups` property of the Amazon EC2 instance resource. Also, choose to have CloudFormation initiate the Amazon S3 bucket resource creation only after the Amazon EC2 instance resource is created successfully. If you design the template correctly, as per example requirements above, you should be able to observe stack events to be as follows:

* CloudFormation starts the creation of the Security Group resource.
* Once your Security Group is marked as `CREATE_COMPLETE`, the Amazon EC2 instance resource creation starts.
* After successful creation of your Amazon EC2 instance, CloudFormation starts the creation of your Amazon S3 bucket.

To get started, open the `resource-dependencies-challenge.yaml` template, that you can find in the `code/workspace/resource-dependencies` directory, with your favorite code editor. Follow example requirements above, and establish resource dependencies where needed. When ready, create a new stack, called `resource-dependencies-challenge`, and verify stack events match the series described above.

:::expand{header="Need a hint?"}
* How can you [reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) your security group in the `SecurityGroups` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html#cfn-ec2-instance-securitygroups) of your Amazon EC2 instance?
* When you reference your security group, also note that the `Type` of the `SecurityGroups` property value is a _List of String_. How do you represent this value in YAML format?
* How can you [specify](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html) that the creation of a resource should follow another resource?
:::

::::::expand{header="Want to see the solution?"}
* Reference the Security Group's logical ID as a list item under the `SecurityGroups` EC2 instance resource property, by using the `Ref` intrinsic function. CloudFormation should then wait for the Security Group to be created first, and then initiates the Amazon EC2 instance creation.
* Modify the Amazon EC2 instance resource definition as shown next:

```yaml
Ec2Instance:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: !Ref LatestAmiId
    InstanceType: t2.micro
    SecurityGroups:
      - !Ref InstanceSecurityGroup
    Tags:
      - Key: Name
        Value: Resource-dependencies-workshop
```

* Since there is no dependency between the Amazon EC2 instance and the Amazon S3 bucket resources, use the `DependsOn` attribute in the Amazon S3 bucket resource, and provide the Amazon EC2 instance's logical ID as a value for the `DependsOn` attribute.
* Add the `DependsOn` attribute for the Amazon S3 bucket resource as shown next:

```yaml
S3Bucket:
  Type: AWS::S3::Bucket
  DependsOn: Ec2Instance
  Properties:
    Tags:
      - Key: Name
        Value: Resource-dependencies-workshop
```

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
1. In the **Cloud9 terminal** navigate to `code/workspace/resource-dependencies`:
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  cd cfn101-workshop/code/workspace/resource-dependencies
  :::
1. Use the AWS CLI to create the stack. The required parameter `--template-body` have been pre-filled for you.
  :::code{language=shell showLineNumbers=false showCopyAction=true}
  aws cloudformation create-stack --stack-name cfn-workshop-resource-dependencies-challenge \
  --template-body file://resource-dependencies-challenge.yaml
:::
1. If the `create-stack` command was successfully sent, CloudFormation will return `StackId`.
  :::code{language=shell showLineNumbers=false showCopyAction=false}
  "StackId": "arn:aws:cloudformation:us-east-1:123456789012:stack/cfn-workshop-resource-dependencies-challenge/739fafa0-e4d7-11ed-a000-12d9009553ff"
:::
1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** console in a new tab and check if the stack status is **CREATE_COMPLETE**.
::::
::::tab{id="local" label="Local development"}
1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. From **Create stack**, choose **With new resources (standard)**.
1. Choose the **Template is ready** option. From **Specify template**, choose **Upload a template file**. Upload the `resource-dependencies-challenge.yaml` template, and choose **Next**.
1. Enter a stack name. For example, `cfn-workshop-resource-dependencies-challenge` and choose **Next**.
1. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
1. In the review page, scroll to the bottom and choose **Submit**.
::::
:::::
::::::


The full solution for this challenge is available in the `code/solutions/resource-dependencies/resource-dependencies-challenge.yaml` template.

### Cleanup

Follow the steps below to [delete the stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html) you created as a part of this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. On the **Stacks** page in the CloudFormation console, select the `cfn-workshop-resource-dependencies` stack.
3. In the stack details pane, choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.
4. Repeat steps above to delete other stacks you created: `cfn-workshop-resource-dependencies-dependson`, `cfn-workshop-resource-dependencies-ref-getatt`, and `cfn-workshop-resource-dependencies-challenge`.

---
### Conclusion

Great work! You learned how to use `Ref` and `Fn::GetAtt` intrinsic functions to define resource dependencies, as well as the `DependsOn` attribute to explicitly define resource dependencies.
