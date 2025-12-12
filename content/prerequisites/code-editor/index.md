---
title: "Code Editor Setup (Recommended)"
weight: 200
---

_Setup Duration: ~5 minutes_

## Overview

Code Editor is an open-source remote integrated development environment (IDE) that lets you write, run, and debug your code with just a browser - think of it as VS Code running in a browser. It includes a code editor, debugger, and terminal. We have included the libraries and tools you will need during the workshop.

For the best experience and minimal setup effort, we recommend using Code Editor to run this workshop at AWS-hosted events because it comes with the necessary set of tools pre-installed and the workshop repository already cloned. If you prefer to work locally, follow the [Local Development Setup](/prerequisites/local-development) instead.

:::alert{type="info"}
Code Editor is automatically provisioned for you at AWS-hosted events. If you are running this workshop on your own, please use the [Local Development Setup](/prerequisites/local-development) instead.
:::

## Accessing your AWS Account

After joining the event, you should see the page with event information and workshop details. You should also see a section titled "AWS account access" on the left navigation bar. You can use these options to access the temporary AWS account provided to you.

![workshop-studio-account-access](/static/prerequisites/code-editor/workshop-studio-account-access.png)

### AWS Management Console

The "AWS console" link will open the AWS Management Console home page. This is the standard AWS Console that provides access to each service. Please note that the infrastructure associated with the workshop will be deployed to a specific region and can only be accessed from that region.

## Login to your Code Editor environment

You can find the URL for the Code Editor in the Output section of the [Workshop welcome](https://catalog.us-east-1.prod.workshops.aws/event/dashboard/) page:

![code-editor-url](/static/prerequisites/code-editor/code-editor-url.png)

Once you click on the URL, you will be presented with the IDE you will be using for the remaining of the labs. The commands can be performed in the terminal section in the bottom part of the window (if the terminal panel is not toggled automatically, click on the second left-most small icon at the top right of your screen):

![code-server-welcome](/static/prerequisites/code-editor/code-server-welcome.png)

## Workshop Files

The workshop repository has been pre-cloned for you in the `/cfn101-workshop` directory. The templates and code you will work on are located in the **code** folder.

Expand the tree on the left to open the **code** folder and explore the workshop files.

:::alert{type="info"}
No need to run `git clone` - the workshop code is already available in your environment!
:::

## Best Practices

- Review the terms and conditions of the event. Do not upload any personal or confidential information in the account.
- The AWS account will only be available for the duration of this workshop, and you will not be able to retain access after the workshop is complete. Backup any materials you wish to keep access to after the workshop.
- Any pre-provisioned infrastructure will be deployed to a specific region. Check your workshop content to determine whether other regions will be used.

---

Congratulations, your workshop development environment is now ready to use!
