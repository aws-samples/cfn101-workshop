---
title: "Default VPC"
weight: 400
---
A default VPC is suitable for getting started quickly, and for launching public instances such as a blog or simple website.

**[Basics](../../Basics)** part of the workshop requires that a default VPC is available in the region you will be deploying CloudFormation templates to.

You will have a default VPC unless you have removed it. If you are unsure, follow the instructions below to check.

If you have deleted your default VPC, you can create a new one by following one of the options below.

### 1. Create a default VPC using the Amazon VPC console

1. Open the Amazon VPC console at [https://console.aws.amazon.com/vpc/](https://console.aws.amazon.com/vpc/).
1. In the navigation pane, choose **Your VPCs**.
1. Choose **Actions**, **Create Default VPC**.
1. Choose **Create**. Close the confirmation screen.

### 2. Create a default VPC using the command line

First we will check if a default VPC is present or not. We will use the AWS CLI to list all existing VPCs in the region

1. Copy the code below to your terminal. Make sure to change the `--region` flag to use a region that you are going to be deploying your CloudFormation to.

   :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[].VpcId" --region eu-west-2
    :::

If the default VPC exists, it will be included here. Assert that `IsDefault` key is `true` and [move to the next step](../../Basics). You can skip the remainder of this section.

If the response is empty `[]` or the VPC is not **default** proceed to the next step. A default VPC does not exist in this region.

1. Copy the code below to your terminal. Make sure to change the --region flag to use a region that you are going to be deploying your CloudFormation to.

   :::code{language=shell showLineNumbers=false showCopyAction=true}
    aws ec2 create-default-vpc --region eu-west-2
    :::

    The result will be a new default VPC created, and the response in the terminal will look like the sample below.

   :::code{language=json showLineNumbers=false showCopyAction=false}
    {
        "Vpc": {
            "CidrBlock": "172.31.0.0/16",
            "DhcpOptionsId": "dopt-c1422ea9",
            "State": "pending",
            "VpcId": "vpc-088b5ae6628fbf3ac",
            "OwnerId": "123456789012",
            "InstanceTenancy": "default",
            "Ipv6CidrBlockAssociationSet": [],
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-0ab2ffabcbe0548bc",
                    "CidrBlock": "172.31.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": true,
            "Tags": []
        }
    }
    :::

   ::alert[If you wish to delete the default VPC again at the end of this workshop you should make a note of the **VpcId** above so that you can be sure to know which one to delete later.]{type="info"}
