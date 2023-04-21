---
title: "Use Cloud9 IDE"
weight: 200
---

## What is Cloud9

AWS Cloud9 is a cloud-based IDE that lets you write, run, and debug your code with just a browser. It includes a code editor, debugger, and terminal. Cloud9 comes prepackaged with essential tools for running this workshop. Since your Cloud9 IDE is cloud-based, you can do labs from your office, home, or anywhere using an internet-connected machine.

## Create a Cloud9 instance from AWS Console

1. Create a cloud9 instance from console by following step from [Create Cloud9 Enviornment using AWS Console](https://docs.aws.amazon.com/cloud9/latest/user-guide/create-environment-main.html) guide.
1. On Cloud9 Enviornments Home Page, From the list of enviornments open the enviornment which you have just created.
1. You will see a terminal area in the bottom, where you will run the requirement commands as you move forward. In the main work area you will open and edit code. AWS Cloud9 already comes with the required command line tools (aws cli, python)
1. Run below command on terminal to update pip version:
    :::code{language=shell showLineNumbers=false showCopyAction=true}
    sudo pip install --upgrade pip
    :::
