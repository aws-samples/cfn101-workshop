---
title: 'Create an AWS Account'
date: 2019-10-18T12:55:54+01:00
weight: 100
---

## Create an AWS Account for Experimentation

To deploy our app, you'll need access to an AWS account. If you already have an account, and your system is configured with credentials of an administrator user, you can [move to the next step](../200-awscli).

{{% notice warning %}}
If you are using an existing account, either personal or a company account, make sure you understand the implications and policy of provisioning resources into this account.
{{% /notice %}}

If you don't have an AWS account, you can [create a free account here](https://portal.aws.amazon.com/billing/signup).

## Administrator User

1. Sign in to your AWS account
1. Go to the AWS IAM console and [create a new user](https://console.aws.amazon.com/iam/home?#/users$new).
1. Type a name for your user (e.g. `cfn-workshop`) and choose both, **Programmatic access** and **AWS Management Console Access**.

    ![new-user-1-png](100-account/new-user-1.png)

1. Click **Next: Permissions** to continue to the next step.
1. Click **Attach existing policies directly** and choose **AdministratorAccess**.

    ![new-user-2-png](100-account/new-user-2.png)

1. Click **Next: Tags**
1. Click **Next: Review**
1. Click **Create User**
1. In the next screen, you'll see your **Access key ID**, and you will have the option to click **Show** to show the **Secret access key**.

    ![new-user-3-png](100-account/new-user-3.png)

{{% notice info %}}
Important: Keep this browser window open for the next step or take a note of the access key ID and secret access key.
{{% /notice %}}
