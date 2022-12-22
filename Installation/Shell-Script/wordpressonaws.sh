#!/bin/bash

aws ec2 create-key-pair --key-name autowordpress --key-type rsa --query 'KeyMaterial' --output text > ~/.ssh/autowordpress.pem

aws ec2 create-security-group --group-name wpws-sec-group --description "EC2-AUTO-CMS-WS" > /dev/null

aws ec2 create-security-group --group-name wpdb-sec-group --description "EC2-AUTO-CMS-DB" > /dev/null

aws ec2 authorize-security-group-ingress --group-name wpws-sec-group --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null

aws ec2 authorize-security-group-ingress --group-name wpws-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null

aws ec2 authorize-security-group-ingress --group-name wpdb-sec-group --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null

chmod 600 ~/.ssh/autowordpress.pem

aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name autowordpress --security-groups wpdb-sec-group --iam-instance-profil Name=LabInstanceProfile --user-data file://~/M346-CMS-Wordpress/Installation/Cloud-Init/cloud-configdb.yml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Wordpress-DB}]' > /dev/null

echo "Database instance is booting up please wait 8-10 minutes"

echo "after that you have to confirm an ssh connection with 'yes'"

sleep 500

mkdir ~/wp-secret

aws ec2 describe-instances --filters 'Name=tag:Name,Values=Wordpress-DB' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text > ~/wp-secret/dbpuip.txt

dbpuip=$(cat ~/wp-secret/dbpuip.txt)

ssh -i ~/.ssh/autowordpress.pem ubuntu@$dbpuip cat /home/mysql_access.txt > ~/wp-secret/password.txt

aws ec2 run-instances --image-id ami-08c40ec9ead489470 --count 1 --instance-type t2.micro --key-name autowordpress --security-groups wpws-sec-group --iam-instance-profil Name=LabInstanceProfile --user-data file://~/M346-CMS-Wordpress/Installation/Cloud-Init/cloud-configws.yml --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Wordpress-WS}]' > /dev/null

echo "Webserver instance is booting up please wait 8-10 minutes"

echo "after that all the important data to set up the machine will be displayed"

sleep 500

aws ec2 describe-instances --filters 'Name=tag:Name,Values=Wordpress-WS' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text > ~/wp-secret/wspuip.txt

wspuip=$(cat ~/wp-secret/wspuip.txt)

aws ec2 describe-instances --filters 'Name=tag:Name,Values=Wordpress-WS' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text > ~/wp-secret/wsprip.txt

wsprip=$(cat ~/wp-secret/wsprip.txt)

sleep 5

aws ec2 describe-instances --filters 'Name=tag:Name,Values=Wordpress-DB' --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text > ~/wp-secret/dbprip.txt

dbprip=$(cat ~/wp-secret/dbprip.txt)

sleep 2

aws ec2 authorize-security-group-ingress --group-name wpdb-sec-group --protocol tcp --port 3306 --cidr $wsprip/20 > /dev/null

scp -i ~/.ssh/autowordpress.pem ~/M346-CMS-Wordpress/Installation/Configs/50-server.cnf ubuntu@$dbpuip:/etc/mysql/mariadb.conf.d/50-server.cnf

ssh -i ~/.ssh/autowordpress.pem ubuntu@$dbpuip systemctl restart mariadb

echo "To configure your Wordpress go to $wspuip"
echo "Database name = wordpress"
echo "Username = root"
echo "Password is stored under ~/wp-secret/password.txt"
echo "Database Host = $dbprip"

echo "Resolving Webserver's Public IP..."

sleep 1

nslookup $wspuip