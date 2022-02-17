## Local Development

### Pre-Requisites
The following dependencies must be installed. Please refer to your operating system, how to install them.

> **Note:** For Windows 10, we recommend enabling Windows Subsystem for Linux (WSL) and installing Linux distribution of your choice,
> for example, here are the instructions on how to install [Ubuntu](https://ubuntu.com/tutorials/ubuntu-on-windows).

- Python >=3.8 and pip
- VirtualEnv
- Hugo
- Go
- Ruby >=2.6 and gem
- [cfn-nag](https://github.com/stelligent/cfn_nag)

Here is an example how to install pre-requisites on macOS/Linux using [Homebrew](https://brew.sh/).
```shell
# install python3
brew install python

# install VirtualEnv
pip3 install virtualenv

# install hugo
brew install hugo

# install go
brew install go

# install ruby, gem and cfn-nag
brew install ruby brew-gem
brew gem install cfn-nag
```

### Build local development environment
Once you have installed pre-requisites, run commands below:

#### Step 1 - Clone the repository (Required)
In the first step, you will clone the repository and initialize submodules.

1. Clone the repository:
   ```shell
   $ git clone https://github.com/aws-samples/cfn101-workshop.git
   ```
2. Initialize submodules:
   ```shell
   $ cd cfn101-workshop/

   $ git submodule init

   $ git submodule update
   ```

#### Step 2 - `make init` (Required)
In the second step, you will use `make` to create a virtual environment.

1. Initialize the local environment
   ```shell
   make init
   ```
1. Activate `VirtualEnv` environment.
   ```shell
   source venv/bin/activate
   ```
1. Run pre-commit tests for the first time to check the installation.
   ```shell
   make test
   ```

### Testing(Automated and Manual)
The repository has a GitHub actions set up which will run `cfn-lint` and `cfn-nag` tests on pull requests.

Furthermore, pre-commit configuration file is provided to format the code and content. See below various tests you can
run locally when developing the labs.

* `make test` - will run pre-commit tests. Useful to run before committing changes.
* `make lint` - will run cfn-lint test against CloudFormation templates in `/code/solutions directory`.
* `make nag` - will run cfn-nag test against CloudFormation templates in `/code/solutions directory`.

### Versioning and releasing (Repo admin only)
This repository follows Semantic Versioning [2.0.0](https://semver.org/). Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when you make incompatible API changes,
2. MINOR version when you add functionality in a backwards compatible manner, and
3. PATCH version when you make backwards compatible bug fixes.

The `bump2version` tool is used to take care of versioning including committing and tagging new versions.

When ready to publish new release follow the steps below:
```shell
# checkout and update main branch
git checkout main && git pull

# checkout release branch
git checkout release

# merge main branch to release branch
git merge main

# bump the version following semantic guide above part=patch|minor|major
make version part=patch

# push the new version tag to origin
make release
```

Finally, create new release on [cfn101-workshop](https://github.com/aws-samples/cfn101-workshop/releases) release page

* Select **Releases** and choose **Draft a new release**
* Choose a tag version
* Select **Auto-generate release notes**
* **Publish release**

## Troubleshooting
If you get an error installing rain
```shell
[INFO] Installing environment for https://github.com/aws-cloudformation/rain.
[INFO] Once installed this environment will be reused.
[INFO] This may take a few minutes...
An unexpected error has occurred: CalledProcessError: command:...
```

The default **proxy.golang.org** is blocked on your network. To fix it, run:
```shell
export GOPROXY=direct
```
