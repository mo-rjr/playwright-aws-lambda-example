#!/bin/sh
echo "hello rebecca"

echo $AWS_LAMBDA_RUNTIME_API
if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then 
  exec /usr/local/bin/aws-lambda-rie /usr/bin/npx aws-lambda-ric $1
else
  exec /usr/bin/npx aws-lambda-ric $1
fi