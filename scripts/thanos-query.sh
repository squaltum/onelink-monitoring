#!/bin/bash

sh 0-all-prerequisites.sh
cp ../config/docker-compose/thanos-query.yaml /opt/onelink/docker-compose.yaml
docker-compose -f /opt/onelink/docker-compose.yaml up -d

exit 0 
