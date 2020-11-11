# Install VOLTHA

## Install a virtual Kubernetes cluster (optional)

Install `k3d`:

```
curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

Create the cluster:

```
k3d cluster create voltha-dev --servers 3
```

Export the configuration:
```
k3d kubeconfig write voltha-dev
export KUBECONFIG="$(k3d kubeconfig write voltha-dev)"
```
Install `kubectl` if needed:
```
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

Install `helm` if needed:

```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
## Prerequisites

*This is only required if you will deploy `bbsim-sadis-server`*

```
kubectl create configmap kube-config "--from-file=kube_config=$KUBECONFIG"
```

## Installing VOLTHA infrastructure

```
helm upgrade --install voltha-infra voltha-infra --set onos-classic.replicas=3
```

Foward ONOS ssh port:

```
kubectl port-forward svc/voltha-infra-onos-classic-hs 8101:8101
```

### Deploying a clustered ONOS:

```
helm upgrade --install voltha-infra voltha-infra \
  --set onos-classic.replicas=3,onos-classic.atomix.replicas=3 \
  --set kafka.replicaCount=3,kafka.zookeeper.replicaCount=3 \
  --set etcd.statefulset.replicaCount=3
```

## TODOs

- Add support to load a Technology Profile in ETCD
- Add support to load a MIB Template in ETCD
