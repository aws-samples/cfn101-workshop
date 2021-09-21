---
title: 'Install Git'
date: 2019-10-18T13:43:18+01:00
weight: 400
---

You may already have Git installed. To check, type `git --version` into a terminal. If not, please follow the instructions below for your operating system.

## Install Git on macOS

There are two ways to install Git on macOS: using [Xcode](https://developer.apple.com/xcode/) or using [Homebrew](https://brew.sh/).

### Install Git with Xcode

1. Open your terminal and run following command:

    ```shell
    $ xcode-select --install
    ```

1. Follow the installation steps in the opened software update popup window.

## Install Git on Linux

Git is included in the main package repository of every Linux distribution so use your package manager to install it (e.g. `apt install git`).

Verify the installation by typing `git --version` into a terminal.

```shell
$ git --version
git version 2.30.0
```

## Install Git on Windows

### Git for Windows stand-alone installer

1. Download the latest [Git for Windows installer](https://git-for-windows.github.io/).
1. When you've successfully started the installer, you should see the Git Setup wizard screen. Follow the Next and Finish
 prompts to complete the installation. The default options are pretty sensible for most users.
1. Open a Command Prompt (or Git Bash if during installation you elected not to use Git from the Windows Command Prompt).
1. Run the following commands `git --version`
    ```shell
    $ git --version
    git version 2.23.0.windows.1
    ```
