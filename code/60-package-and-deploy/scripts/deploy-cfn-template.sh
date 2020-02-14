#!/usr/bin/env bash

# From code/60-package-and-deploy directory run ./scripts/deploy-cfn-template.sh

BUCKET_NAME="cfn-workshop-s3-s3bucket-1wo3wjmf93viq"
PREFIX_NAME="lambda-function"
STACK_NAME="cfn-workshop-lambda"
AWS_REGION="eu-west-1"

printf "\n--> Packaging and uploading templates to the %s S3 bucket ...\n" $BUCKET_NAME

aws cloudformation package \
  --template-file infrastructure.template \
  --s3-bucket $BUCKET_NAME \
  --s3-prefix $PREFIX_NAME \
  --output-template-file infrastructure-packaged.template

printf "\n--> Validating template ...\n"

aws cloudformation validate-template \
  --template-body file://infrastructure-packaged.template

printf "\n--> Deploying %s template...\n" $STACK_NAME

aws cloudformation deploy \
  --template-file infrastructure-packaged.template \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --capabilities CAPABILITY_IAM
