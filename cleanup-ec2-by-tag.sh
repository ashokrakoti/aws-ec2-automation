#!/bin/bash
# Terminate all EC2 instances tagged with LaunchedBy=Jenkins

TAG_KEY="LaunchedBy"
TAG_VALUE="Jenkins"

echo "🔍 Looking for instances tagged with $TAG_KEY=$TAG_VALUE"

INSTANCE_IDS=$(aws ec2 describe-instances   --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE"             "Name=instance-state-name,Values=running,stopped"   --query 'Reservations[*].Instances[*].InstanceId' --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "✅ No matching instances found."
else
  echo "💥 Terminating: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
  echo "✅ Termination complete."
fi
