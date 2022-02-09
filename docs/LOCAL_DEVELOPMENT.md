## Local Development

### Pre-Requisites
The following dependencies must be installed. Please refer to your operating system, how to install them.

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

# install pre-commit
brew install pre-commit

# install hugo
brew install hugo

# install go
brew install go

# install cfn-nag
brew install ruby brew-gem
brew gem install cfn-nag
```

### Build local development environment
Once you have installed pre-requisites, run commands below:

#### Step 1 - Clone the repository (required)
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
