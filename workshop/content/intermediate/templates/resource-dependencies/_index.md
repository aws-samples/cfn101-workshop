---
title: 'Resource Dependencies'
date: 2022-02-03T22:04:02Z
weight: 200
---

### Overview

You use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) to programmatically provision resources you describe in your templates. There are cases where a resource depends on one or more resources; for example, an [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instance depends on a Security Group that you wish to use for your EC2 instance: you describe both resources in a way that you reference the Security Group in the EC2 instance, so that your CloudFormation stack creates the Security Group first, and your EC2 instance next.

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

Copy and append the example content shown next to the `resource-dependencies-without-dependson.yaml` file. Next, you will create a stack, and review stack events to see in which order resources will be created.

```yaml
Parameters:
  BucketName:
    Description: Enter a unique name for S3 bucket.
    Type: String

  SNSTopicName:
    Description: Enter a name for SNS topic.
    Type: String

Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName

  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref SNSTopicName
```

Use the AWS CloudFormation Console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) using the `resource-dependencies-without-dependson.yaml` template:


1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. Choose the **Template is ready** option. From **Specify template**, choose **Upload a template file**. Upload the `resource-dependencies-without-dependson.yaml` template, and choose **Next**.
4. Enter a stack name. For example, `resource-dependencies-lab`.
5. In the **Parameters** section, provide unique values for `BucketName` and `SNSTopicName` parameters. When ready, choose **Next**.
6. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
7. In the **Review** page, scroll to the bottom and choose **Create stack**.


Refresh the page until you see the `CREATE_COMPLETE` status for your stack. Now, let’s review stack events, that should look similar to the image shown next:

![resource-dependencies-lab.png](resource-dependencies/resource-dependencies-lab.png)

Looking at stack events, you can see the creation of the `SNSTopic` and `S3Bucket` resources was initiated at the same time. Since there are no dependencies between the two resources, CloudFormation initiated the creation of both resources together.

Now, think of an example scenario where you want the S3 bucket to be created first, and only after the bucket is successfully created, the SNS topic creation should start. This is where the use of the `DependsOn` attribute comes into play: you explicitly define the dependency on the `SNSTopic` resource, and provide the logical ID of the S3 bucket resource (i.e.,`S3Bucket` in the example above) as a value. In doing so, CloudFormation will wait for the S3 bucket creation to be completed before initiating the creation of the SNS topic. Let’s take a look!

* Make sure you are in the directory: `code/workspace/resource-dependencies`.
* Open the `resource-dependencies-with-dependson.yaml` file.
* Update the content of the template as you follow along steps on this lab.

Copy and paste the template snippet shown next in the `resource-dependencies-with-dependson.yaml` file; in the next step, you will create a stack and review stack events:

```yaml
Parameters:
  BucketName:
    Description: Enter a unique name for S3 bucket.
    Type: String

  SNSTopicName:
    Description: Enter a name for SNS topic.
    Type: String

Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName

  SNSTopic:
    Type: AWS::SNS::Topic
    DependsOn: S3Bucket
    Properties:
      TopicName: !Ref SNSTopicName
```


Follow the same procedure as above to create a new stack using `resource-dependencies-with-dependson.yaml`  template file. Make sure to provide a different stack name this time, for example `resource-dependencies-lab-dependson`. Provide unique values for `BucketName` and `SNSTopicName` parameters, and create the stack.

This time, your stack events should look different:

![resource-dependencies-lab-dependson.png](resource-dependencies/resource-dependencies-lab-dependson.png)

Now, let’s review the stack events for your new stack. You added the `DependsOn` attribute to the SNS topic resource in the template, and specified the logical ID of the S3 bucket resource. This resulted in CloudFormation creating the `S3Bucket` resource first, and the `SNSTopic` resource next. When you delete the stack, the resource that was created first will be the last one to be deleted.


Congratulations! You have now learned how to explicitly define resource creation order using the `DependsOn` attribute.


#### Lab 2

In this lab, you will learn how CloudFormation automatically handles resource dependencies when a resource property references the return value of another resource. You reference resource return values with intrinsic functions such as `Ref` or `Fn::GetAtt`, depending on your use case. As an example, see which available output values are available for an SNS [topic](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#aws-properties-sns-topic-return-values) and for an S3 [bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html#aws-resource-s3-bucket-return-values).

Let’s create a stack, and see the resource creation order in action!

* Make sure you are in the directory: `code/workspace/resource-dependencies`.
* Open the `resource-dependencies-with-intrinsic-functions.yaml` file.
* Update the content of the template as you follow along steps on this lab.

Paste the contents of the template snippet shown next in `resource-dependencies-with-intrinsic-functions.yaml` file:

```yaml
Parameters:
  SNSTopicName:
    Description: Enter a name for SNS topic.
    Type: String

  EmailAddress:
    Description: Enter an email address to subscribe to SNS topic.
    Type: String

  SecuirtyGroupName:
    Description: Enter a name for security group
    Type: String

Resources:
  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Ref SNSTopicName

  SNSTopicSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      Endpoint: !Ref EmailAddress
      Protocol: email
      TopicArn: !Ref SNSTopic

  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for CloudFormation lab
      GroupName: !Ref SecuirtyGroupName

  SecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupId: !GetAtt SecurityGroup.GroupId
      IpProtocol: tcp
      FromPort: 80
      ToPort: 80
      CidrIp: 0.0.0.0/0
```


There are four resources in the template snippet you pasted into your template: [SNS topic](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html), [SNS topic subscription](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sns-subscription.html), [an EC2 Security Group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html), and an [ingress rule for the Security Group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group-ingress.html). Note the following:

* The logical ID of the SNS topic resource, `SNSTopic`, is referenced with `Ref` in the `TopicArn` property of the `SNSTopicSubscription` resource. This is because the `AWS::SNS::Topic` resource type returns the [Amazon Resource Name](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html) (ARN) of the SNS topic when you use the `Ref` intrinsic function: for more information, see [SNS topic return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-sns-topic.html#aws-properties-sns-topic-return-values). This implies that CloudFormation waits for the creation of `SNSTopic` to complete before initiating the creation of `SNSTopicSubscription`.
* The logical ID of the security group resource, `SecurityGroup`, is referenced with `Fn::GetAtt` in the `SecurityGroupIngress` resource: your intent here is to specify the ID of the `SecurityGroup` resource for the the `GroupId` property. The `AWS::EC2::SecurityGroup` resource type returns the ID of the security group when you use the `Fn::GetAtt` intrinsic function and pass the `GroupId` attribute to `Fn::GetAtt`, whereas the `Ref` function returns the name of the security group instead. For more information, see[EC2 Security Group return values](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html#aws-properties-ec2-security-group-return-values).
* Once the `SecurityGroup` resource is in `CREATE_COMPLETE` status, the creation of `SecurityGroupIngress` will start. Similarly, after the creation of `SNSTopic`**,** the `SNSTopicSubscription` resource creation will be initiated.
* Note that there are no dependencies between `SNSTopic` and `SecurityGroup` resources: this means that CloudFormation initiates the creation of both these resources in parallel.

Let’s create a stack, and verify this is the behavior you expect. Use the AWS CloudFormation Console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) using the `resource-dependency-with-intrinsic-functions.yaml` template:


1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From **Create stack**, choose **With new resources (standard)**.
3. Choose the **Template is ready** option. From **Specify template**, choose **Upload a template file**. Upload the `resource-dependencies-with-intrinsic-functions.yaml` template, and choose **Next**.
4. Enter a stack name. For example, `resource-dependencies-lab-ref-getatt`.
5. In the **Parameters** section, provide a unique name for the SNS topic, an email address for SNS Topic subscription, and a name for security group; when ready, choose **Next**.
6. Choose to accept default values on the **Configure stack options** page; scroll to the bottom of the page, and choose **Next**.
7. In the review page, scroll to the bottom and choose **Create stack**.


Once the stack is created, your stack events should look like in the following screenshot:

![resource-dependencies-lab-ref-getatt.png](resource-dependencies/resource-dependencies-lab-ref-getatt.png)

Let’s review stack events for your `resource-dependencies-lab-ref-getatt` stack. Note the creation of `SNSTopic` and `SecurityGroup` resources started in parallel, as both resources had no dependencies between each other. Also, note the `SecurityGroupIngress` resource creation started only after the `SecurityGroup` resource was in the `CREATE_COMPLETE` status, and the `SNSTopicSubscription` creation started after the `SNSTopic` resource was successfully created.

When you delete your stack, CloudFormation follows creation order in reverse: in this case, for example, `SNSTopicSubscription` and `SecurityGroupIngress` resources will be deleted first, followed by `SecurityGroup` and `SNSTopic`.

{{% notice note %}}
As part of the stack creation, you should have received an email for the email address you provided for the SNS subscription, to confirm the topic subscription. Please choose the **Confirm subscription** option in the email you received, to successfully subscribe to the SNS topic: doing this is important because when you delete the stack, CloudFormation will not be able to delete subscriptions that are in pending state.
{{% /notice %}}

Kudos! You have now learned how CloudFormation automatically handles resource creation order when you define resource dependencies with `Ref` or `Fn::GetAtt`.


### Challenge

Design a template to create an [EC2 instance](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html), a [security group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html) and an [S3 bucket](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-s3-bucket.html). Reference the security group logical ID in the EC2Instance resource for the `SecurityGroups` property. Your intent is to have CloudFormation initiate the S3 bucket resource creation only after the EC2 instance resource is created successfully. If you design the template correctly, as per the requirements, you should be able to observe stack events as follows:

* Security Group resource creation is initiated.
* Once the security group is marked as `CREATE_COMPLETE`, the EC2 instance resource creation starts.
* After successful completion of the EC2 instance resource creation, CloudFormation should initiate the creation of S3 bucket.

To get started, refer to the `resource-dependencies-challenge.yaml` template in the `code/workspace/resource-dependencies` directory: you will need to establish the resource dependencies as needed. Follow the above procedure to define the dependency, and verify stack events match the above series.

{{%expand "Need a hint?" %}}

* How can you [reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html) the security group for your instance?
* How can you [specify](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html) that the creation of a resource should follow another resource?
{{% /expand %}}

{{%expand "Want to see the solution?" %}}

* Reference the Security Group's logical ID as a list under the `SecurityGroups` EC2 instance resource property, by using the `Ref` intrinsic function. CloudFormation should then wait for the Security Group to be created first, and then initiates the EC2 instance creation.
* Modify the EC2 instance resource definition as shown next:

```yaml
  Ec2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t2.micro
      SecurityGroups:
        - !Ref InstanceSecurityGroup
```

* Since there is no dependency between the EC2 instance and the S3 bucket, use the `DependsOn` attribute in the S3 bucket resource, and provide the EC2 instance's logical ID as a value for the `DependsOn` attribute.
* Add the `DependsOn` attribute for the S3 bucket resource as shown next:

```yaml
  S3Bucket:
    Type: AWS::S3::Bucket
    DependsOn: Ec2Instance
    Properties:
      BucketName: !Ref S3BucketName
```
{{% /expand %}}

Create a new stack, called `resource-dependencies-challenge`, with your updated `resource-dependencies-challenge.yaml` template, and verify stack events are shown as in the sequence mentioned earlier.

The full solution for this challenge is available in the `code/solutions/resource-dependencies/resource-dependencies-challenge.yaml` template.

### Cleanup

Follow the steps below to [delete the stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html) you created as a part of this lab:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. On the **Stacks** page in the CloudFormation console, select the `resource-dependencies-lab` stack.
3. In the stack details pane, choose **Delete** to delete the stack, and then choose **Delete stack** to confirm.
4. Repeat steps above to delete the other two stacks you created: `resource-dependencies-lab-dependson` and `resource-dependencies-lab-ref-getatt`.

### Conclusion

Great work! You learned how to use `Ref` and `Fn::GetAtt` intrinsic functions to define resource dependencies, as well as the `DependsOn` attribute to explicitly define resource dependencies.
