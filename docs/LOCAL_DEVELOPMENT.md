## Local Development

### Pre-Requisites

The following dependencies must be installed:
- Python >=3.8 and pip
- pre-commit
- hugo
- Go
- Ruby >=2.6 and gem
- [cfn-nag](https://github.com/stelligent/cfn_nag)

Here is a code to install pre-requisites on macOS using [Homebrew](https://brew.sh/). For other operating systems,
please refer to the OS documentation.
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


1. Clone the repository.
   ```shell
   git clone <git-repository-clone-address>
   ```
1. Initialize the `pre-commit`.
   ```shell
   pre-commit install
   ```
1. Run `pre-commit` tests. (These will also be run automatically on each commit)
   ```shell
   pre-commit run --all-files
   ```
1. Run `cfn-lint` tests. (This test will also run by GitHub actions on PR merge to mainline)
   ```shell
   cfn-lint code/solutions/*.yaml
   ```
1. Run `cfn-nag` tests. (This test will also run by GitHub actions on PR merge to mainline)
   ```shell
   cfn_nag_scan --input-path code/solutions
   ```
