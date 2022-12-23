#!/bin/bash

# AWS Preparation: key, group, connection rules
aws ec2 create-key-pair --key-name autowordpress --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/autowordpress.pem

aws ec2 create-security-group --group-name wp-sec-group --description "EC2-AUTO-CMS" > /dev/null

aws ec2 authorize-security-group-ingress --group-name wp-sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null

aws ec2 authorize-security-group-ingress --group-name wp-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null

aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name autowordpress --security-groups wp-sec-group --iam-instance-profil Name=LabInstanceProfile --user-data file://~/M346-CMS-Wordpress/Installation/Cloud-Init/cloud-config.yml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Wordpress}]' > /dev/null

# Info for the user
echo "Instance is booting up please wait 10 minutes..."
echo "after that you have to confirm an ssh connection with 'yes'."
echo "All important details for the configuration will be displayed"

sleep 600

mkdir ~/wp-secret

# Fetching Public IP-address
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Wordpress' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text > ~/wp-secret/puip.txt

puip=$(cat ~/wp-secret/puip.txt)

chmod 600 ~/.ssh/autowordpress.pem

# Fetching SQL root password with ssh
ssh -i ~/.ssh/autowordpress.pem ubuntu@$puip cat /home/mysql_access.txt > ~/wp-secret/password.txt

sleep 5

sqlpassword=$(cat ~/wp-secret/password.txt)

# Configuration details
echo "To configure your Wordpress go to $puip"
echo "Database name = wordpress"
echo "Username = root"
echo "$sqlpassword"
echo "Database Host = hostname"

echo "Resolving Webserver's Public IP..."

sleep 1

nslookup $puip
