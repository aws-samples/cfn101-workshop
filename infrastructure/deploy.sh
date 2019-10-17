#!/usr/bin/env bash

# To run the script execute: $ env $(cat  infrastructure/.env | xargs) ./infrastructure/deploy.sh
aws cloudformation deploy \
  --template-file ./infrastructure/amplify.template \
  --capabilities CAPABILITY_IAM \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --parameter-overrides \
    AmplifyAppName=${APP_NAME} \
    OAuthToken=${GITHUB_OAUTH_TOKEN} \
    Repository=${REPOSITORY} \
    Domain=${DOMAIN} \
    SubDomain=${SUBDOMAIN}