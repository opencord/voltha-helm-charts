# Helm Charts to Deploy VOLTHA 2.x

This repository defines [Kubernetes Helm](https://helm.sh/) charts that can be
used to deploy a [VOLTHA](https://www.opennetworking.org/voltha/) instance.
More information and documentation can be found in the 
[voltha docs](https://docs.voltha.org/master/kind-voltha/README.html) which we recommend as the starting point.

## Installing charts

To deploy VOLTHA a [Kubernetes](https://kubernetes.io/) environment is
required. There are many mechanisms to deploy a Kubernetes environment and how
to do so is out of scope for this project. A Simple search on the Internet will
lead to the many possibilities.

In addition to a base Kubernetes in order to pass traffic to an OLT additional
services that are external to VOLTHA are required, such as an OpenFlow
Controller with applications to support authentication (`EAPOL`) and IP address
allocation (`DHCP`) as examplified by the [SEBA
Project](https://www.opennetworking.org/seba/).

## Deploying using kind-voltha

We suggest an automated deployment of VOLTHA by using
[kind-volta](https://docs.voltha.org/master/kind-voltha/README.html?highlight=tracing) as described in the 
[voltha docs](https://docs.voltha.org/master/kind-voltha/README.html). 
Note that `kind-voltha` is a thin wrapper over `helm` chart commands, automating some commands and arguments. 

## Manual Example deployment

The following describes how to deploy VOLTHA manually. 

### Prerequisite Helm Chart Repositories
To use the charts for VOLTHA the following two Helm repositories should be 
added to your helm environment:
```shell
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
```

### ONOS Controller 
To use the charts for VOLTHA the following two Helm repositories should be 
added to your helm environment:
```shell
helm repo add onos https://charts.onosproject.org
helm repo update
```

then to install ONOS:
```shell script
helm install --create-namespace --set image.pullPolicy=Always,image.repository=voltha/voltha-onos,image.tag=master,replicas=3,atomix.replicas=3 --set defaults.log_level=DEBUG --namespace default onos onos/onos-classic
```

### Deploy VOLTHA Manually

Add the helm chart repository and build the chart dependencies as follows:
```shell
helm repo add onf https://charts.opencord.org
helm repo update
```

If you are developing and want to modify and use the charts from a local copy:
```shell
git clone https://github.com/opencord/voltha-helm-charts
cd voltha-helm-charts
helm dependency build ./voltha
```
#### Deploy ETCD Operator
[ETCD](https://github.com/etcd-io/etcd) deployes an ETCD cluster using standard Kubernetes
manifests. As the VOLTHA helm charts use ETCD, it must be installed before the VOLTHA helm chart.
```shell
helm install -f --create-namespace --set replicas=1 --namespace default etcd incubator/etcd
```

#### Deploy VOLTHA Core Components
At this point the VOLTHA Helm charts can be used to deploy the VOLTHA core
components:

```shell
helm install -f values.yaml --create-namespace --set therecanbeonlyone=true --set services.etcd.service=etcd.default.svc --set services.etcd.port=2379 --set services.etcd.address=etcd.default.svc:2379 --set kafka_broker=kafka.default.svc:9092 --set services.kafka.adapter.service=kafka.default.svc --set services.kafka.adapter.port=9092 --set services.kafka.cluster.service=kafka.default.svc --set services.kafka.cluster.port=9092 --set services.kafka.adapter.address=kafka.default.svc:9092 --set services.kafka.cluster.address=kafka.default.svc:9092 --set 'services.controller[0].service=onos-onos-classic-0.onos-onos-classic-hs.default.svc' --set 'services.controller[0].port=6653' --set 'services.controller[0].address=onos-onos-classic-0.onos-onos-classic-hs.default.svc:6653' --namespace voltha voltha onf/voltha
```
An example fo the [values.yaml](https://github.com/opencord/kind-voltha/blob/master/values.yaml)

#### Adapters for OpenOLT and OpenONU
The adapters for the OpenOLT and OpenONU are in separate helm charts. 

To install the OpenOLT adapter use:
```shell
helm install -f values.yaml --create-namespace --set services.etcd.service=etcd.default.svc --set services.etcd.port=2379 --set services.etcd.address=etcd.default.svc:2379 --set kafka_broker=kafka.default.svc:9092 --set services.kafka.adapter.service=kafka.default.svc --set services.kafka.adapter.port=9092 --set services.kafka.cluster.service=kafka.default.svc --set services.kafka.cluster.port=9092 --set services.kafka.adapter.address=kafka.default.svc:9092 --set services.kafka.cluster.address=kafka.default.svc:9092 --namespace voltha open-olt onf/voltha-adapter-openolt
```
To install the OpenONU adapter use:
```shell
helm install -f values.yaml --create-namespace --set services.etcd.service=etcd.default.svc --set services.etcd.port=2379 --set services.etcd.address=etcd.default.svc:2379 --set kafka_broker=kafka.default.svc:9092 --set services.kafka.adapter.service=kafka.default.svc --set services.kafka.adapter.port=9092 --set services.kafka.cluster.service=kafka.default.svc --set services.kafka.cluster.port=9092 --set services.kafka.adapter.address=kafka.default.svc:9092 --set services.kafka.cluster.address=kafka.default.svc:9092 --namespace voltha open-onu onf/voltha-adapter-openonu
```
An example fo the [values.yaml](https://github.com/opencord/kind-voltha/blob/master/values.yaml)

### Deploying Tracing PoD
Optionally, a Jaeger tracing stack based all-in-one PoD can be deployed in voltha
setup to collect and analyze execution traces generated by various Voltha containers
for execution time analysis and troubleshooting. Refer to below links for more details
on Open Tracing approach:

[Open Tracing](https://opentracing.io/)
[Jaeger Distributed Tracing Stack](https://www.jaegertracing.io/)

To install the Voltha Tracing PoD use:
```shell
helm install --namespace voltha --name voltha-tracing ./voltha-tracing
```

### Kafka and Etcd

VOLTHA relies on [Kafka](https://kafka.apache.org/) for inter-component
communication and [Etcd](https://coreos.com/etcd/) for persistent storage.

#### Using  Kafka and Etcd instances

Kafka or Etcd values **MUST** be overridden when
deploying VOLTHA so that the VOLTHA components can locate the required
services. These values **MUST** be overridden when installing both the `voltha`
and the `voltha-adapter-simulated` chart. The relevant property keys are:

```shell
services:
  kafka:
    adapter:
      service: voltha-kafka.voltha.svc.cluster.local
      port: 9092
    cluster:
      service: voltha-kafka.voltha.svc.cluster.local
      port: 9092

  etcd:
    service: voltha-etcd-cluster-client.voltha.svc.cluster.local
    port: 2379

  controller:
    service: onos-openflow.default.svc.cluster.local
    port: 6653
```
## Installing and Configuring `voltctl`

[`voltctl`](https://github.com/opencord/voltctl) is a replacement for the
`voltha-cli` container in VOLTHA that provides access to the VOLTHA CLI when a
user connects to the container via `SSH`. `voltctl` provides a use model
similar to `docker`, `etcdctl`, or `kubectl` for VOLTHA.

As `voltctl` is a binary executable as opposed to a Docker container it must be
installed separately onto the machine(s) on which it is to be run. The [Release
Page](https://github.com/opencord/voltctl/releases) for `voltctl` maintains of
pre-built binaries that can be installed. The following is an example of how,
in the example environment, `voltctl` can be installed with bash completion and
configured:

```shell
sudo wget https://github.com/opencord/voltctl/releases/download/v1.3.0/voltctl-1.3.0-linux-amd64 -O /usr/bin/voltctl
source <(voltctl completion bash | sudo tee /etc/bash_completion.d/voltctl)
mkdir $HOME/.volt
voltctl -a v2 -s voltha-api.voltha.svc.cluster.local:55555 config > $HOME/.volt/config
```

## Delete VOLTHA charts

To remove the VOLTHA and Simulated Adapter deployments standard Helm commands
can be utilized:

```shell
helm delete --purge voltha voltha-adapter-simulated voltha-adapter-openolt voltha-adapter-openonu voltha-etcd-operator
```

## Known issues

Known VOLTHA issues are tracked in [JIRA](https://jira.opencord.org). Issues
that may specifically be observed, or at the very least were discovered, in
this environment can be found in JIRA via a [JIRA Issue
Search](https://jira.opencord.org/issues/?jql=status%20not%20in%20%28closed%2C%20Done%2CResolved%29%20and%20labels%20in%20%28helm%29%20and%20affectedVersion%20in%20%28%22VOLTHA%20v2.0%22%29).

## Pre-patchset submission Checks

On patchset submission, jobs are run in Jenkins that validate the correctness
of the helm charts.

The code for these jobs can be found in
[helm-repo-tools](http://gerrit.opencord.org/helm-repo-tools)

The two scripts that should be run to test are:

- `helmlint.sh`
- `chart_version_check.sh`
