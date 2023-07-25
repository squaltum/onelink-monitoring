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
