#!/bin/bash
# Launch an EC2 instance with tags

KEY_NAME="my-key-pair"
KEY_PATH="/Users/ashokrakoti/Developer/aws/${KEY_NAME}.pem"
SECURITY_GROUP_NAME="jenkins-sg"
INSTANCE_TAG="LaunchedBy=Jenkins"

# Create key pair (if doesn't exist)
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &>/dev/null; then
  aws ec2 create-key-pair --key-name "$KEY_NAME"     --query 'KeyMaterial' --output text > "$KEY_PATH"
  chmod 400 "$KEY_PATH"
fi

# Create security group (if doesn't exist)
GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME"   --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)

if [[ "$GROUP_ID" == "None" ]]; then
  GROUP_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME"     --description "Security group for Jenkins EC2 launch" --output text)
  aws ec2 authorize-security-group-ingress --group-id "$GROUP_ID"     --protocol tcp --port 22 --cidr 0.0.0.0/0
fi

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances   --image-id ami-0c02fb55956c7d316   --instance-type t2.micro   --key-name "$KEY_NAME"   --security-group-ids "$GROUP_ID"   --tag-specifications "ResourceType=instance,Tags=[{Key=LaunchedBy,Value=Jenkins}]"   --query 'Instances[0].InstanceId' --output text)

echo "✅ EC2 Instance launched with ID: $INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances   --instance-ids "$INSTANCE_ID"   --query 'Reservations[0].Instances[0].PublicIpAddress'   --output text)

echo "🔐 SSH with: ssh -i "$KEY_PATH" ec2-user@$PUBLIC_IP"
