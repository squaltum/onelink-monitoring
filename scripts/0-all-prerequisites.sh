#!/bin/bash

dnf upgrade --releasever=2023.1.20230719 -y
dnf install docker -y
systemctl start docker; systemctl enable docker
fallocate -l 8G /swapfile 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab 
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime 
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /opt/onelink

while read line
do
	S3VAR=$( echo ${line} |gawk -F"=" '{ print $1 }' )
	if [ "${S3VAR}" = "bucket" ]; 
	then
		S3VAR=$( echo ${line} |gawk -F"=" '{ print $2 }' )
		sed -i "s/BUCKETNAME/${S3VAR}/g" ../config/bucket.yaml
	fi
	if [ "${S3VAR}" = "access_key" ]; 
	then
		S3VAR=$( echo ${line} |gawk -F"=" '{ print $2 }' )
		sed -i "s/ACCESSKEY/${S3VAR}/g" ../config/bucket.yaml
	fi
	if [ "${S3VAR}" = "secret_key" ]; 
	then
		S3VAR=$( echo ${line} |gawk -F"=" '{ print $2 }' )
		sed -i "s/SECRETKEY/${S3VAR}/g" ../config/bucket.yaml
	fi
	if [ "${S3VAR}" = "endpoint" ]; 
	then
		S3VAR=$( echo ${line} |gawk -F"=" '{ print $2 }' )
		sed -i "s/S3ENDPOINT/${S3VAR}/g" ../config/bucket.yaml
	fi
	if [ "${S3VAR}" = "region" ]; 
	then
		S3VAR=$( echo ${line} |gawk -F"=" '{ print $2 }' )
		sed -i "s/S3REGION/${S3VAR}/g" ../config/bucket.yaml
	fi
done < ../VARS
