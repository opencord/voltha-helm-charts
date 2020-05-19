# Logging

This chart implements a log aggregation framework built on elasticsearch,kibana and fluentd within kubernetes.These charts provides Authentication, Authorization and security features for EFK.These security features were all supported via X-Pack plugin.These charts enable Role Based Access Control (RBAC) in Elasticsearch.

# Hardware Requirement
The minimum requirement to setup EFK with kind-voltha
CPU: 4
RAM Size: 16GB

## Create secrets
encryptionkey=$(docker run --rm busybox:1.31.1 /bin/sh -c "< /dev/urandom tr -dc _A-Za-z0-9 | head -c50")
kubectl create secret generic kibana --from-literal=encryptionkey=$encryptionkey -n voltha
kubectl create secret generic elastic-credentials --from-literal=password=changeme --from-literal=username=elastic -n voltha
kubectl create secret generic elastic-config-credentials --from-literal=password=<password> --from-literal=username=<username> -n voltha

#Install efk setup
Create charts directory inside voltha-logging

mkdir ~/voltha-logging/charts

helm repo add elastic  https://helm.elastic.co
helm repo add kiwigrid https://kiwigrid.github.io

helm fetch elastic/elasticsearch
helm fetch elastic/kibana
helm fetch kiwigrid/fluentd-elasticsearch

tar -xvzf elasticsearch-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts
tar -xvzf kibana-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts
tar -xvzf fluentd-elasticsearch-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts

helm install -n logging voltha-logging --namespace voltha

NOTE:
1. The name must be `logging` currently.
2. By default, the logging charts disabled Persistance Storage.If the Persistance Storage is enabled it throuws permission denied error.So it's adviced to not use Persistance Storage.

## Current log sources

- [elasticsearch](https://github.com/elastic/helm-charts/tree/7.7.0/elasticsearch)
- [kibana](https://github.com/elastic/helm-charts/tree/7.7.0/elasticsearch)
- [fluentd-elasticsearch](https://github.com/kiwigrid/helm-charts/tree/master/charts/fluentd-elasticsearch)


#To access Elasticsearch:
screen -dms elasticsearch kubectl port-forward --address 0.0.0.0  service/elasticsearch-master <exposed_port>:9200 -n voltha

Visit: http://<k8s_node_ip>:<exposed_port>

#To access Kibana:
screen -dms kibana-ui kubectl port-forward --address 0.0.0.0  service/logging-kibana <exposed_port>:5601 -n voltha

Visit: http://<k8s_node_ip>:<exposed_port>

##To start using  Kibana:
Login Kibana dashboard with admin user.More advanced documentation refer [https://docs.google.com/document/d/1KF1HhE-PN-VY4JN2bqKmQBrZghFC5HQM_s0mC0slapA/edit?usp=sharing]

Note: The indexes are creating on daily basis.

** Log aggregation for voltha **

This chart runs the following services:

- Elasticsearch
- Kibana
- fluentd-elasticsearch (container logs from k8s)

#To delete the efk service:
kubectl delete secret kibana
kubectl delete secret elastic-credentials 
kubectl delete secret elastic-config-credentials 
helm del --purge logging
