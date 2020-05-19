# Logging

This chart implements a log aggregation framework built on elasticsearch,kibana and fluentd within kubernetes.

# Hardware Requirement
The minimu reruirement to setup EFK with kind-voltha
CPU: 4
RAM Size: 16GB

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
kubectl port-forward --address 0.0.0.0  service/elasticsearch-master <exposed_port>:9200 -n voltha &

Visit: http://<k8s_node_ip>:<exposed_port>

#To access Kibana:
kubectl port-forward --address 0.0.0.0  service/logging-kibana <exposed_port>:5601 -n voltha &

Visit: http://<k8s_node_ip>:<exposed_port>

##To start using  Kibana:
you must create an index under Management > Index Patterns. Create one with a name of logstash*, then you can search for events in the Discover section.

Note: The indexes are creating on daily basis.

** Log aggregation for voltha **

This chart runs the following services:

- Elasticsearch
- Kibana
- fluentd-elasticsearch (container logs from k8s)

#To delete the efk service:
helm del --purge logging
