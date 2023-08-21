---
title: "Looping over collections with Fn::ForEach"
weight: 641
---

_Lab Duration: ~45 minutes_

---

### Overview

When you describe infrastructure with code, there are use cases where the code you write describes resources that share the same configuration, or that contains some differences that could be managed with mechanisms like variables. As the number of such resources and relevant properties grow, the code you write grows as well, thus making it not easy to maintain over time, and prone to human errors.

In the [Language extensions](../language-extensions) lab, you’ve used the `AWS::LanguageExtensions` [transform](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-languageextensions.html) to leverage a number of functions that extend the [AWS CloudFormation](https://aws.amazon.com/cloudformation/) language: such functions are the result of feedback that the CloudFormation team receives from the community via open discussions driven by an [RFC mechanism](https://github.com/aws-cloudformation/cfn-language-discussion). One of these functions is the `Fn::ForEach` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-foreach.html), that you’ll learn how to use in this lab. This intrinsic function allows you to describe resources, that share the same/similar configuration, with dynamic iterations that you use to map resource configurations to loop-like structures.

### Topics Covered

By the end of this lab, you will be able to:

* Identify example use cases where you can simplify and reduce statically-described code, for resources that share the same/similar configuration, using `Fn::ForEach`.
* Describe, with code, the desired state of resources by using `Fn::ForEach` to loop over collections.
*  Discover, for applicable use cases, how you can use `Fn::ForEach` to have fewer lines of code, thus leading to code that is easier to maintain, and less prone to human errors.

### Start lab

### Lab part 1: basic looping over a collection for S3 buckets

Let’s start with an example use case: you’re tasked with describing 3 [Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) buckets that will have a number of configuration properties in common, for example [bucket encryption](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-bucketencryption.html) set to use [AWS Key Management Service (AWS KMS)](https://aws.amazon.com/kms/), [lifecycle configuration](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-lifecycleconfig.html) set to transition to the `GLACIER` [storage class](https://aws.amazon.com/s3/storage-classes/) after 30 days and to expire objects after 1 year, `PublicAccessBlockConfiguration` [properties](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket-publicaccessblockconfiguration.html) set to `true`, and tags set to use `aws-cloudformation-workshop` as the tag value for the `Name` tag key.

S3 buckets you’re tasked to describe with code share the same properties in this use case. While you certainly can describe all of them with three discrete code blocks, in this lab you choose to use `Fn::ForEach` to reduce the code size and relative complexity, so that you describe all the three buckets once with a single, iterative structure. This also has the benefit of having code that is easier to maintain, and it helps with reducing human errors as well.

If you were to describe the three S3 buckets above *without* `Fn::ForEach`, the resulting template would be something like the following one, shown here as an example:

:::code{language=yaml showLineNumbers=false showCopyAction=false}
AWSTemplateFormatVersion: "2010-09-09"

Description: AWS CloudFormation workshop lab - sample S3 buckets with the same configuration settings.

Resources:
  S3Bucket1:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop

  S3Bucket2:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop

  S3Bucket3:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
      LifecycleConfiguration:
        Rules:
          - ExpirationInDays: 365
            Id: Example Glacier Rule
            Status: Enabled
            Transitions:
              - StorageClass: GLACIER
                TransitionInDays: 30
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Name
          Value: aws-cloudformation-workshop
:::

In this lab, you choose to use `Fn::ForEach` to describe the S3 bucket configuration properties only once, by looping over a collection of buckets. This means that, in this case, the initial template you'll use will have fewer lines of code, thus making it easier to maintain. As a result, you’ll have a template, processed by the `AWS::LanguageExtensions` transform, that will describe content like the above, with three S3 bucket resources having the same properties but different [logical IDs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html), such as `S3Bucket1`, `S3Bucket2`, and `S3Bucket3`.

Let’s get started! Navigate to the `code/workspace/looping-over-collections` directory, and open the `s3-buckets.yaml` file in your favorite text editor.

::alert[Note the `Transform: AWS::LanguageExtensions` line, that is already present in the `s3-buckets.yaml` template you just opened (you've already used this transform in the [Language extensions](../language-extensions) lab). This line activates the language extension [transform](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-languageextensions.html), that is *required* in order to use the `Fn::ForEach` intrinsic function.]{type="warning"}

With the `s3-buckets.yaml` file opened in your text editor, remove the TODO reminder line that is commented out, and append the code shown next to the `Resources` section (indentation matters - make sure the leading character of the `Fn::ForEach::S3Buckets` line starts at column number `2` in your editor):

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=8}
  Fn::ForEach::S3Buckets:
    - S3BucketLogicalId
    - [S3Bucket1, S3Bucket2, S3Bucket3]
    - ${S3BucketLogicalId}:
        Type: AWS::S3::Bucket
        Properties:
          BucketEncryption:
            ServerSideEncryptionConfiguration:
              - ServerSideEncryptionByDefault:
                  SSEAlgorithm: aws:kms
          LifecycleConfiguration:
            Rules:
              - Id: Example Glacier Rule
                ExpirationInDays: 365
                Status: Enabled
                Transitions:
                  - TransitionInDays: 30
                    StorageClass: GLACIER
          PublicAccessBlockConfiguration:
            BlockPublicAcls: true
            BlockPublicPolicy: true
            IgnorePublicAcls: true
            RestrictPublicBuckets: true
          Tags:
            - Key: Name
              Value: aws-cloudformation-workshop
:::

Save the updated file to disk. Looking at the code you just pasted, you note that the content starting from the `Type: AWS::S3::Bucket` line is something you’ve seen in the example at the beginning of this lab: it is the same set of properties that all the three S3 buckets have in common. Let’s look into the lines that are above `Type: AWS::S3::Bucket` to understand how `Fn::ForEach` works!

In this example, you want to iterate over a three-element collection, that is composed of the three S3 buckets. You choose to create this collection as `[S3Bucket1, S3Bucket2, S3Bucket3]`, and use each of the elements, that are denoted by the `S3BucketLogicalId` identifier described above the collection itself. In this example, you described the collection as an array, but you could also have used a reference to a template [parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html) of type  `CommaDelimitedList`.

On the top of the code you pasted, you note the `Fn::ForEach::S3Buckets:` line, that describes the intent of using `Fn::ForEach` to iterate over a collection. The rightmost part of the line, `S3Buckets`, indicates the name you choose for the loop. When you create a loop, make sure you indicate a name that is unique within the template: do not choose a name used for another loop in the template, and that you used or plan to use for the logical ID of a resource in the same template.

The line right above `Type: AWS::S3::Bucket`, that is `${S3BucketLogicalId}:`, denotes the `OutputKey` content that you’ll find in the template that will be transformed. In this case, the value of `OutputKey` will be the logical ID of each of the 3 S3 buckets: `S3Bucket1` in the first loop iteration, `S3Bucket2` in the second, and `S3Bucket3` in the third.

The lines starting with `Type: AWS::S3::Bucket` and below, in the example, constitute the `OutputValue` that will be replicated for each `OutputKey` in the processed template. These lines contain the common configuration that will be applied to the three S3 bucket resources with the logical IDs mentioned in the previous paragraph.

::alert[CloudFormation uses service quotas that are applied to the processed template. For more information on CloudFormation service quotas, see [AWS CloudFormation quotas](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cloudformation-limits.html) in the CloudFormation User Guide.]{type="warning"}

It’s now time to create a new CloudFormation stack, to see how your three S3 buckets will be provisioned by looping over the collection you described above! You'll create a new stack in the `us-east-1` region.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Run the following AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name looping-over-collections-s3-buckets \
--template-body file://s3-buckets.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

The command above should return the ID of the stack you are creating. Wait until the stack is in the `CREATE_COMPLETE` status by using the [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

::::
::::tab{id="local" label="Local development"}
Steps:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you are in the **US East (N. Virginia)** region.
1. From the left navigation panel, select the **Stacks** tab.
1. From the right side of the page, choose **Create Stack**, and then choose **With new resources (standard).**
1. From **Prerequisite**-**Prepare template**, choose **Template is ready**.
1. Under **Specify template**, select **Template source**, and choose **Upload a template file**.
1. Select **Choose file**, and provide the `s3-buckets.yaml` template you updated earlier. Choose **Next**.
1. In the **Specify Stack details** page, specify a **Stack** name: `looping-over-collections-s3-buckets`. Choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
1. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.
::::
:::::

When stack creation is complete, navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/), and locate the `looping-over-collections-s3-buckets` stack. Select the stack, and then select the **Template** pane. Note the following:

* you should see the initial template you provided, that uses the loop over the collection of buckets you described;
* choose **View processed template**: you should see the expanded template, that instead of the looping structure shows the three S3 buckets statically described, as a result of the processing. Note that you’ll see the processed configuration in JSON format;
* navigate to the **Resources** tab, and note the 3, newly-created S3 buckets whose logical IDs should be `S3Bucket1`, `S3Bucket2`, and `S3Bucket3`.

Congratulations! You have completed the first part of this lab, and have learned the basics of `Fn::ForEach`. In the next part, you’ll go over a new example with more moving parts.

### Lab part 2: inner loops for VPC-related resources

In this part of the lab, you’ll learn how to nest `Fn::ForEach` looping structures, when needed. Recall the usage of `Fn::ForEach` above: you pass the following parameters to the intrinsic function, right below the definition of the unique loop:

* `Identifier`
* `Collection`
* `OutputKey`

In the previous example, you have used `${S3BucketLogicalId}:` as the `OutputKey` for the logical ID of each bucket you wanted to create. In this example, you’ll use another `Fn::ForEach` loop instead for the `OutputKey`, to drive an inner looping logic for a new use case: the creation of resources related to an [Amazon Virtual Private Cloud (Amazon VPC)](https://aws.amazon.com/vpc/) resource.

Let’s get started! Make sure you are in the `code/workspace/looping-over-collections` directory, and open the `vpc.yaml` file in your favorite text editor. Note the `Transform: AWS::LanguageExtensions` line in the code, that is *required* for the `Fn::ForEach` intrinsic function you’ll use next. The template already describes a VPC [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html), an `InternetGateway` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-internetgateway.html), and a `VPCGatewayAttachment` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc-gateway-attachment.html) without the use of `Fn::ForEach`, because you’re defining such resources only once in the template. In the template, you can also find a `Mappings` [section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html) with a number of settings for the VPC and VPC-related resources that you’ll use next.

Remove the TODO reminder line in the file you just opened, and append the code shown next, to start describing public and private subnets. Make sure the level of indentation is the same as for the `VpcGatewayAttachment` resource declaration (that is, starting at column `2`):

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=63}
  Fn::ForEach::SubnetTypes:
    - SubnetType
    - [Public, Private]
    - Fn::ForEach::SubnetNumbers:
        - SubnetNumber
        - ["1", "2"]
        - ${SubnetType}Subnet${SubnetNumber}:
            Type: AWS::EC2::Subnet
            Properties:
              AvailabilityZone: !Select
                - !FindInMap
                  - SubnetAzIndexes
                  - !Ref SubnetType
                  - !Ref SubnetNumber
                - !GetAZs ""
              CidrBlock: !FindInMap
                - SubnetCidrs
                - !Ref SubnetType
                - !Ref SubnetNumber
              Tags:
                - Key: Name
                  Value: aws-cloudformation-workshop
              VpcId: !Ref Vpc
:::

The code you added above shows the intent of describing two public subnets, and two private subnets for a total of 4 `AWS::EC2::Subnet` resources.

With the first `Fn::ForEach::SubnetTypes` loop, you iterate over the collection of subnet types (public and private), and with the second, inner loop (that you are using here as your `OutputKey`), you iterate through each subnet (subnet 1 and subnet 2, using the strings `["1", "2"]` in the collection), of a specific type (public, private).

::alert[The numbers `1` and `2`, that are elements of the `["1", "2"]` example collection, are represented here as quoted because a collection must be a list of strings.]{type="warning"}

In the `OutputKey` section of the inner loop, `${SubnetType}Subnet${SubnetNumber}`, you compose the name of the logical ID of each resource that, respectively, will be `PublicSubnet1`, `PublicSubnet2`, `PrivateSubnet1`, and `PrivateSubnet2` as both outer and inner loops iterate through the collections (`[Public, Private]`, and `["1", "2"]`) that you defined in the loops.

In each inner loop iteration, besides the four logical IDs above, each resource will have its properties configured to pull CIDR addressing information from the `SubnetCidrs` mapping via the `Fn::FindInMap` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html), as well as the indexes to use when selecting Availability Zones for subnets with the `Fn::GetAZs` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html). The intent with the configuration used for the indexes in the `SubnetAzIndexes` mapping is to create public and private subnets with ID 1 in the same Availability Zone, and public and private subnets with ID 2 in a different Availability Zone: the reason behind this choice is to optimize Availability Zone-related traffic, so to have resources for a private subnet in the same Availability Zone as the NAT gateway, that you associate to the relevant public subnet (for example, to have `PrivateSubnet1` use the NAT gateway target that is associated to `PublicSubnet1`). For more information, see [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) in the Amazon VPC User Guide.

Other properties, for subnets, that will be replicated over inner loop iterations also include `Tags` and `VpcId`.

Let’s continue to describe other resources you’ll need: this time, you want to describe two public and two private route tables, and then associate such route tables to the relevant subnets you defined above. Add the following code to the existing inner loop (make sure the indentation is correct: the column where `${SubnetType}RouteTable${SubnetNumber}` starts must be the same as where `${SubnetType}Subnet${SubnetNumber}` above starts, which is column `10`):

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=86}
          ${SubnetType}RouteTable${SubnetNumber}:
            Type: AWS::EC2::RouteTable
            Properties:
              Tags:
                - Key: Name
                  Value: aws-cloudformation-workshop
              VpcId: !Ref Vpc
          ${SubnetType}SubnetRouteTableAssociation${SubnetNumber}:
            Type: AWS::EC2::SubnetRouteTableAssociation
            Properties:
              RouteTableId: !Ref
                Fn::Sub: ${SubnetType}RouteTable${SubnetNumber}
              SubnetId: !Ref
                Fn::Sub: ${SubnetType}Subnet${SubnetNumber}
:::

With the above, you create four route tables (two public, and two private) with the first block and, with the second block, you associate them to the relevant subnets you’re defining within the same inner loop iterations.

Now that you have the subnets you need for this lab’s example use case, and that each subnet has a route table associated to it, it’s time to add default routes to all IPv4 destinations (`0.0.0.0/0`) that are assumed to be a requirement in your example use case as well. Now, while the `0.0.0.0/0` CIDR is going to be the same for routes you’ll assign to both public and private subnets, public routes will need the `InternetGateway` you created earlier as a target, whereas private subnets will need a Network Address Translation (NAT) mechanism instead. You then choose to describe public and private routes with two separate, new loop iterations to decouple public from private routes in specialized business logic for each type.

Let’s start with creating routes for public subnets first, that we’ll add to the public route tables you described earlier; here, you create a new loop that you’ll indent 2 columns to the right (that is, column number `2`); add the content below to the `vpc.yaml` file:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=101}
  Fn::ForEach::DefaultRoutesForPublicSubnets:
    - SubnetNumber
    - ["1", "2"]
    - DefaultRouteForPublicSubnet${SubnetNumber}:
        DependsOn: VpcGatewayAttachment
        Type: AWS::EC2::Route
        Properties:
          RouteTableId: !Ref
            Fn::Sub: PublicRouteTable${SubnetNumber}
          DestinationCidrBlock: 0.0.0.0/0
          GatewayId: !Ref InternetGateway
:::

With the new loop above, you described 2 `AWS::EC2::Route` resources for public subnets - that is, each is configured to be a default route with the `InternetGateway` (that is already described in the template you're using for this lab) as a target.

::alert[The `AWS::EC2::Route` resources described above use the `DependsOn` attribute to add an explicit dependency on the VPC gateway attachment. The same is also true for `AWS::EC2::EIP` resources you'll define next. See [When a DependsOn attribute is required](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-dependson.html#gatewayattachment) to learn more on why these resources need `DependsOn` in the current context.]{type="warning"}

You’ll now need to set up routes for private subnets. For this, you choose to create a new loop where you describe 2 `AWS::EC2::EIP` [resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-eip.html), that you’ll use for 2 `AWS::EC2::NatGateway` resources you’ll define in this new loop as well later on. You’ll also describe two routes for private subnets that will have each NAT gateway as a target, respectively. Add the following code for the new loop to the template:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=113}
  Fn::ForEach::NatGateways:
    - SubnetNumber
    - ["1", "2"]
    - Eip${SubnetNumber}:
        DependsOn: VpcGatewayAttachment
        Type: AWS::EC2::EIP
        Properties:
          Domain: vpc
      NatGateway${SubnetNumber}:
        Type: AWS::EC2::NatGateway
        Properties:
          AllocationId: !GetAtt
            - !Sub Eip${SubnetNumber}
            - AllocationId
          SubnetId: !Ref
            Fn::Sub: PublicSubnet${SubnetNumber}
          Tags:
            - Key: Name
              Value: aws-cloudformation-workshop
      DefaultRouteForPrivateSubnet${SubnetNumber}:
        Type: AWS::EC2::Route
        Properties:
          RouteTableId: !Ref
            Fn::Sub: PrivateRouteTable${SubnetNumber}
          DestinationCidrBlock: 0.0.0.0/0
          NatGatewayId: !Ref
            Fn::Sub: NatGateway${SubnetNumber}
:::

In the code above, note the logical IDs for the two elastic IP resources you’re creating (`Eip${SubnetNumber}`), the logical IDs for the two NAT gateways (`NatGateway${SubnetNumber}`), and the logical IDs for the two routes for private subnets (`DefaultRouteForPrivateSubnet${SubnetNumber}`).

Moreover, note the `AllocationId` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-natgateway.html#cfn-ec2-natgateway-allocationid) of the NAT gateway resource: when you describe this property, you use the `Fn::GetAtt` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html) to consume the allocation ID of the relevant elastic IP resource, by passing the logical ID of the elastic IP resource as well. In the example above, you first use the `Fn::Sub` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) to compose the logical ID of each elastic IP resource (`!Sub Eip${SubnetNumber}`), and then you use the `Ref` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html) to pass the composed logical ID as a reference for the relevant resource described in the template (in this case, described as part of a looping iteration). The `RouteTableId` property for `AWS::EC2::Route` resources uses a similar logic (`Fn::Sub: PrivateRouteTable${SubnetNumber}`) when composing the logical ID of the route table. The same also holds true for the `SubnetId` property of the `AWS::EC2::NatGateway` resource.

It’s now time to provision the infrastructure for the VPC-related resources you described with code! Save the `vpc.yaml` file with all the changes you’ve been applying along this part of the lab, and follow the indications below to create a new stack, called `looping-over-collections-vpc`, using the `vpc.yaml` file. You'll create the new stack in the `us-east-1` region.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Run the following AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
--stack-name looping-over-collections-vpc \
--template-body file://vpc.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

The command above should return the ID of the stack you are creating. Wait until the stack is in the `CREATE_COMPLETE` status by using the [wait stack-create-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-create-complete.html) AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="Local development"}
Steps:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you are in the **US East (N. Virginia)** region.
1. From the left navigation panel, select the **Stacks** tab.
1. From the right side of the page, choose **Create Stack**, and then choose **With new resources (standard).**
1. From **Prerequisite**-**Prepare template**, choose **Template is ready**.
1. Under **Specify template**, select **Template source**, and choose **Upload a template file**.
1. Select **Choose file**, and provide the `vpc.yaml` template you updated earlier. Choose **Next**.
1. In the **Specify Stack details** page, specify a **Stack** name: `looping-over-collections-vpc`. Choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
1. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.
::::
:::::

Once you created the new stack with the method of your choice, continue to follow directions you found in part 1 of the lab to navigate to the **Template** and **Resources** sections, this time for the `looping-over-collections-vpc` stack: compare the template you provided with the processed one, to see how the code maintainability has improved with the method of looping over collections.

Congratulations! You completed the second part of the lab, and learned how to use inner loops when needed in more complex use cases.

### Challenge

In this challenge, you’re tasked with adding the IDs of public and private subnets to the `Outputs` [section](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) of the `vpc.yaml` file, using `Fn::ForEach`. Requirements for outputs are:

* add the `Outputs` section in the `vpc.yaml` template;
* add a meaningful description for each output, so that it will contain text composed such as:
    * `The ID of PublicSubnet1.`
    * `The ID of PublicSubnet2.`
    * `The ID of PrivateSubnet1.`
    * `The ID of PrivateSubnet2.`
* Add the `Value` for each output, as a reference to the relevant subnet ID.
* Add the `Export` [name](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html) for each output, so that you can [consume](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html) it from other stacks in the future. Create the name of each export using this pattern: `YOUR_AWS_ACCOUNT_ID-SUBNET_TYPESubnetSUBNET_NUMBERId`; example for the first public subnet: `111122223333-PublicSubnet1Id`.

:::expand{header="Need a hint?"}
* Use the same outer + inner loops logic you followed to create the two public and the two private subnets, and apply it to content you'll write underneath the `Outputs` section.
* Make sure you recall how to describe the [structure](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html) of an output when you build the looping logic for your outputs.
* When you describe the `Value` of each output, you’ll need to reference the logical ID of a subnet, but you need to compose it first using `Fn::Sub`. Look at the example pattern you used for composing the referenced value for `RouteTableId` in the inner loop you used to describe `AWS::EC2::Route` resources, or the `SubnetId` property of the `AWS::EC2::NatGateway` resource.
* Is there a [pseudo parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html) you can use to return the ID of the current AWS account you're using?
:::

::::::expand{header="Want to see the solution?"}
The complete solution is available in the `vpc.yaml` file, that you can find on the `code/solutions/looping-over-collections` directory.

Append the following content to the `vpc.yaml` file:

:::code{language=yaml showLineNumbers=true showCopyAction=true lineNumberStart=141}
Outputs:
  Fn::ForEach::SubnetIdsOutputs:
    - SubnetType
    - [Public, Private]
    - Fn::ForEach::SubnetNumbers:
        - SubnetNumber
        - ["1", "2"]
        - ${SubnetType}Subnet${SubnetNumber}:
            Description: !Sub 'The ID of ${SubnetType}Subnet${SubnetNumber}.'
            Export:
              Name: !Sub ${AWS::AccountId}-${SubnetType}Subnet${SubnetNumber}Id
            Value: !Ref
              Fn::Sub: ${SubnetType}Subnet${SubnetNumber}
:::

Next, update the existing `looping-over-collections-vpc` stack with the updated template containing the `Outputs` information below.

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Run the following AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
--stack-name looping-over-collections-vpc \
--template-body file://vpc.yaml \
--region us-east-1 \
--capabilities CAPABILITY_AUTO_EXPAND
:::

Wait until the stack is in the `UPDATE_COMPLETE` status by using the [wait stack-update-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-update-complete.html) AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-update-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="Local development"}
Steps:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you are in the **US East (N. Virginia)** region.
1. From the left navigation panel, select the **Stacks** tab.
1. Choose the existing `looping-over-collections-vpc` stack from the list of stacks.
1. From the right side of the page, choose **Update Stack**.
1. From **Prerequisite**-**Prepare template**, choose **Replace current template**.
1. Under **Specify template**, select **Template source**, and choose **Upload a template file**.
1. Select **Choose file**, and provide the `vpc.yaml` template you updated earlier. Choose **Next**.
1. In the **Specify Stack details** page, choose **Next**.
1. On **Configure Stack options**, leave the configuration as it is. Choose **Next**.
1. On the **Review** page, review the contents of the page. At the bottom of the page, choose to acknowledge all the capabilities shown in the **Capabilities and transforms** section. Choose **Submit**.
1. Refresh the stack creation page until you see the stack to be in the `CREATE_COMPLETE` status.
::::
:::::

When the stack update is complete, you should be able to see the outputs in the `Outputs` pane for the stack in the CloudFormation console.
::::::

### Clean up

You'll now delete the resources you created as part of this lab. Use the following steps:

:::::tabs{variant="container"}
::::tab{id="cloud9" label="Cloud9"}
Delete the `looping-over-collections-s3-buckets` stack, by running the following AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

Wait until the `DELETE` operation is complete, by using the [wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--region us-east-1 \
--stack-name looping-over-collections-s3-buckets
:::

When done, repeat the steps above to delete the `looping-over-collections-vpc` stack:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation delete-stack \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

Wait until the `DELETE` operation is complete, by using the [wait stack-delete-complete](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/wait/stack-delete-complete.html) AWS CLI command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-delete-complete \
--region us-east-1 \
--stack-name looping-over-collections-vpc
:::

::::
::::tab{id="local" label="Local development"}
Steps:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
1. Make sure you are in the **US East (N. Virginia)** region.
1. From the **Stacks** page, select the `looping-over-collections-s3-buckets` stack.
1. In the stack details pane, choose **Delete**. Select **Delete** when prompted.
1. From the **Stacks** page, select the `looping-over-collections-vpc` stack.
1. In the stack details pane, choose **Delete**. Select **Delete** when prompted.
::::
:::::

### Conclusion

Great work! You learned how to loop over collections using the `Fn::ForEach` intrinsic function and the `AWS::LanguageExtensions` transform. For more information, see [Fn::ForEach](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-foreach.html) in the AWS CloudFormation User Guide, and the [Exploring Fn::ForEach and Fn::FindInMap enhancements in AWS CloudFormation](https://aws.amazon.com/blogs/devops/exploring-fnforeach-and-fnfindinmap-enhancements-in-aws-cloudformation/) blog post. We welcome your contributions to RFCs and your feedback in our [cfn-language-discussion](https://github.com/aws-cloudformation/cfn-language-discussion) GitHub repository!
