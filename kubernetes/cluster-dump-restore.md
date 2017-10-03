## Migration of Kubernetes cluster deployment state

_The deployment state of the Kubernetes cluster is stored in etcd. If you're concerned about backing up this information, you should look into backing up the etcd data directory for each etcd instance in your cluster. This can be done via an [etcd-based backup strategy](https://github.com/coreos/etcd/tree/master/contrib/systemd/etcd2-backup-coreos), or via snapshotting the underlying block device that backs the etcd data directory. Backing up Kubernetes clusters is not the purpose of this document._

This document's primary purpose is to show how to migrate the deployment state from one Kubernetes cluster to another. The clusters may have different versions, pod/service network cidrs, number of nodes, etc.

For the remainder of this document, the cluster that is being dumped will be referred to as the *source cluster*. The cluster that is being restored to will be called the *target cluster*. The goal is to migrate state from the *source cluster* to the *target cluster*.

This migration process boils down to selectively omitting state that is not portable between clusters, as well as making some assumptions about the clusters we're dealing with. Those assumptions include:
* **kube-dns add-on** This allows abstracting away the services' clusterIPs, which is inherentely non-portable across clusters with different serviceCIDRS.

* **api object compatibility** Any api object type (eg: replicaset) that is dumped from the *source cluster* must be supported by the *target cluster*.

	As a general rule, if the *target cluster's* Kubernetes version is >= *source cluster's* Kubernetes version, this will not be a problem.

* **blank target slate** The *target cluster* to has no deployment state beyond a "stock" cluster. In the CoreOS case, the stock cluster state is everything in the `kube-system` namespace along with the service token in the default namespace.

	If the *target cluster* has other pre-existing state, more precautions must be taken to ensure there are no undesired interactions between pre-existing resources on the *target cluster* and the dump coming from *source cluster*.

	Name conflicts are easy to defect, but more subtle issues like services selecting unintended pre-existing pods is another more subtle situation that can arise. We will assume **blank target slate** for the remainder of this document.

As of now, this is not entirely supported upstream. This `get --export` flag is supposed to do something like this, but leaves plenty of state that we do not consider to be portable in this case. [github issue](https://github.com/kubernetes/kubernetes/issues/21582).

We'll explain step-by-step how the CoreOS infrastructure team migrates deployments between Kubernetes clusters today.

### Dump from the source cluster

Create a directory to hold your dump files:

```shell
mkdir ./cluster-dump
```


First, get a list of all namespaces that are not `kube-system` or `default` and record them to a file on disk. This represents the list of namespaces that we want to migrate:

```shell
kubectl get --export -o=json ns | \
jq '.items[] |
	select(.metadata.name!="kube-system") |
	select(.metadata.name!="default") |
	del(.status,
        .metadata.uid,
        .metadata.selfLink,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.generation
    )' > ./cluster-dump/ns.json
```


For each of these namespaces, dump all services, controllers (rc,ds,replicaset,etc), secrets and daemonsets to a file on disk. Strip any non-portable fields from the objects. If you wish to migrate additional controller resource types (replicasets, deployments, etc), make sure to add them to the resource type list:

```shell
for ns in $(jq -r '.metadata.name' < ./cluster-dump/ns.json);do
    echo "Namespace: $ns"
    kubectl --namespace="${ns}" get --export -o=json svc,rc,secrets,ds | \
    jq '.items[] |
        select(.type!="kubernetes.io/service-account-token") |
        del(
            .spec.clusterIP,
            .metadata.uid,
            .metadata.selfLink,
            .metadata.resourceVersion,
            .metadata.creationTimestamp,
            .metadata.generation,
            .status,
            .spec.template.spec.securityContext,
            .spec.template.spec.dnsPolicy,
            .spec.template.spec.terminationGracePeriodSeconds,
            .spec.template.spec.restartPolicy
        )' >> "./cluster-dump/cluster-dump.json"
done
```

Notice that pods and service tokens are explicitly omitted altogether, as they are inherently non-portable resources that are created and managed by other components. The general rule for what is portable across heterogenous clusters is is "services (resolved via cluster DNS), controllers and secrets that aren't service tokens".

**Make sure you clean up these JSON files. They contain your secrets!**

### Restore to target cluster

Create the set of namespaces needed for your deployment state:

```shell
kubectl create -f cluster-dump/ns.json
```

Restore the resource state:

```shell
kubectl create -f cluster-dump/cluster-dump.json
```

