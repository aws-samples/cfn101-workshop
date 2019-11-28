#!/usr/bin/env bash

# Import configuration
. ./.env

# Deploy the workshop
aws cloudformation deploy \
  --template-file ./amplify.template \
  --capabilities CAPABILITY_IAM \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --parameter-overrides \
    AmplifyAppName=${APP_NAME} \
    OAuthToken=${GITHUB_OAUTH_TOKEN} \
    Repository=${REPOSITORY} \
    Domain=${DOMAIN} \
    SubDomain=${SUBDOMAIN}
