#!/bin/bash

set -e

echo "Please enter the values similar to the ones entered when creating the S3 bucket"
echo "Values can be passed as show below:"
echo "sh setenv.sh test test us-east-2"
echo "Defaults are set if nothing is passed\n\n"

CLUSTER_ENV=${1:-dev}
CLUSTER_NAME=${2:-mydemocluster}
REGION=${3:-us-east-2}

export BUCKET=terraform-state-$CLUSTER_ENV-$CLUSTER_NAME
export KEY=terraform-$CLUSTER_ENV-$CLUSTER_NAME.tfstate
export DYNAMODB_TBL=terraform-state-lock-$CLUSTER_ENV-$CLUSTER_NAME

echo "${CLUSTER_ENV}"
echo "${CLUSTER_NAME}"
echo "${REGION}"
echo "${BUCKET}"
echo "${KEY}"
echo "${DYNAMODB_TBL}"

echo "Initializing the backend...."

terraform init -backend-config="bucket=$BUCKET" -backend-config="key=$KEY" -backend-config="region=$REGION" -backend-config="dynamodb_table=$DYNAMODB_TBL"

echo "Backend initialized!!!"