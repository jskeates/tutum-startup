#!/bin/bash
# Expected to be run on Ubuntu 14.04

# Update instance

sudo locale-gen en_GB.UTF-8
sudo apt-get update

# Install Tutum CLI

sudo apt-get install python-pip -y
sudo pip install tutum==0.21.1

# Install jq

sudo apt-get install jq -y

# Install AWS CLI

sudo apt-get install awscli -y

# Set Tutum env vars

export TUTUM_USER=xxx
export TUTUM_APIKEY=xxx

# Set AWS env vars

export AWS_DEFAULT_REGION=$(ec2metadata --availability-zone | sed 's/.$//')

# Register this node with Tutum

tutum node byo | sed -n 4p | source /dev/stdin

# Remove any old Tutum nodes

tutum node rm $(tutum node list | grep "Unreachable" | awk '{print $1}')

# Sleep until node has deployed

sleep 15

# Set Tutum UUID env var now that tutum-agent has been installed

export TUTUM_UUID=$(cat /etc/tutum/agent/tutum-agent.conf | jq -r .TutumUUID)

# Set Tutum tags based on EC2 tags

INSTANCE_ID=$(ec2metadata --instance-id)
EC2_TAGS=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" | jq -r '.Tags | map(select(.Key | contains("tutum"))) | .[].Value')

for TAG in $EC2_TAGS
do
  tutum tag add -t $TAG $TUTUM_UUID
done

# Cleanup instance

unset AWS_DEFAULT_REGION TUTUM_USER TUTUM_APIKEY TUTUM_UUID
sudo pip uninstall tutum -y
sudo apt-get purge python-pip jq awscli -y
cat /dev/null > ~/.bash_history && history -c

# Send Slack Notification

INSTANCE_IP=$(ec2metadata --public-ipv4)
INSTANCE_TYPE=$(ec2metadata --instance-type)
TIME=$(date +"%T")

MSG="$TIME INFO - A new EC2 instance has started: *$INSTANCE_ID* / $INSTANCE_TYPE ($INSTANCE_IP)"

curl -X POST --data-urlencode "payload={\"channel\": \"#devops\", \"username\": \"AWS\", \"text\": \"$MSG\", \"icon_url\": \"http://cl.ly/1z130N3p2G42/Image%202016-01-12%20at%2012.18.09%20pm.png\"}" https://hooks.slack.com/services/xxx/xxx/xxx

# Cleanup history

cat /dev/null > ~/.bash_history && history -c
