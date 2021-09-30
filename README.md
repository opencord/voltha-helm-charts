# Helm Charts to Deploy VOLTHA 2.x

This repository defines [Kubernetes Helm](https://helm.sh/) charts that can be
used to deploy a [VOLTHA](https://www.opennetworking.org/voltha/) instance.
More information and documentation can be found in the [voltha docs](https://docs.voltha.org/).

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

#### Load the kubernetes config in the cluster

*This is only required if you will deploy `bbsim-sadis-server`*

```
kubectl create namespace infra
kubectl create configmap -n infra kube-config "--from-file=kube_config=$KUBECONFIG"
```
*If the `kubectl create namespace infra` outputs `Error from server (AlreadyExists): namespaces "infra" already exists`
that is fine and you can proceed. That output means that somebody already deployed in that cluster and created the
`infra` namespace.*

### Installing VOLTHA infrastructure

VOLTHA relies to a set of infrastructure components (ONOS, Kafka, ETCD, ...) that
can be installed via the `voltha-infra` helm chart:

```shell
helm upgrade --install --create-namespace -n infra voltha-infra onf/voltha-infra
```

By default the `voltha-infra` helm chart will install one instance of each component,
but that can be customized via a custom value file or via flags, eg:

```shell
helm upgrade --install --create-namespace -n infra voltha-infra onf/voltha-infra \
  --set onos-classic.replicas=3,onos-classic.atomix.replicas=3 \
  --set kafka.replicaCount=3,kafka.zookeeper.replicaCount=3 \
  --set etcd.statefulset.replicaCount=3
```

To deploy a released version of the `voltha-infra` chart you can specify the `--version` in the command.
As an example to deploy the infrastructure for the 2.8 LTS release you can use `--version 2.8.0` like:
```shell
helm upgrade --install --create-namespace -n infra --version 2.8.0 voltha-infra onf/voltha-infra
```

#### Accessing the ONOS Cli and API

In order to access the ONOS CLI you need to expose the ONOS SSH port:

```shell
kubectl -n infra port-forward --address 0.0.0.0 svc/voltha-infra-onos-classic-hs 8101:8101
```

Once that is done you can `ssh` into ONOS by:

```shell
ssh karaf@127.0.0.1 -p 8101
```

To access the ONOS Rest API and GUI you need to expose:

```shell
kubectl -n infra port-forward --address 0.0.0.0 svc/voltha-infra-onos-classic-hs 8181:8181
```

#### Customizing the ONOS configuration

The ONOS configuration is defined in two separate variables in the value file:

- `onos.netcfg`: multiline text (json)
- `onos.componentConfig`: yaml list of component name and multiline text

Being the content of the configuration multiline text is not possible to override the configuration via `--set` it's
necessary to create a custom value file with your content and install the chart with:

```shell
helm upgrade --install --create-namespace -n infra voltha-infra onf/voltha-infra -f myfile.yaml
```

#### Support for logging and tracing (optional)

VOLTHA comes with support for Jaeger and EFK (Elastic, Fluentd, Kibana) integration.
In order to deploy those components together with the infrastructure add these flags to the command to install
the VOLTHA infrastructure:

```shell
helm upgrade --install --create-namespace -n infra voltha-infra onf/voltha-infra \
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
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra
```

> _We suggest to keep VOLTHA separated by deploying them in different namespaces._
> _For example to install a second VOLTHA stack do:_
>
> ```
> helm upgrade --install --create-namespace \
>  -n voltha2 voltha2 onf/voltha-stack \
>  --set global.stack_name=voltha2 \
>  --set voltha_infra_name=voltha-infra \
>  --set voltha_infra_namespace=infra
> ```

If you add a different number of ONOS you need also to tell the `ofagent` to connect to all of them
by adding it to the `voltha-stack` command. The following is an example for 3 ONOS instances.
```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set voltha.onos_classic.replicas=3
```

To deploy a released version of the `voltha-stack` chart you can specify the `--version` in the command.
As an example to deploy VOLTHA 2.8 LTS release you can use `--version 2.8.0` like:
```shell
helm upgrade --install --create-namespace \
  -n voltha1 --version 2.8.0 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra
```

#### Enable tracing in VOLTHA (optional)

To enable tracing across the VOLTHA components add `--set global.tracing.enabled=true` to the install command, for example:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set global.tracing.enabled=true
```

> NOTE that the `Jaeger` pod must be up and running before the VOLTHA stack starts in order for the components to register.

#### Enable log correlation in VOLTHA (optional)

To enable log correlation across the VOLTHA components add `--set global.log_correlation.enabled=true` to the install command, for example:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set global.log_correlation.enabled=true
```

### Use the OpenONU python adapter

Up to release `0.10.0` of the `voltha-stack` chart you can still use the openonu-py version of the adapter.

> NOTE that this adapter is now unsupported, so you're in uncharted territory from now on.

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set voltha-adapter-openonu.use_openonu_adapter_go=false
```

### Deploy BBSim

BBSim is a broadband simulator tool that is used as an OpenOLT compatible device
in emulated environments.

In order to install a single BBSim instance to test VOLTHA,
you can use the BBSim helm chart:

```shell
helm upgrade --install -n voltha1 bbsim0 onf/bbsim --set olt_id=10
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
in the example environment, `voltctl` can be installed with bash completion:

```shell
HOSTOS="$(uname -s | tr "[:upper:]" "[:lower:"])"
HOSTARCH="$(uname -m | tr "[:upper:]" "[:lower:"])"
if [ "$HOSTARCH" == "x86_64" ]; then
    HOSTARCH="amd64"
fi
sudo wget https://github.com/opencord/voltctl/releases/download/v1.3.1/voltctl-1.3.1-$HOSTOS-$HOSTARCH -O /usr/local/bin/voltctl
source <(voltctl completion bash)
```

If you are exposing the `voltha-api` service on `127.0.0.1:55555` as per the examples in this guide there is no need to configure
`voltctl`, if you are exposing the service on a different port/IP you configure `voltctl` with:

```shell
voltctl -s <voltha-api-ip>:<voltha-api-port> config > $HOME/.volt/config
```

### Deploying a different workflow

If you want to deploy VOLTHA with the appropriate configuration for the `dt` or `tt` worflow two example files are provided in the `./examples` folder.

For you convenience here are the commands to deploy those workflows:

**DT**

```shell
helm upgrade --install -n infra voltha-infra onf/voltha-infra -f examples/dt-values.yaml
helm upgrade --install -n voltha1 bbsim0 onf/bbsim --set olt_id=10 -f examples/dt-values.yaml
helm upgrade --install --create-namespace   -n voltha1 voltha1 onf/voltha-stack   --set global.stack_name=voltha1   --set voltha_infra_name=voltha-infra   --set voltha_infra_namespace=infra
```

**TT**

```shell
helm upgrade --install -n infra voltha-infra onf/voltha-infra -f examples/tt-values.yaml
helm upgrade --install -n voltha1 bbsim0 onf/bbsim --set olt_id=10 -f examples/tt-values.yaml
helm upgrade --install --create-namespace   -n voltha1 voltha1 onf/voltha-stack   --set global.stack_name=voltha1   --set voltha_infra_name=voltha-infra   --set voltha_infra_namespace=infra
```

### Using an ingress controller

A process to expose the VOLTHA API external to the Kubernetes cluster was described
using the `port-forward` option from the `kubectl` command line tool. This mechanism,
while convenient, is not recommended for a production deployment. For a production
deployment a [Kubernetes Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress/) is recommended.

There are many choices when deploying an ingress controller including open source and
commercial options. This document does not recommend or require a specific
ingress controller, but it is important to note that VOLTHA has only been tested
using the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
and thus examples for Kubernetes manifests are offered in that context.

To deploy the NGINX ingress controller please see the [instructions](https://kubernetes.github.io/ingress-nginx/deploy/) on the NGINX site. For instructions on deploying
an ingress controller when using a kind cluster, as is common for VOLTHA development,
please see the [instructions](https://kind.sigs.k8s.io/docs/user/ingress/) on the
kind site.

#### VOLTHA Helm Charts

The VOLTHA Helm charts were updated to deploy Ingress resources for the etcd
and VOLTHA API services. By default these Ingress resources are disabled and
not deployed.

By default the Ingress resources are defined without a `host` option. This
is convenient when running a single stack but is not sufficient when
running multiple stacks and enabling external access to both stacks through
the ingress controller.

When using multiple stacks and an Ingress controller virtual hosts will be
required to differentiate the stacks and direct API requests to the correct
service. If `--set voltha.ingress.enableVirtualHosts=true` is used when
installing the voltha stack then a virtual host will be defined using
`<stack-name>.voltha.local`. In order to use this virtual host this virtual
host name will need to resolve to the IP address of your Ingress controller.

To include the Ingress resources when deploying VOLTHA the following
values need to be set:

##### When Installing Infra

`--set etcd.ingress.enabled=true`

##### When Installing the VOLTHA Stack

`--set voltha.ingress.enabled=true`

#### Usage with `voltctl`

Once the Ingress resources are defined `voltctl` should be able to access the
VOLTHA deployment without having to run `kubectl port-forward` commands for
each specific service. The configuration to `voltctl` to utilize the ingress
controller can be specified either via the command line options or via the
voltctl configuration file (default `~/.volt/config`).

The important settings are

**NOTE:** _Note hostname and port will vary depending on how you deploy as
well as how the Ingress controller is accessed from outside the cluster._

- `--server`/`server` - the value of the external IP address of the ingress
controller and the port on which it is listening (_ex:_ `localhost:443` or
`voltha1.voltha.com:30474`).

- `--kvstore`/`kvstore` - the value of the external IP address of the ingress
controller and the point on which it is listening (_ex:_ `localhost:443`)

- `--tls`/`tls.useTls` - indicates that TLS should be used when communicating
through the ingress controller, which is required for the NGINX ingress controller
(_ex:_ `true`)

_CLI example_:

```bash
voltctl --server=voltha1.voltha.com:443 --kvstore=localhost:443 --tls version
```

_`voltctl` configuration file example:_

```yaml
server: voltha1.example.com:443
kafka: localhost:443
kvstore: localhost:443
tls:
  useTls: true
  caCert: ""
  cert: ""
  key: ""
  verify: false
grpc:
  timeout: 5m0s
  maxCallRecvMsgSize: 4M
kvstoreconfig:
  timeout: 5s
```

#### Ingress Controller References

1. [Guide to setting up ingress on a kind cluster.](https://kind.sigs.k8s.io/docs/user/ingress/)

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
voltha1       bbsim0-6f9584b4dd-txtj4                              1/1     Running     0          66s
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
kubectl -n voltha1 port-forward --address 0.0.0.0 svc/voltha1-voltha-api 55555
```

> _If you have deployed multiple stacks you need to change the `port-forward` command to connect to the stack you want to operate, eg:_
>
> ```
> kubectl -n voltha2 port-forward --address 0.0.0.0 svc/voltha2-voltha-api 55555
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
voltctl device create -t openolt -H bbsim0.voltha1.svc:50060
voltctl device list --filter Type~openolt -q | xargs voltctl device enable
```

Once the OLT device is enabled you will see that an emulated ONU is reported to VOLTHA:

```shell
$ voltctl device list
ID                                      TYPE                 ROOT     PARENTID                                SERIALNUMBER    ADMINSTATE    OPERSTATUS    CONNECTSTATUS    REASON
42b04dfc-a253-46a0-8b96-da0551648fd5    brcm_openomci_onu    false    92a67593-06fa-4fad-87cb-b8befab90a56    BBSM00000001    ENABLED       ACTIVE        REACHABLE        initial-mib-downloaded
92a67593-06fa-4fad-87cb-b8befab90a56    openolt              true     b367cec6-a771-417a-94a7-8b8922fac587    BBSIM_OLT_0     ENABLED       ACTIVE        REACHABLE
```

### Running the sanity test (optional)

If you want to run the `sanity-test` you can:

```shell
git clone https://github.com/opencord/voltha-system-tests.git && cd voltha-system-tests

export KUBECONFIG="$(k3d kubeconfig write voltha-dev)" # or you KUBECONFIG file
mkdir -p ~/.volt
voltctl config > ~/.volt/config
export VOLTCONFIG="~/.volt/config"
make sanity-kind
```
> This assumes that both the `onos-ssh`, `onos-rest` and `voltha-api` ports are forwarded on the host and bbsim was installed with ` helm install -n voltha1 bbsim0 onf/bbsim --set olt_id=10`.

### Remove VOLTHA from your cluster

> NOTE that this is not required as part of your development loop. In that case you should be able to simply upgrade the component you are working on (see next section).

If you need to completely uninstall everything that you installed following this guide, you can simply remove the installed `helm` charts:
```shell
helm del -n voltha1 voltha1 bbsim0
helm del -n infra voltha-infra
```

If you are using the `bbsim-sadis-server` component as well then remember to remove the `kube-config` configmap as well:

```shell
kubectl delete cm -n infra kube-config
```

### Upgrade a component

> NOTE that this section is intended for development purposes, it's not a guide for in service software upgrade.

If you want to upgrade a component within a VOLTHA stack you can use the same `helm upgrade` command as per the
installation guide while providing a new image for one of the component, eg:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set voltha-adapter-openonu.images.adapter_open_onu_go.repository=voltha/voltha-openonu-adapter-go \
  --set voltha-adapter-openonu.images.adapter_open_onu_go.tag=test
```

If as part of your development process you have published a new image with the same tag you can force it's download simply
by restarting the pod, for example:

```shell
kubectl delete pod -n voltha1 $(kubectl get pods -n voltha1 | grep openonu | awk '{print $1}')
```

> In order for this to work the `imagePullPolicy` has to be set to `Always`.

### Develop with latest code

The voltha-infra and voltha-stack charts pull the referenced version of every component, if your charts are up to date
that will be the latest released one.
If for your development and testing you'd like to have all the `master` of each component, independently if that has
been officially tagged and release there is a provided `dev-values.yaml`. You can use it for the a `voltha-stack` like so:
```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  -f examples/dev-values.yaml
```
After the feature you are working on is released by modifying the `VERSION` file and removing `-dev` you
can remove the `dev-values.yaml` file from your helm command.

### Test changes to a chart

If you are working on an helm chart you can install a stack omitting that component,
and then use the local copy of your chart to install it, eg:

```shell
helm upgrade --install --create-namespace \
  -n voltha1 voltha1 onf/voltha-stack \
  --set global.stack_name=voltha1 \
  --set voltha_infra_name=voltha-infra \
  --set voltha_infra_namespace=infra \
  --set voltha-adapter-openonu.enabled=false

helm upgrade --install --create-namespace \
  -n voltha1 opeonu-adapter voltha-adapter-openonu \
  --set global.stack_name=voltha1 \
  --set adapter_open_onu.kv_store_data_prefix=service/voltha/voltha1_voltha1 \
  --set adapter_open_onu.topics.core_topic=voltha1_voltha1_rwcore \
  --set adapter_open_onu.topics.adapter_open_onu_topic=voltha1_voltha1_brcm_openomci_onu \
  --set services.kafka.adapter.service=voltha-infra-kafka.infra.svc \
  --set services.kafka.cluster.service=voltha-infra-kafka.infra.svc \
  --set services.etcd.service=voltha-infra-etcd.infra.svc
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
[helm-repo-tools](https://gerrit.opencord.org/admin/repos/helm-repo-tools)

The two scripts that should be run to test are:

- `helmlint.sh`
- `chart_version_check.sh`
