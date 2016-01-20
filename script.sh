#!/bin/bash
# Expected to be run on Ubuntu 14.04

# Parameters
# -- Tutum Credentials: store your username and API Key in an S3 bucket that the
# EC2 Instance's IAM Role has permission to access
# Username: <CREDENTIALS_S3_BUCKET>/<ENVIRONMENT>/tutum_auth_user
# API Key: <CREDENTIALS_S3_BUCKET>/<ENVIRONMENT>/tutum_auth_api_key
CREDENTIALS_S3_BUCKET="xxx"
ENVIRONMENT="xxx" #e.g. "staging", "production"
# -- Deployment Timeout: The amount of time to wait for this node to be deployed
# before the attempt is abandoned
DEPLOYMENT_TIMEOUT="5m"

# Update instance

sudo locale-gen en_GB.UTF-8
sudo apt-get update

# Install Tutum CLI

sudo apt-get install python-pip -y
sudo pip install tutum==0.21.1

# Install jq

sudo apt-get install jq -y

# Install AWS CLI

sudo pip install awscli==1.9.20

# Set AWS env vars

export AWS_DEFAULT_REGION=$(ec2metadata --availability-zone | sed 's/.$//')

# Set Tutum env vars

export TUTUM_USER=$(aws s3 cp s3://${CREDENTIALS_S3_BUCKET}/${ENVIRONMENT}/tutum_auth_user - --region ${AWS_DEFAULT_REGION})
export TUTUM_APIKEY=$(aws s3 cp s3://${CREDENTIALS_S3_BUCKET}/${ENVIRONMENT}/tutum_auth_api_key - --region ${AWS_DEFAULT_REGION})

# Register this node with Tutum

tutum node byo | sed -n 4p | source /dev/stdin

# Remove any old Tutum nodes

tutum node rm $(tutum node list | grep "Unreachable" | awk '{print $1}')

# Set Tutum UUID env var now that tutum-agent has been installed

export TUTUM_UUID=$(cat /etc/tutum/agent/tutum-agent.conf | jq -r .TutumUUID)

# Wait for node to be deployed

echo "Waiting for node to be deployed..."
timeout $DEPLOYMENT_TIMEOUT bash -c "while [ \"\$(tutum node inspect $TUTUM_UUID | jq -r .state)\" != \"Deployed\" ]; do sleep 10; done;" #TUTUM_UUID is purposefully not escaped
if [ $? != 0 ]; then echo "Node never came up"; exit 2; fi

# Set Tutum tags based on EC2 tags

INSTANCE_ID=$(ec2metadata --instance-id)
EC2_TAGS=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" | jq -r '.Tags | map(select(.Key | contains("tutum"))) | .[].Value')

for TAG in $EC2_TAGS
do
  tutum tag add -t $TAG $TUTUM_UUID
done

# Cleanup instance

unset AWS_DEFAULT_REGION TUTUM_USER TUTUM_APIKEY TUTUM_UUID
sudo pip uninstall tutum aws-cli -y
sudo apt-get purge python-pip jq -y
cat /dev/null > ~/.bash_history && history -c
