#!/bin/bash

aws ec2 create-key-pair --key-name autowordpress --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/autowordpress.pem

aws ec2 create-security-group --group-name wp-sec-group --description "EC2-AUTO-CMS"

aws ec2 authorize-security-group-ingress --group-name wp-sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-name wp-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name autowordpress --security-groups wp-sec-group --iam-instance-profil Name=LabInstanceProfile --user-data file://~/M346-CMS-Wordpress/Installation/Cloud-Init/cloud-config.yml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Wordpress}]'