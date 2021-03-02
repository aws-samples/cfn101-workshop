---
title: 'Lab 06: Multi Region Latest AMI'
date: 2019-11-07T13:46:21Z
weight: 100
---

### Overview
Consider the use case of deploying your current template in different regions. You would need to manually change `AmiID` property in your template to match the AMI ID for each AWS Region. Similarly, if there is an update to the Amazon Machine Image, and you would like to use the latest image, the same manual process would apply.

To fix this, you can use the existing _Parameters_ section of your CloudFormation template and define Systems Manager parameter type. A Systems Manager parameter type allows you to reference parameters held in the System Manager Parameter Store.

### Topics Covered
In this Lab, you will learn:

+ How to query **[AWS Systems Manager Parameter Store](https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)** in CloudFormation to get the latest Amazon Linux AMI ID.

### Start Lab

1. Go to the `code/30-launching-ec2` directory.
1. Open the `01-lab06-SSM.yaml` file.
1. Update the `AmiID` parameter to:

    ```yaml
      AmiID:
        Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
        Description: The ID of the AMI.
        Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'
   ```

Go to the AWS console and update your stack with a new template.

1. Open the **[AWS CloudFormation](https://console.aws.amazon.com/cloudformation)** link in a new tab and log in to your AWS account.
1. Click on the stack name, for example **cfn-workshop-ec2**.
1. In the top right corner click on **Update**.
1. In **Prepare template**, choose **Replace current template**.
1. In **Template source**, choose **Upload a template file**.
1. Click on **Choose file** button and navigate to your workshop directory.
1. Select the file `01-lab06-SSM.yaml` and click **Next**.
1. For **Amazon Machine Image ID** copy and paste in `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2`
1. For **EnvironmentType** select the different environment than is listed. For example if you have **Dev** selected, choose **Test** and click **Next**.
1. You can leave **Configure stack options** default, click **Next**.
1. On the **Review <stack_name>** page, scroll down to the bottom and click on **Update stack**.
1. You can click the **refresh** button a few times until you see in the status **UPDATE_COMPLETE**.

{{%expand "How do I update a Stack?" %}}
![update-2](100-lab-06-ami/update-2.gif)
{{% /expand %}}

### Challenge
Deploy the template in different AWS Region to the one you have been using.

{{%expand "Solution" %}}
![new-region-](100-lab-06-ami/new-region-1.gif)
{{% /expand %}}

{{% notice note %}}
Notice, that you did not have to update AMI ID parameter. By using CloudFormation's integration with Systems
Manager Parameter Store, your templates are now more generic and reusable.
{{% /notice %}}

---
### Conclusion

Congratulations! You have now successfully updated your template to use the latest Amazon Linux AMI. Furthermore, your template can now be deployed in any region, without appending AMI ID parameter.
