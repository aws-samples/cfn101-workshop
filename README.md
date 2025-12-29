<h1 align="center">
AWS CloudFormation - Workshop
<br>
    <a href="https://cfn101.workshop.aws"><img alt="Website" src="https://img.shields.io/website?down_color=red&down_message=down&up_color=green&up_message=up&url=https%3A%2F%2Fcfn101.workshop.aws"></a>
    <a href="https://github.com/aws-samples/cfn101-workshop/actions"><img alt="GitHub Workflow Status" src="https://github.com/aws-samples/cfn101-workshop/workflows/Unit%20Tests/badge.svg"></a>
</h1>

## Workshop Instructions

**The full workshop instructions and content are available at [cfn101.workshop.aws](https://cfn101.workshop.aws/)**

This repository provides the code templates and solutions referenced in the workshop. The workshop instruction files are maintained in AWS Workshop Studio and published to the workshop website. This GitHub repository contains only the code resources needed to complete the workshop labs.

## Usage
1. Visit [cfn101.workshop.aws](https://cfn101.workshop.aws/) for the complete workshop instructions
2. Clone this repository to your working directory or download the ZIP file from GitHub for the code templates
3. Open the downloaded files in your code editor or IDE of your choice

The working directory is located in [code/workspace](code/workspace) where you can follow along and write your code.

In the [code/solutions](code/solutions), you can find the completed solution for each lab. This can be used as a
reference, in case you get stuck or things don't work as intended.

## Contributing

Contributions to the code templates and solutions are welcome!

### Local Development Setup

To validate your changes locally before submitting a PR:

```bash
# Install uv (if not already installed)
# See: https://docs.astral.sh/uv/getting-started/installation/

# Set up environment and install dependencies
make init

# Run pre-commit checks on all files
make test
```

The pre-commit hooks will automatically check your CloudFormation templates for linting issues, formatting, and best practices.

For more details, please read the [code of conduct](CODE_OF_CONDUCT.md) and the [contributing guidelines](CONTRIBUTING.md).

## License
This library is licensed under the MIT-0 License. See the [license](LICENSE) file.
