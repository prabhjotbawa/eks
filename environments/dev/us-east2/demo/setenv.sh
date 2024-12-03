#!/bin/bash

set -e

export CLUSTER_ENV=$1
export CLUSTER_NAME=$2
export REGION=$3
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