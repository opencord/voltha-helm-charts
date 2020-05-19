# Logging

This chart implements a log aggregation framework built on elasticsearch,kibana and fluentd within kubernetes.

#Install efk setup
Create charts directory inside voltha-logging 

mkdir ~/voltha-logging/charts

helm repo add kiwigrid https://kiwigrid.github.io

helm fetch stable/elasticsearch
helm fetch stable/kibana
helm fetch kiwigrid/fluentd-elasticsearch
 
tar -xvzf elasticsearch-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts
tar -xvzf kibana-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts
tar -xvzf fluentd-elasticsearch-<version>.tgz -C  ~/voltha-helm-charts/voltha-logging/charts

helm install -n logging voltha-logging --namespace voltha

NOTE: 
1. The name must be `logging` currently.
2. By default, the logging charts creating Persistance Volume.To check the PV 
   kubectl get pv -n voltha

## Current log sources

- [elasticsearch](https://github.com/helm/charts/tree/master/stable/elasticsearch)
- [kibana](https://github.com/helm/charts/tree/master/stable/kibana)
- [fluentd-elasticsearch](https://github.com/kiwigrid/helm-charts/tree/master/charts/fluentd-elasticsearch)


#To access Kibana:
kubectl port-forward --address 0.0.0.0  service/logging-kibana <exposed_port>:5601 -n voltha &

Visit: http://<k8s_node_ip>:<exposed_port>

##To start using  Kibana: 
you must create an index under Management > Index Patterns. Create one with a name of logstash*, then you can search for events in the Discover section.


** Log aggregation for voltha **

This chart runs the following services:

- Elasticsearch
- Kibana
- fluentd-elasticsearch (container logs from k8s)

#To delete the efk service:
helm del --purge logging
kubectl delete pvc <volume-name> -n voltha
