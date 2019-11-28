## AWS CloudFormation 101 - Workshop

## Developer Guide

This workshop is built with markdown as a static HTML site using [hugo](http://gohugo.io).

```bash
brew install hugo
```

The hugo is using [hugo-theme-learn](https://github.com/matcornic/hugo-theme-learn) theme. To start, clone the repo and 
initialize submodule:

```bash
git clone https://github.com/aws-samples/cfn101-workshop.git
cd cfn101-workshop
git submodule init && git submodule update
```

You'll find the content of the workshop in the [workshop](workshop/) directory.

Lab resources can be found in the [code](code/) directory. 

You can start up a local development server by running:

```bash
cd workshop
hugo server
open http://localhost:1313/
```

## Website Infrastructure

The workshop is available at https://cfn101.solution.builders. It's a static website
hosted via [AWS Amplify](https://aws.amazon.com/amplify/).

The infrastructure is implemented as a CloudFormation stack. The template exists in the [infrastructure](infrastructure/) directory.

```bash
cd infrastructure/

# Create an `.env` file and populate it with your own values
cp .env.example .env

# run the deployment script
env $(cat .env | xargs) ./deploy.sh
```

## License

This library is licensed under the MIT-0 License. See the LICENSE file.