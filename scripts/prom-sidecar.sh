#!/bin/bash

sh 0-all-prerequisites.sh
mkdir /opt/onelink/prom-data /opt/onelink/prom-config /opt/onelink/s3
#chmod 1001 /opt/onelink/prom-data /opt/onelink/prom-config
cp ../config/prometheus.yaml /opt/onelink/prom-config/
cp ../config/bucket.yaml /opt/onelink/s3/
cp ../config/docker-compose/prom-thanos-sidecar.yaml /opt/onelink/docker-compose.yaml
docker-compose -f /opt/onelink/docker-compose.yaml up -d

exit 0 
