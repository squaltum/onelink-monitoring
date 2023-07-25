#!/bin/bash

sh 0-all-prerequisites.sh
mkdir -p /opt/onelink/blackbox-exporter/config
cp ../config/blackbox.yaml /opt/onelink/blackbox-exporter/config/
cp ../config/docker-compose/blackbox-exporter.yaml /opt/onelink/blackbox-exporter/docker-compose.yaml
docker-compose -f /opt/onelink/blackbox-exporter/docker-compose.yaml up -d

exit 0
