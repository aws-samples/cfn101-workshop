#!/usr/bin/env bash

# From code/package-and-deploy directory run ./scripts/invoke-lambda-function.sh

if [ -z "$1" ]; then
    echo "Error: Provide time_zone, e.g. Europe/London"
    exit 1
else
  TIMEZONE="$1"
fi
LAMBDA_FUNCTION_NAME="cfn-workshop-python-function"
PAYLOAD="{\"time_zone\":\"${TIMEZONE}\"}"

aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --payload $PAYLOAD \
  response.json

cat response.json
