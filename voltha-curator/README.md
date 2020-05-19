# Curator 

This chart implements a cronjob for cleanup indices created by log aggregation framework built on elasticsearch,kibana and fluentd within
kubernetes.The job runs on daily basis at night 1:00 am and it delete indices for 3 day's ago.

#Install curator setup
helm install -n curator voltha-curator --namespace voltha

##To check curator status: 
kubectl get cronjob -n voltha

#To delete the efk service:
helm del --purge curator 
