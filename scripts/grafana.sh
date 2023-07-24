#!/bin/bash

sh 0-all-prerequisites.sh
mkdir /opt/onelink/grafana-data
chmod 1001 /opt/onelink/grafana-data
cp ../config/docker-compose/grafana.yaml /opt/onelink/docker-compose.yaml
docker-compose -f /opt/onelink/docker-compose.yaml up -d

exit 0 
