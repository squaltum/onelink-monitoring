#!/bin/bash

sh 0-all-prerequisites.sh
mkdir /opt/onelink/store-data /opt/onelink/s3
chmod 1001 /opt/onelink/store-data
cp ../config/bucket.yaml /opt/onelink/s3/
cp ../config/docker-compose/thanos-store.yaml /opt/onelink/docker-compose.yaml
docker-compose -f /opt/onelink/docker-compose.yaml up -d

exit 0 
