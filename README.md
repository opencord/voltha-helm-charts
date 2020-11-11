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

## Example deployment

The following describes how to deploy VOLTHA.

### Prerequisites
To use the charts for VOLTHA the following Helm repositories should be
added to your helm environment:
```shell
helm repo add onf https://charts.opencord.org
helm repo update
```

#### Temporary steps before the patch is merged

These are a set of steps required to bring up the environment before this patch is merged and the charts are published
```
helm repo add kokuwa https://kokuwaio.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm dep update voltha-infra
helm dep update voltha-stack
```

#### Load the kubernetes config in the cluster

*This is only required if you will deploy `bbsim-sadis-server`*

```
kubectl create namespace infra
kubectl create configmap -n infra kube-config "--from-file=kube_config=$KUBECONFIG"
```

### Installing VOLTHA infrastructure

VOLTHA relies to a set of infrastructure components (ONOS, Kafka, ETCD, ...) that
can be installed via the `voltha-infra` helm chart:

```shell
helm upgrade --install -n infra voltha-infra voltha-infra
```

By default the `voltha-infra` helm chart will install one instance of each component,
but that can be customized via a custom value file or via flags, eg:

```shell
helm upgrade --install -n infra voltha-infra voltha-infra \
  --set onos-classic.replicas=3,onos-classic.atomix.replicas=3 \
  --set kafka.replicaCount=3,kafka.zookeeper.replicaCount=3 \
  --set etcd.statefulset.replicaCount=3
```

#### Accessing the ONOS Cli

In order to access the ONOS CLI you need to expose the ONOS SSH port:

```shell
kubectl -n infra port-forward svc/voltha-infra-onos-classic-hs 8101:8101
```

Once that is done you can `ssh` into ONOS by:

```shell
ssh karaf@127.0.0.1 -p 8101
```

#### Customizing the ONOS configuration

The ONOS configuration is defined in two separate variables in the value file:

- `onos.netcfg`: multiline text (json)
- `onos.componentConfig`: yaml list of component name and multiline text

Being the content of the configuration multiline text is not possible to override the configuration via `--set` it's
necessary to create a custom value file with your content and install the chart with:

```shell
helm upgrade --install -n infra voltha-infra voltha-infra -f myfile.yaml
```

#### Support for logging and tracing (optional)

VOLTHA comes with support for Jaeger and EFK (Elastic, Fluentd, Kibana) integration.
In order to deploy those components together with the infrastructure add these flags to the command to install
the VOLTHA infrastructure:

```shell
helm upgrade --install -n infra voltha-infra voltha-infra \
  --set voltha-tracing.enabled=true \
  --set efk.enabled=true
```

Once `kibana` is running execute this command to properly configure it:

```
 curl -v -X POST -H Content-type:application/json -H kbn-xsrf:true http://localhost:5601/api/saved_objects/index-pattern/logst* -d '{"attributes":{"title":"logst*","timeFieldName":"@timestamp"}}'
```

> _NOTE In order to send a request to `kibana` you need to expose the port with
 `kubectl port-forward -n infra --address 0.0.0.0 svc/voltha-infra-kibana 5601`_

### Deploy VOLTHA

VOLTHA encompass multiple components that work together to manage OLT devices.
Such group of component is known as a `stack` and is composed by:

- VOLTHA core
- OfAgent (OpenFlow Agent)
- OLT Adapter
- ONU Adapter

To deploy a VOLTHA stack with the opensource adapters (OpenOLT and OpenONU) you can use the `voltha-stack` chart:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra
```

> _We suggest to keep VOLTHA separated by deploying them in different namespaces._
> _For example to install a second VOLTHA stack do:_
>
> ```
> helm upgrade --install --create-namespace \
>  -n voltha2 voltha2 voltha-stack \
>  --set global.stack_name=voltha2 \
>  --set voltha_infra_name=voltha-infra \
>  --set voltha_infra_namespace=infra
> ```

#### Enable tracing in VOLTHA (optional)

To enable tracing across the VOLTHA components add `--set global.tracing.enabled=true` to the install command, for example:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set global.tracing.enabled=true
```

#### Enable log correlation in VOLTHA (optional)

To enable log correlation across the VOLTHA components add `--set global.log_correlation.enabled=true` to the install command, for example:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set global.log_correlation.enabled=true
```

### Deploy BBSim

BBSim is a broadband simulator tool that is used as an OpenOLT compatible device
in emulated environments.

In order to install a single BBSim instance to test VOLTHA,
you can use the BBSim helm chart:

```shell
helm install -n voltha1 bbsim10 onf/bbsim --set olt_id=10
```

> _While it's not mandatory to install BBSim in the same namespace as the VOLTHA stack it's advised to do so to make explicit which stack is controlling it._

### Installing and Configuring `voltctl`

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

## Post installation

Ok, now I have VOLTHA installed and everything is running.
What can I do with it?

### Sanity Checks

As first make sure that all components are running correctly:

```shell
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                  READY   STATUS      RESTARTS   AGE
infra         bbsim-sadis-server-6fcbdf9bd8-s7srz                   1/1     Running     0          14m
infra         elasticsearch-master-0                                1/1     Running     0          14m
infra         voltha-infra-etcd-0                                   1/1     Running     0          14m
infra         voltha-infra-fluentd-elasticsearch-9df8b              1/1     Running     0          14m
infra         voltha-infra-fluentd-elasticsearch-rgbvb              1/1     Running     0          14m
infra         voltha-infra-fluentd-elasticsearch-vfrcg              1/1     Running     0          14m
infra         voltha-infra-freeradius-7cbcdc66f-fhlt6               1/1     Running     0          14m
infra         voltha-infra-kafka-0                                  1/1     Running     0          14m
infra         voltha-infra-kibana-6cc8b8f779-7tlvp                  1/1     Running     0          14m
infra         voltha-infra-onos-classic-0                           1/1     Running     0          14m
infra         voltha-infra-voltha-infra-onos-config-loader-whdtz    0/1     Completed   3          14m
infra         voltha-infra-voltha-tracing-jaeger-7fffb6cdf6-l5r8s   1/1     Running     0          14m
infra         voltha-infra-zookeeper-0                              1/1     Running     0          14m
voltha1       bbsim10-6f9584b4dd-txtj4                              1/1     Running     0          66s
voltha1       voltha1-voltha-adapter-openolt-5b5844b5b6-htlvp       1/1     Running     0          91s
voltha1       voltha1-voltha-adapter-openonu-85749df5fc-n5kdd       1/1     Running     0          91s
voltha1       voltha1-voltha-ofagent-5b5dc9b7b5-htxt6               1/1     Running     0          91s
voltha1       voltha1-voltha-rw-core-7d69cb4567-9cn2n               1/1     Running     0          91s
```
> _Note that is completely fine if the `onos-config-loader` pod restarts a few times, it is a job that loads
configuration into ONOS and will fail until ONOS is ready to accept the configuration._

Once all the kubernetes pods are in `Ready` and `Running` state make sure the adapter registered with the core.

In order to use `voltctl` you need to expose the `voltha-api` service:
```shell
kubectl -n voltha1 port-forward svc/voltha1-voltha-api 55555
```

> _If you have deployed multiple stacks you need to change the `port-forward` command to connect to the stack you want to operate, eg:_
> 
> ```
> kubectl -n voltha2 port-forward svc/voltha2-voltha-api 55555
> ```

Once that is done you can query `rw-core` for a list of adapters:

```shell
$ voltctl adapter list
ID                     VENDOR              TYPE                 ENDPOINT                     VERSION            CURRENTREPLICA    TOTALREPLICAS    LASTCOMMUNICATION
brcm_openomci_onu_1    VOLTHA OpenONUGo    brcm_openomci_onu    voltha1_brcm_openomci_onu    unknown-version    1                 1
openolt_1              VOLTHA OpenOLT      openolt              voltha1_openolt              3.0.2              1                 1
```

### Provisioning an OLT

Once you completed the `Sanity Checks` you can provision an OLT.
We suggest to start with `BBSim` (see above for installation instructions).

To create and enable the OLT device in VOLTHA you can use these `voltctl` commands:

```shell
voltctl device create -t openolt -H bbsim10.voltha1.svc:50060
voltctl device list --filter Type~openolt -q | xargs voltctl device enable
```

Once the OLT device is enabled you will see that an emulated ONU is reported to VOLTHA:

```shell
$ voltctl device list
ID                                      TYPE                 ROOT     PARENTID                                SERIALNUMBER    ADMINSTATE    OPERSTATUS    CONNECTSTATUS    REASON
42b04dfc-a253-46a0-8b96-da0551648fd5    brcm_openomci_onu    false    92a67593-06fa-4fad-87cb-b8befab90a56    BBSM00000001    ENABLED       ACTIVE        REACHABLE        initial-mib-downloaded
92a67593-06fa-4fad-87cb-b8befab90a56    openolt              true     b367cec6-a771-417a-94a7-8b8922fac587    BBSIM_OLT_0     ENABLED       ACTIVE        REACHABLE
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
