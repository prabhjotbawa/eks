#!/bin/bash

set -e

echo "Please enter the values similar to the ones entered when creating the S3 bucket"

echo -n "What's the environment: Choose from dev,test or prod"
read -r CLUSTER_ENV
echo -n "What's the cluster name: Eg:- mydemocluster"
read -r CLUSTER_NAME
#export CLUSTER_ENV=$1
#export CLUSTER_NAME=$2
echo -n "What's the region name: Eg:- us-east-2"
read -r REGION
#export REGION=$3
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