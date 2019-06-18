# Helm Charts to Deploy VOLTHA 2.x

This repository defines [Kubernetes Helm](https://helm.sh/) charts that can be
used to deploy a [VOLTHA](https://www.opennetworking.org/voltha/) instance.

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

### Example deployment

The [VOLTHA Access Edge
Repository](https://github.com/ciena/voltha-access-edge) is one example of
deploying a Kubernetes environment as well deploying external component
required to perform authentication and IP address allocation. It was build
around deploying VOLTHA 1.x, but by skipping some steps and using the charts in
this repository it can be used to deploy VOLTHA 2.x.

#### Deploying Kubernetes and OpenFlow Controller

Follow the directions in the
[README.md](https://github.com/ciena/voltha-access-edge/blob/master/README.md#deploy-voltha)
file to deploy a Kubernetes cluster on top of a set of
[Vagrant](https://www.vagrantup.com/) virtual machines connected using an
instance of the [Trellis](https://www.opennetworking.org/trellis/) spine - leaf
networking fabric on top of a [Mininet](http://mininet.org/) virtual network.

**DO NOT** deploy VOLTHA following those directions, so **STOP** after the
[Initialize
Helm](https://github.com/ciena/voltha-access-edge/blob/master/README.md#initialize-helm)
step.

Once helm is initialized deploy the [ONOS OpenFlow
Controller](https://onosproject.org/) using the `make helm-onos` command.

#### Prerequite Helm Chart Repositories
To use the charts for VOLTHA the following two Helm repositories should be 
added to your helm environment:
```shell
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
```

#### Deploy VOLTHA

Clone the [VOLTHA Helm Chart](https://github.com/ciena/voltha-helm-charts)
repository and build the chart dependencies as follows:

```shell
git clone https://github.com/ciena/voltha-helm-charts
cd voltha-helm-charts
helm dependency build ./voltha
```

##### Deploy ETCD Operator
[ETCD Operator](https://github.com/coreos/etcd-operator) defines Kubernetes
resources types that allow you define ETCD clusters using standard Kubernetes
manifests. As the VOLTHA helm charts use these resources types the ETCD
operator must be installed before the VOLTHA helm chart.
```shell
helm install --namespace voltha --name voltha-etcd-operator stable/etcd-operator
```

##### Deploy VOLTHA Core Components
At this point the VOLTHA Helm charts can be used to deploy the VOLTHA core
components:

```shell
helm install --namespace voltha --name voltha ./voltha
```

#### Deploying Adapters
Deploying adapters is optional an you need only deploy those adapters which
are required for a given deployment

##### Adapters for Simulated OLT/ONU
After that is complete the adapters for the simulated devices can be deployed.
Deploying the adapters for the simulated olt/onu is optional as it deploying
any adapter. But by deploying the simulated olt/onu adapters it is possible to
create devices in VOLTHA and enable them without having access to hardware.
```shell
helm install --namespace voltha --name voltha-adapter-simulated ./voltha-adapter-simulated
```

##### Adapters for OpenOLT and OpenONU
The adapters for the OpenOLT and OpenONU are in separate helm charts. There are currently 
two versions of the OpenOLT adapter, one implemented in **Python** and one
implemented in **Go**. The same chart is used to deploy either the Python or Go
implementation and which one is used is determined by a value setting.

To install the **Python** implementation of the OpenOLT adapter use:
```shell
helm install --namespace voltha --name voltha-adapter-openolt ./voltha-adapter-openolt
```

To install the **Go** implementation of the OpenOLT adapter use:
```shell
helm install --set use_go=true --namespace voltha --name voltha-adapter-openolt ./voltha-adapter-openolt
```

**NOTE:** The Python and Go implementations are exclusive and should not be started in the same cluster.

To install the OpenONU adapter use:
```shell
helm install --namespace voltha --name voltha-adapter-openonu ./voltha-adapter-openonu
```

### Kafka and Etcd

VOLTHA relies on [Kafka](https://kafka.apache.org/) for inter-component
communication and [Etcd](https://coreos.com/etcd/) for persistent storage. By
default the VOLTHA Helm charts will deploy private instances of both Kafka and
Etcd in the same namespace into which VOLTHA is deployed. The settings that
control if private instances of these services are deployed can be overridden
using the `--set` or the `--values` options to the `helm install`. The relevant
property keys are:

- `private_etcd_cluster` - if `true` an instance of `etcd-operator` and an
  `etcd-cluster` will be deployed, else neither will be deployed
- `private_kafka_cluster` - if `true` an instance of Kafka will be deployed,
  else it won't be deployed

#### Using alternate Kafka and Etcd instances

If using alternate instance of Kafka or Etcd values **MUST** be overridden when
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

#### Configuring the number of Read-Only and Read-Write VOLTAH cores

By default the charts will create one R/O core and two R/W cores. This can be
configured by overriding two values:

- `replicas.ro_core` specifies the number of R/O core replicas
- `replicas.rw_core` specifies the number of **pairs** of R/W cores, so a value
  of one (1) gets you one (1) pair which is two (2) instances. A value of two
  (2) gets you two (2) pairs which is four (4) instances.

## Delete VOLTHA charts

To remove the VOLTHA and Simulated Adapter deployments standard Helm commands
can be utilized:

```shell
helm delete --purge voltha voltha-adapter-simulated voltha-adapter-openolt voltha-adapter-openonu voltha-etcd-operator
```

## Installing and Configuring `voltctl`

[`voltctl`](https://github.com/ciena/voltctl) is a replacement for the
`voltha-cli` container in VOLTHA that provides access to the VOLTHA CLI when a
user connects to the container via `SSH`. `voltctl` provides a use model
similar to `docker`, `etcdctl`, or `kubectl` for VOLTHA.

As `voltctl` is a binary executable as opposed to a Docker container it must be
installed separately onto the machine(s) on which it is to be run. The [Release
Page](https://github.com/ciena/voltctl/releases) for `voltctl` maintains of
pre-built binaries that can be installed. The following is an example of how,
in the example environment, `voltctl` can be installed with bash completion and
configured:

```shell
sudo wget https://github.com/ciena/voltctl/releases/download/0.0.0-dev/voltctl-0.0.0-dev-linux-x86_64 -O /usr/bin/voltctl
source <(voltctl completion bash | sudo tee /etc/bash_completion.d/voltctl)
mkdir $HOME/.volt
voltctl -a v2 -s voltha-api.voltha.svc.cluster.local:55555 config > $HOME/.volt/config
```

If you are using `voltctl` and do not wish to deploy the `voltha-cli`
container, then you can disable deployment of this container by adding the
`--set replicas.cli=0` option when installing the `voltha` chart.

## Troubleshooting

### Restart voltha-api-server (f.n.a. afrouter)

If you are getting an error similar to the following:

```shell
$ voltctl version
rpc error: code = Unknown desc = Unable to route method 'GetVoltha'
panic: rpc error: code = Unknown desc = Unable to route method 'GetVoltha'

goroutine 1 [running]:
main.main()
    /home/ubuntu/voltha-access-edge/voltctl/src/github.com/ciena/voltctl/cmd/voltctl.go:48 +0x56d
```

Then you can restart the API server by scaling it to 0 and then back to 1

```shell
kubectl scale --replicas=0 deployment -n voltha voltha-api-server
kubectl scale --replicas=1 deployment -n voltha voltha-api-server
```

Before scaling back to `1` be sure the current instance is gone using `kubectl
get -n voltha pods`

## Known issues

Known VOLTHA issues are tracked in [JIRA](https://jira.opencord.org). Issues
that may specifically be observed, or at the very least were discovered, in
this environment can be found in JIRA via a [JIRA Issue
Search](https://jira.opencord.org/issues/?jql=status%20not%20in%20%28closed%2C%20Done%2CResolved%29%20and%20labels%20in%20%28helm%29%20and%20affectedVersion%20in%20%28%22VOLTHA%20v2.0%22%29).

### Small Kubernetes Deployments
Kubernetes affinity is used to ensure the distribution of read-write core pods
across the Kubernetes nodes in support of optimum high availability. While
this *seems* to work for production sized Kubernetes clusters (2n+1 nodes,
where n >= 1) on smaller Kubernetes deployments it may mean that members
of a r/w core pair are scheduled on the same node, which may mean that on a
smaller Kubnernetes deployment *true* high availability is not achieved.

## Pre-patchset submission Checks

On patchset submission, jobs are run in Jenkins that validate the correctness
of the helm charts.

The code for these jobs can be found in
[helm-repo-tools](http://gerrit.opencord.org/helm-repo-tools)

The two scripts that should be run to test are:

- `helmlint.sh`
- `chart_version_check.sh`
