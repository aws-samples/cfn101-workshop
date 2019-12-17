---
title: 'Install and configure the AWS CLI'
date: 2019-10-18T12:51:19+01:00
weight: 200
---

The [AWS CLI](https://aws.amazon.com/cli/) allows you to interact with AWS services from a terminal session.
Make sure you have the latest version of the AWS CLI installed on your system.
 
 * macOS and Linux: [Bundled installer](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html#install-bundle-other)
 * Windows: [MSI installer](https://docs.aws.amazon.com/cli/latest/userguide/install-windows.html#install-msi-on-windows)

See the [AWS Command Line Interface installation](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) page for more details.

## Configure your credentials

Open a terminal window and run `aws configure` to set up your environment. Type
the **access key ID** and **secret key** you create in [the previous step](../100-account) and choose a default region (you can
use `us-east-1`, `eu-west-1`, `us-west-2` for example). Preferably use a region
that doesn't have any resources already deployed into it.

    aws configure


And fill in the information from the console:

    AWS Access Key ID [None]: <type key ID here>
    AWS Secret Access Key [None]: <type access key>
    Default region name [None]: <choose region (e.g. "us-east-1", "eu-west-1")>
    Default output format [None]: <leave blank>
