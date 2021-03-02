## AWS CloudFormation 101 - Workshop

[![Website cfn101.workshop.aws](https://img.shields.io/website-up-down-green-red/http/cfn101.workshop.aws.svg)](https://cfn101.workshop.aws/)

## Workshop site

Go to [https://cfn101.workshop.aws](https://cfn101.workshop.aws/) to start a workshop.

## Developer Guide

This workshop is built with markdown as a static HTML site using [hugo](http://gohugo.io).

To install hugo, use your operating system's package manager (e.g. `brew install hugo`) or follow [the instructions on the hugo website](https://gohugo.io/getting-started/installing).

You'll find the content of the workshop in the [workshop](./workshop) directory.

Lab resources can be found in the [code](code) directory.

You will need to bring in the project's requirements using git submodules:

```bash
git submodule init
git submodule update
```

You can start up a local development server by running:

```bash
cd workshop
hugo serve
```

Once the server is running, you can open <http://localhost:1313> in your browser.

## Website Infrastructure

The workshop is available at https://cfn101.workshop.aws. It's a static website
hosted via [AWS Amplify](https://aws.amazon.com/amplify/).

The infrastructure is deployed using [AWS CloudFormation](https://aws.amazon.com/cloudformation/). The CloudFormation template is in the [infrastructure](./infrastructure) directory.

To deploy the workshop into your own account, you need to create an environment file and run the script:

```bash
cd infrastructure/

# Create an `.env` file and populate it with your own values
cp .env.example .env

# run the deployment script
./deploy.sh
```

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
