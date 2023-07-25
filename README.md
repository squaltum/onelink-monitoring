## onelink-monitoring ##

How to deploy

pre-step edit vars for s3 bucket
     - vi VARS

1. Prometheus + Thanos Sidecar
     - cd sripts
     - sh prom-sidecar.sh
  
2. Thanos Store
     - cd scripts
     - sh thanos-store.sh

3. Thanos Query
     - cd scripts
     - sh thanos-query.sh

4. Thanos Compact
     - cd scripts
     - sh thanos-compact.sh

5. grafana server
     - cd scripts
     - sh grafana.sh

6. Prometheus Blackbox-exporter
     - cd scripts
     - blackbox-exporter.sh
 
