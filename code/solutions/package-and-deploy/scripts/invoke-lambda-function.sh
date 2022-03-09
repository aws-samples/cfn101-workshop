#!/usr/bin/env bash

# From code/package-and-deploy directory run ./scripts/invoke-lambda-function.sh <TIME_ZONE>

if [ -z "$1" ]; then
    echo "Usage: ./scripts/invoke-lambda-function.sh <TIME_ZONE>, e.g. Europe/London"
    exit 1
else
  TIME_ZONE="$1"
fi
LAMBDA_FUNCTION_NAME="cfn-workshop-python-function"
PAYLOAD="{\"time_zone\":\"${TIME_ZONE}\"}"

aws lambda invoke \
  --function-name "${LAMBDA_FUNCTION_NAME}" \
  --payload "${PAYLOAD}" \
  response.json

cat response.json
