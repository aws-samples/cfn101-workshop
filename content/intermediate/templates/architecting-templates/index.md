---
title: "Architecting your templates"
weight: 650
---

### Overview

When you describe your infrastructure with code, you want to take into account the ability to scale as your infrastructure grows, as well as its ongoing maintainability over time. The [AWS CloudFormation best practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html) page contains a collection of best practices for you to follow and to adopt in your workflows. In this lab, you will focus on designing your templates by considering _lifecycle and ownership_ aspects for resources you describe with code, as well as _modularity and reuse_ practices, that you will implement in CloudFormation templates by referencing values across stacks within the same account and region, as well as with input parameters for your templates. You can also find other self-paced labs in this workshop that show you examples of best practices, that for example include: [Pseudo parameters](/basics/templates/pseudo-parameters), [Linting and testing](/basics/templates/linting-and-testing), [Dynamic references](/intermediate/templates/dynamic-references) (to reference sensitive information in your AWS CloudFormation templates), [Policy-as-code with Guard](/intermediate/templates/policy-as-code-with-guard) (policy-as-code validation for JSON- and YAML-formatted data).



### Topics Covered

By the end of this lab, you will be able to:

* Learn design patterns that include architecting templates by lifecycle and ownership criteria.
* Learn how to compose stacks by exporting and consuming values for dependencies.
* Learn concepts that illustrate how to reuse modular templates.



### Start Lab

In this lab, you will create an infrastructure that describes an example, simple web application running in the AWS cloud as follows:

* One [Amazon Virtual Private Cloud](https://aws.amazon.com/vpc/) (Amazon VPC), with 2 public and 2 private subnets across 2 [availability zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) of a given region, such as the `us-east-1` region.
* One [Auto Scaling group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html) with a minimum of 2 [Amazon Elastic Compute Cloud](https://aws.amazon.com/ec2/) (Amazon EC2) instances, and a maximum of 4. You'll launch such instances in the 2 private subnets, and you'll use such instances to run a simple web application.
* One [Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/application-load-balancer/) with an Internet-facing endpoint; this load balancer will be fronting your EC2 instances.
* One [Amazon Route 53](https://aws.amazon.com/route53/) [hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html), where you'll store an [alias](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html) record that points to your load balancer. You will not register a domain name as part of running this example lab: you'll create a [private hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html) so that you can make HTTP requests to the sample application from a compute resource - such as an EC2 instance - that you'll launch in the VPC associated with the hosted zone itself. For this, you'll create an [AWS Cloud9](https://aws.amazon.com/cloud9/) environment - that you will use to run parts of this lab - to make HTTP requests to the application you'll deploy.

Before starting the deployment, let's take one step back and think about the application you're going to build. In particular, think about *job roles*. For example, in a company you have different teams owning functions related to security, network, application, database, and so forth. Even if all functions were to be owned by one single team, it is a best practice to architect your templates so that each function for each template can be owned by and mapped to a group of individuals specializing in that function. This also helps with having smaller templates that are easier to troubleshoot, and to reuse; you can further break out such templates into smaller ones as needed. Also, consider organizing resources that persist information - such as a database - and resources that consume that data - for example, a fleet of servers - in separate stacks: not only this helps with potentially mapping dedicate resource owner(s) - such as, a database team maintaining relevant resources - but also makes it easier to troubleshoot and maintain resources over time. If you, for example, describe a database and an entire application stack in the same template, should an issue happen with the stack you'll create next, depending on the nature of the issue you might need - in a worst-case scenario - to delete the stack, and create a new one altogether. Besides narrowing areas of impact, if you describe a database with a separate template this also helps you with potentially reusing the template later on.

Let's take a look at the infrastructure you'll build. Before continuing to next steps, take a moment and think of a reasonable starting point to describe this infrastructure by lifecycle and ownership; how would you do this?

![architecting-templates-infrastructure-diagram.png](/static/intermediate/templates/architecting-templates/architecting-templates-infrastructure-diagram.png)

As a starting point, you'll use steps shown next; note that resources you will describe in each subsequent stack might have dependencies on resources you'll create with the previous one(s):

* One template for your VPC-related resources.
* One template for your hosted zone.
* One template for application and load balancer security groups.
* One template for your application stack, including your load balancer, EC2 instances, and a DNS record to add to the hosted zone you created with a previous template.

You will also use another template to describe your Cloud9 environment (not shown in the diagram above).

With the strategy shown earlier, you have not only designed your templates by taking into account ownership (e.g., a networking team to own the VPC-related resources, a security team to own security group resources, an application team to own the infrastructure and the deployment of their application), but also by lifecycle. As an example, if you need to roll out a new version of the application, and you want to create a new application stack for a cut-over to it, you don't have to necessarily redeploy or update (unless needed) all the other existing stacks that describe application infrastructure dependencies.

::alert[If you would have gotten a database as part of the example infrastructure shown above, you would have chosen to describe it in a separate template as well. Also, you could have chosen to describe its security group in the same template where you also described security groups for the application stack, so that you could have referenced ingress/egress rules for it from the application security group in the same template, in addition to exporting database security group information you would have consumed in a subsequent stack that would have created the database itself.]{type="info"}



### Prerequisites

You'll use Cloud9 later on for this lab; first, you'll begin with using your workstation. Start with fetching the CloudFormation Workshop code repository content into your workstation: for this, you can choose between two options:

- Option 1 (faster, no tools to install in your workstation): navigate to the [CloudFormation Workshop repository page in GitHub](https://github.com/aws-samples/cfn101-workshop); locate the **Code** button, and choose **Download ZIP** from the dropdown menu. This action should result in a `cfn101-workshop-main.zip` file, containing the content of the workshop in the `main` branch of the repository, that you'll download and expand in your workstation in a directory of your choice.
- Option 2: use [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) to clone the CloudFormation Workshop repository. For this, make sure that you have `git` installed in your workstation, or install it with a method of your choice. When ready, follow the **Clone lab resources** section in [Get lab resources](/prerequisites/local-development) to clone the lab repository. This will clone the repository into a `cfn101-workshop` directory in your workstation.


Next, change directory to the `cfn101-workshop/code/workspace/architecting-templates` directory of the repository that you have either expanded from the ZIP file, or cloned. Locate the `base-network.template` file and the `cloud9.template` file: you'll first use them to create the base infrastructure and your Cloud9 environment respectively.



### Creating the VPC stack

Let's get started! As you describe your infrastructure with CloudFormation, take a look at how example templates you'll use in this lab are connected together with a series of dependencies, that are exported in one stack and imported into another one(s).

Create a new stack with the `base-network.template` file:

1. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/).
2. From the region selector on the top of the page, choose a region - such as *N. Virginia* (`us-east-1`).
3. From **Create stack**, choose **With new resources (standard)**.
4. From **Prepare template**, choose **Template is ready**.
5. From **Template source**, choose **Upload a template file**. Choose the `base-network.template` file mentioned earlier, and then choose **Next**.
6. Specify a stack name: `cloudformation-workshop-dev-base-network`. Choose to accept default parameter values, and then choose **Next**.
7. On the subsequent page, choose **Next**.
8. Choose **Create stack** in the next page.

Stack creation will start: at the end of it, you should see your stack in the `CREATE_COMPLETE` status. As the creation of your stack proceeds, open the `base-network.template` file in your favorite text editor in your workstation. Note the following:

* As you want to create your subnets in separate availability zones within a region (for example, `us-east-1a`, `us-east-1b` availability zones in the `us-east-1` region), you specify the `AvailabilityZone` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html) for each subnet. Instead of hard-coding the availability zone name (such as `us-east-1a`), the example template uses the `Fn::Sub` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) (shown in the template using its YAML short form, `!Sub`) to concatenate the name of the region (e.g., `us-east-1`, derived from the `AWS::Region` [pseudo parameter](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-region)) with either `a` or `b`, such as with: `AvailabilityZone: !Sub '${AWS::Region}a'`. This way, it is easier for you to reuse this template across regions by making the template more portable.
* In the `Outputs` section of the template, note the values of resources that you want to [export](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-exports.html), so that you can consume such values in subsequent stack(s) you will create next. You create an export with a given name, so that you can reference that name and consume the export's value in another stack(s). Each export must be unique per account and per region: in the sample template, each export's name contains the stack name as a prefix (note the `AWS::StackName` pseudo parameter being used with `Fn::Sub` as described earlier). As a stack name must be unique in a given account and region as well, the choice of the stack name as a prefix is a reasonable choice to start with. Of course, you want to make sure the suffix you will choose will give you a unique export name within the account and region as well, when you combine it with your prefix. Ultimately, as long as the export name you choose is unique, and easy to consume or to derive in subsequent stacks with a consistent naming convention, that is what matters.



### Creating your Cloud9 environment

Next, you'll create a Cloud9 environment that you'll use for 2 goals: to continue the deployment of the infrastructure for this lab, and to validate the DNS configuration within your VPC's scope. Before deploying your Cloud9 environment, let's see how you consume an export in the template that describes the environment itself: open the `cloud9.template` file with your favorite text editor, and note the value for the `SubnetId` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cloud9-environmentec2.html#cfn-cloud9-environmentec2-subnetid) of the `AWS::Cloud9::EnvironmentEC2` resource type. In order to use your Cloud9 environment's EC2 instance to test the resolution of the DNS record in the private hosted zone as mentioned earlier, you'll launch the instance in a subnet that belongs to the same VPC you'll associate to the private hosted zone itself. In this lab, you choose to specify the first public subnet you created earlier: for this, you'll reference the name of the export whose value holds the ID of the first subnet. The example first composes the name of the export for the first public subnet, by concatenating the name of the stack where you exported the intended value (you'll pass this stack name as an input parameter to `cloud9.template`) to the suffix you chose in the VPC stack: `Fn::Sub: ${NetworkStackName}-PublicSubnet1Id`. With the composed name of the export, you consume its value with the `Fn::ImportValue` [intrinsic function](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html), that is shown in the example template in its YAML short form. For more information on cross-stack references, see the **Note** section for `Fn::ImportValue` on this [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html).

Let's create the Cloud9 environment! You'll use the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/) as you did earlier:

1. Make sure you are in the same region you chose earlier, such as *N. Virginia* (`us-east-1`).
2. From **Create stack**, choose **With new resources (standard)**.
3. From **Prepare template**, choose **Template is ready**.
4. From **Template source**, choose **Upload a template file**. Choose the `cloud9.template` file, and then choose **Next**.
5. Specify a stack name: `cloudformation-workshop-dev-cloud9`. Choose to accept default parameter values, and choose **Next**.
6. On the subsequent page, choose **Next**.
7. Choose **Create stack** in the next page.
8. Refresh the stack creation page until you see your stack in the `CREATE_COMPLETE` status: note that another stack will be created as well, whose name prefix should read `aws-cloud9-aws-cloudformation-workshop-`: this stack creates the security group and the EC2 instance for your Cloud9 environment.
9. When ready, open your Cloud9 environment: navigate to the [AWS Cloud9 Console](https://console.aws.amazon.com/cloud9/home), locate the `aws-cloudformation-workshop` environment, and choose **Open IDE**. Your environment should then open in another window.



### Installing `cfn-lint`

As part of the software development life cycle (SDLC), early testing is key to start to find and correct issues whilst you are developing your code, to *shorten the feedback loop and save time*. As part of best practices when working with CloudFormation, you want to validate that your templates are not only using either a valid JSON or YAML data structure, but that also conform to the [AWS CloudFormation resource specification](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html). This way, if you specify an incorrect resource property name or value for example, you have the opportunity to detect this very early in the SDLC, as you develop your templates in your workstation.

To validate your templates, you'll now use the [AWS CloudFormation Linter](https://github.com/aws-cloudformation/cfn-lint): in your Cloud9 environment, locate the command line terminal at the bottom of the page: first, create and activate a new virtual environment for Python with `virtualenv` as shown next:

:::code{language=shell showLineNumbers=false showCopyAction=true}
mkdir ~/my-virtual-environments
virtualenv ~/my-virtual-environments/cloudformation-workshop-venv
source ~/my-virtual-environments/cloudformation-workshop-venv/bin/activate
:::

The last command above should have activated the virtual environment you created: your shell prompt should indicate so with the `(cloudformation-workshop-venv)` prefix added to it. You'll now install, into your virtual environment scope for your current terminal, `cfn-lint` by running the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
pip install cfn-lint
:::

::alert[Should you close your current terminal in Cloud9 and then reopen a new one, make sure you run again the command: `source ~/my-virtual-environments/cloudformation-workshop-venv/bin/activate` to activate your previously created virtual environment in your new terminal.]{type="info"}

You'll see an example of using `cfn-lint` later on, as you continue to deploy your infrastructure. For a deeper dive into CloudFormation testing tools with this workshop, see the [Linting and testing](/basics/templates/linting-and-testing) lab. Note that you can also run `cfn-lint` as a plugin for a [supported editor](https://github.com/aws-cloudformation/cfn-lint#editor-plugins) of your choice in your workstation. You can also choose, for your projects, to run `cfn-lint` as a `pre-commit` [hook](https://github.com/aws-cloudformation/cfn-lint#pre-commit).

::alert[As part of a fail-fast strategy and of SDLC processes you use, you also want to include compliance validation checks to verify the infrastructure you describe with code is compliant to controls that your company needs and wants to put in place. As an example, tools and features for CloudFormation include [AWS CloudFormation Guard](https://docs.aws.amazon.com/cfn-guard/latest/ug/what-is-guard.html) and [AWS CloudFormation Hooks](https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/hooks.html) which are not discussed in this lab. As part of this CloudFormation workshop, you can choose try the [Policy-as-code with Guard](/intermediate/templates/policy-as-code-with-guard) lab.]{type="info"}



### Continuing the deployment from your Cloud9 environment

Continue with the deployment of your resources. This time, you'll use the [AWS Command Line Interface](https://aws.amazon.com/cli/) (AWS CLI) to create your stacks. The AWS CLI is already included with Cloud9: as a future reference, for more information on how to install it in your own workstation, see [Getting started with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

To continue the deployment of your infrastructure, you first want to clone this lab's repository into your Cloud9 environment. Make sure you run the command below from within the `~/environment` directory, as shown next:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd ~/environment
git clone https://github.com/aws-samples/cfn101-workshop.git
:::

Next, change directory to `cfn101-workshop/code/workspace/architecting-templates/`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cd cfn101-workshop/code/workspace/architecting-templates/
:::



### Running cfn-lint

Run `cfn-lint` against template files for this lab you'll find in the `architecting-templates` directory:

:::code{language=shell showLineNumbers=false showCopyAction=true}
cfn-lint *.template
:::

You should not see any output being emitted by the command above: this means there are no errors. The command verified that your templates conform to the resource type specifications as mentioned earlier. In this lab, you started to deploy resources for your VPC and for your Cloud9 environment directly, to focus on template architecture examples and to prepare your workspace: as part of best practices, you want to run `cfn-lint` before deploying your resources or adding your templates to a repository, so that you have an opportunity to save time and to make changes earlier in the process.

To illustrate an example of `cfn-lint`'s capabilities, use the *Environment* navigation tab on the left side in Cloud9 to expand to the `aws-cloudformation-workshop -> cfn101-workshop-> code -> workspace -> architecting-templates` directory, and open the `hosted-zone.template` file.  Locate the `Name: !Ref 'HostedZoneName'` line, and temporarily change it into `Names: !Ref 'HostedZoneName'` (you temporarily changed the `Name` property into `Names`). Next, run `cfn-lint` as you did earlier, and you should see an error similar to the following output excerpt:

:::code{language=shell showLineNumbers=false showCopyAction=false}
E3002 Invalid Property Resources/HostedZone/Properties/Names
:::

Here, `cfn-lint` tells you that the property you specified is not valid for the resource whose [logical ID](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html) is `HostedZone`. As you can see, you have an early check opportunity to validate your template from a linting perspective.

::alert[Before proceeding to create the hosted zone next, do not forget to change `Names` back to `Name`.]{type="warning"}



### Creating the hosted zone

Open the `hosted-zone.template` file in Cloud9. Note the following:

* In this lab, you want to associate this hosted zone you are about to create to your VPC: you can see how this example template implements this if you look at the configuration for the `AWS::Route53::HostedZone` resource type, where you reference the ID of your VPC. For this, you first compose the name of the export with `Fn::Sub: ${NetworkStackName}-VpcId`, and then you consume the value of the export with the outer `!ImportValue` declaration.
* After you create the hosted zone, you will create an application stack that will consume hosted zone information: in the application stack, you will describe a DNS alias record pointing to the load balancer you will create with the same stack, and you will need to know where to store this record. In the `hosted-zone.template` file, you will export the ID and the name of the hosted zone in the `Outputs` section, so that you can consume this information later, in the application stack.

Now that you have familiarized with the business logic described in this template, it's time to create the hosted zone! You'll use the AWS CLI for this, that is already installed in your Cloud9 environment. First, create a new stack called `cloudformation-workshop-dev-hosted-zone` with the `hosted-zone.template` file and in the `us-east-1` region:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-hosted-zone \
    --template-body file://hosted-zone.template \
    --region us-east-1
:::

This will result in an output similar to the following excerpt:

:::code{language=json showLineNumbers=false showCopyAction=false}
{
    "StackId": "arn:aws:cloudformation: [...]"
}
:::

Wait for the stack creation to complete with the following command (alternatively, navigate to the CloudFormation console, and wait until the stack is in `CREATE_COMPLETE` status):

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-hosted-zone \
    --region us-east-1
:::

At the end of the stack creation, you'll have a Route 53 private hosted zone. Look at default template parameters you used to create the stack: the hosted zone name is called `my-example-domain.com`. Navigate to the [Route 53 Console](https://console.aws.amazon.com/route53/home); from **Hosted zones** choose the hosted zone you created and, in the details page, you'll see there are already two DNS record types, `NS` and `SOA`: later on, you will use CloudFormation to create an alias record for your load balancer, and that record should also show up in this details page.



### Creating security groups

Open the  `security-groups.template` file in Cloud9. This example template describes 2 security groups: one for the load balancer you'll create, and one for EC2 instances running the example web application. Note how both security groups consume the VPC ID in a similar way you've seen earlier. Note also how security group IDs are exported in the `Outputs` section for you to later consume such from the application stack.

Create your security groups with a new stack, called `cloudformation-workshop-dev-security-groups`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-security-groups \
    --template-body file://security-groups.template \
    --region us-east-1
:::

and wait for its creation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-security-groups \
    --region us-east-1
:::



### Creating the application stack

Open the  `application.template` file in Cloud9. This template describes the deployment of your application, by using an application load balancer, and an Auto Scaling group of EC2 instances. Note the following:


* For testing easily in this lab, you'll use an HTTP listener for the load balancer.
* The Auto Scaling group [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html) uses a `LaunchTemplate` [resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-launchtemplate.html) to bootstrap each instance. In particular, from within the `UserData` property underneath `LaunchTemplateData`, you can see how [CloudFormation helper scripts](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) are first set up in each instance with `yum update -y aws-cfn-bootstrap`, and then how the `cfn-init` [helper script](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html) is used to install packages (such as `httpd`), and to set up content: as an example, note the value of the `/var/www/html/index.html` web application file being referenced from a sample template parameter, with a default value of `Hello world!`
* The `cfn-signal` [helper script](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html) in the `UserData` section is set up to communicate to CloudFormation whether the instance has been successfully created or updated. Moreover, the `cfn-hup` [helper](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-hup.html) is set up to detect `Metadata` changes as you update the stack (note the detection `interval` is set to check every 2 minutes in this example, instead of the `15` that is the default value), and helps with applying changes as needed.
* The Auto Scaling group uses a `CreationPolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html) with a `Timeout` set to 15 minutes, within which to receive at least 2 `Count` signals - one from each of the 2 instances - to determine whether the instance bootstrap succeeded. If such signals are not received within 15 minutes, the stack will roll back.
* The Auto Scaling group also uses an `UpdatePolicy` [attribute](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html) with an `AutoScalingRollingUpdate` [policy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html#cfn-attributes-updatepolicy-rollingupdate): if you update the stack and a relevant resource update is triggered, the policy will update one instance at a time as specified in `MaxBatchSize`, whilst leaving a minimum of 2 instances in service (see `MinInstancesInService`). Moreover, `PauseTime` in conjunction with `WaitOnResourceSignals` tells CloudFormation to wait for 15 minutes (`PT15M`) for the Auto Scaling group to receive successful signals from instances that are either added or replaced.

Deploy the application and its infrastructure with a new stack, called `cloudformation-workshop-dev-application`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application.template \
    --region us-east-1
:::

and wait for its creation to complete:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation wait stack-create-complete \
    --stack-name cloudformation-workshop-dev-application \
    --region us-east-1
:::

At the end of the deployment, you should have a stack that created your application, including an alias Route 53 record: you'll go in more details next, when you'll validate your deployment worked as intended for this lab.



### Validating your deployment

You'll perform a two-step validation by:

* Connecting to the load balancer URL, and verifying the content you get in an HTTP response is the one intended as part of this lab's examples.
* Issuing an HTTP request to the URL that uses the alias record, and verifying that the HTTP response is the same to the one you got in the previous step.



#### Validating by connecting to the load balancer URL

From the CloudFormation Console, choose your `cloudformation-workshop-dev-application` stack, and then choose `Outputs`. Open, in a new tab of your browser, the link you'll find for the `AppUrl` output value: you should see an `Hello world!` output being displayed.



#### Validating by connecting to the URL with the DNS record value

With the `application.template` file open in Cloud9, locate the resource of type `AWS::Route53::RecordSet`. This resource creates an alias record of type `A` in the private hosted zone (referenced in `HostedZoneId` via the export whose name is derived from `${HostedZoneStackName}-HostedZoneId`). The value for the `Name` alias record is an entry called `my-example-domain.com`, that in this example is the same as the zone apex of the domain.

As you've created a private hosted zone in this lab (in lieu of registering a domain pointing to a public hosted zone instead), you should be able to resolve the alias record above from within the context of your VPC. This means that your Cloud9 environment, whose EC2 instance you created in your VPC, should be able to perform the name resolution successfully. From the console terminal in Cloud9, issue the following command:

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

You should see `Hello world!` as the output, that is the same output you saw earlier.

Congratulations! You have successfully performed and verified the deployment of a sample application and of its infrastructure with CloudFormation!



### Challenge

In this challenge, you'll recall and apply key concepts related to reuse and modularity, and extend them in terms of deployment orchestration. You are tasked with copying the `application.template` file (that is in your workspace in Cloud9) into a new file called `application-blue-green.template`, and to update this new file so that you can use it for 2 stacks in the context of a blue/green deployment pattern where you'll [Update DNS Routing with Amazon Route 53](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/update-dns-routing-with-amazon-route-53.html). Requirements in this example challenge are as follows:

* Have 2 stacks: update the existing one you created, called `cloudformation-workshop-dev-application`, and create a new one called `cloudformation-workshop-dev-application-v2`, showing `Blue` and `Green` as outputs, respectively, instead of `Hello world!`. Let's refer to both stacks as to *Blue* and *Green*, respectively. Use the new `application-blue-green.template` file for both stacks.
* Each stack should create a new alias record whose `Name` is the same to the one you used earlier (the hosted zone name). Both of these records though will need to be a [weighted set](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-weighted.html#rrsets-values-weighted-weight), so that Route 53 will respond to a query you issue based on the [ratio of the weight for a given resource to the total of weights](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-weighted.html). Initially, you want to assign a weight of `255` (more weight) to the *Blue* stack, and `1` (less weight) to the *Green* stack: this way, *Blue* initially gets 255/256ths of traffic, and *Green* gets 1/256ths of traffic.
* Make sure you update the _set identifier_ in the template, so that its value will be unique for each of the 2 stacks that will use that same template.

A diagram illustrating the desired state for this lab's example is shown next:

![architecting-templates-blue-green-diagram.png](/static/intermediate/templates/architecting-templates/architecting-templates-blue-green-diagram.png)

Reference the CloudFormation documentation [page](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html) for the `AWS::Route53::RecordSet` resource type to identify which properties to add or update to satisfy requirements above.

Once you created the two stacks, validate with `curl` that the `my-example-domain.com` alias points initially mostly to *Blue*. Next, flip weight values for alias records you create in both stacks, so that when you test again most traffic goes mostly to *Green* instead (that is, loads version 2 of your example app whose output reads `Green`).



:::expand{header="Need a hint?"}

* Look into reusing the example `PageTextContent` template parameter, so that you add new values you can use to demonstrate and validate that you are running either `Blue` or `Green` for a given stack that uses the template.
* Refer to, and use the `SetIdentifier` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-setidentifier). Choose a way to specify a unique value for this property depending on whether you launch the *Blue* or the *Green* stack.
* Refer to, and use the `Weight` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-weight).
* You will not need to specify the `Region` [property](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#cfn-route53-recordset-region) in your updated record set.
:::



::::expand{header="Want to see the solution?"}

The complete solution is available in the `application-blue-green.template` file, that you can find on the `code/solutions/architecting-templates` directory.

Instead, for a step-by-step guide instead, follow the following steps to update your workspace copy of the `application-blue-green.template` file:

* Add the following `AllowedValues` to the `PageTextContent` sample input parameter, in 2 separate lines and by taking care of indentation as needed: `- Blue`, and `- Green`.
* Add a new template parameter, `RecordSetWeight`. Set its `Type` to `Number`, its `Default` value to `0`, its `MinValue` to `0`, and its `MaxValue` to `255`.  Add a `Decription` to tell the user what is the purpose of the parameter.
* Update the set identifier with a value that will be unique for both records in the hosted zone. Update the `SetIdentifier` property for the record set, as in this example: `SetIdentifier: !Sub '${AppNameTagValue} application managed with the ${AWS::StackName} stack.'`
* Add the `Weight` property for the `AWS::Route53::RecordSet` resource type, to reference the `RecordSetWeight` template parameter: `Weight: !Ref 'RecordSetWeight'`.
* Remove the `Region: !Ref 'AWS::Region'` line from the recordset resource.
* Update the existing stack: `cloudformation-workshop-dev-application`, with the new application-blue-green.template file. Pass `Blue` as a parameter value for `PageTextContent`, and `255` for `RecordSetWeight`. Example:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Blue \
        ParameterKey=RecordSetWeight,ParameterValue=255
:::

* Create a new stack, called `cloudformation-workshop-dev-application-v2`, to which you pass `Green` as a parameter value for `PageTextContent`, and `1` for `RecordSetWeight`. Example:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation create-stack \
    --stack-name cloudformation-workshop-dev-application-v2 \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Green \
        ParameterKey=RecordSetWeight,ParameterValue=1
:::

* Once both operations are complete, test that the `my-example-domain.com` record mainly points to `Blue`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

* Next, update both stacks, and swap `RecordSetWeight` values:

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Blue \
        ParameterKey=RecordSetWeight,ParameterValue=1

aws cloudformation update-stack \
    --stack-name cloudformation-workshop-dev-application-v2 \
    --template-body file://application-blue-green.template \
    --parameters \
        ParameterKey=PageTextContent,ParameterValue=Green \
        ParameterKey=RecordSetWeight,ParameterValue=255
:::

* Once stack updates are complete, test that the `my-example-domain.com` record now mainly points to `Green`:

:::code{language=shell showLineNumbers=false showCopyAction=true}
curl http://my-example-domain.com
:::

::::



### Clean up

Navigate to the CloudFormation Console on your workstation. Select and delete, in the following order, stacks you created in this lab. *Note that since you used cross-stack references a number of stacks, you cannot delete a stack that exports a value if that value is still used by a consuming stack*:

1. Delete `cloudformation-workshop-dev-application-v2` and `cloudformation-workshop-dev-application` without waiting for each one of them to be deleted; such stacks do not depend on each other. When both stacks are deleted, continue with the next step.
2. Delete `cloudformation-workshop-dev-security-groups` and `cloudformation-workshop-dev-hosted-zone` without waiting for each one of them to be deleted as well. Then, continue with next steps.
3. Delete `cloudformation-workshop-dev-cloud9`: note that when you delete this stack, the delete action you start should also cause the deletion the stack whose name starts with `aws-cloud9-aws-cloudformation-workshop-`. When both stacks are deleted, continue with the last step.
4. Delete the `cloudformation-workshop-dev-base-network` stack.


### Conclusion

Congratulations! You have learned and practiced how to design your templates for lifecycle and ownership, and on how to use a number of pseudo parameters and intrinsic functions to favor reusability and modularity. You have also learned how to compose stack creations by exporting and importing values, and on how to reuse a template with an example blue-green deployment pattern.
