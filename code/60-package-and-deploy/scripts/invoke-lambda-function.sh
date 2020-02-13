#!/usr/bin/env bash

# From code/60-package-and-deploy directory run ./scripts/invoke-lambda-function.sh

LAMBDA_FUNCTION_NAME="cfn-workshop-python-function"

PAYLOAD='{"time_zone":"Europe/London"}'

aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --payload $PAYLOAD \
  response.json

echo "$(<response.json)"
