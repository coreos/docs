# Kubernetes DaemonSets vs fleet Global units

Running a container on all nodes is a common task. Aggregating service logs, collecting node metrics, or running a networked storage cluster all require a container to be replicated across all nodes. In fleet this is done with a [Global unit][global-units]. In Kubernetes, this is done with a [DaemonSet][daemon-sets].

## Global units

Global units in fleet are described with the `Global` option under the `[X-Fleet]` option in a unit file. For example the following unit file will run on all nodes in a cluster:

```yaml
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill busybox1
ExecStartPre=-/usr/bin/docker rm busybox1
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name busybox1 busybox /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop busybox1

[X-Fleet]
Global=true
```

Can be run and verified with the following commands:

```
$ fleetctl start hello.service 
Unit hello.service 
Triggered global unit hello.service start
$ fleetctl list-units
UNIT            MACHINE                         ACTIVE  SUB
hello.service   190c6f8f.../node1    			active  running
hello.service   c46a8ace.../node2    			active  running
hello.service   d77c07da.../node3    			active  running
```

## Kubernetes DaemonSets

[Kubernetes DaemonSets][k8s-daemonset] are a Kubernetes service which is run on all (or most) nodes in a cluster.

The DaemonSet can monitor for a specific label, but not create any pods, or it can include a container definition in its `spec` section.

### DaemonSet with Pod declaration

A DaemonSet which includes a `container` spec would look something like this:

```yaml
apiVersion: extensions/v1beta1 
kationind: DaemonSet
metadata:
  name: app-a
spec:
  template:
    metadata:
      name: app-a
      labels:
        daemon: app-a-daemon
    spec:
      containers:
      - name: app-a
        image: nginx
        ports:
        - containerPort: 80
          hostPort: 8000
          name: serverport
```

When applied, the DaemonSet creates work on the cluster:

```
$ kubectl get nodes  # Take a look at our nodes
NAME    		            STATUS                     AGE
controller1.infra.backend   Ready,SchedulingDisabled   44m
worker1.infra.backend          Ready                      44m
worker2.infra.backend       Ready                      44m
$ kubectl create -f app-a.yaml     # Deploy the DaemonSet
daemonset "app-a" created
$ kubectl get pods -o wide   # Inspect where DaemonSet pods are running
NAME          READY     STATUS    RESTARTS   AGE       IP          NODE
app-a-8bh7j   1/1       Running   0          2m        10.2.56.5   worker2.infra.backend
app-a-k8s6p   1/1       Running   0          2m        10.2.19.5   worker1.infra.backend
app-a-tgvw6   1/1       Running   0          2m        10.2.44.3   controller1.infra.backend
$ kubectl get ds  # Inspect the DaemonSet directly
NAME      DESIRED   CURRENT   READY     NODE-SELECTOR   AGE
app-a     3         3         0         <none>          2m
```

# DaemonSets on a subset of hosts

Sometimes a DaemonSet should only run on a subset of nodes. This may be because of resource limitations, beta feature roll-out, restricted monitoring needs, etc. Adding a `NodeSelector` to the `.spec.template.spec` restricts where the DaemonSet pods are scheduled.

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  labels:
    app: app-b
  name: app-b
spec:
  template:
    metadata:
      labels:
        app: app-b-shard
    spec:
      nodeSelector: 
        app: app-b-node
      containers:
      - name: app-b-shard
        image: nginx
        ports:
        - containerPort: 80
          hostPort: 8000
          name: serverport
```

When applying this DaemonSet before adding the chosen `app=app-b-node` label to any nodes, the DaemonSet does not get scheduled:

```
$ kubectl create -f app-b.yaml
daemonset "app-b" created
$ kubectl get ds
NAME      DESIRED   CURRENT   READY     NODE-SELECTOR    AGE
app-b     0         0         0         app=app-b-node   1m
```

Once we add the label to one or more nodes, the pods are scheduled there:

```
$ kubectl label node worker1.infra.backend app=app-b-node
node "worker1.infra.backend" labeled
$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
app-b-r4y70   1/1       Running   0          24s
$ kubectl get ds
NAME      DESIRED   CURRENT   READY     NODE-SELECTOR    AGE
app-b     1         1         0         app=app-b-node   2m
```

Removing the label from the node unschedules the pod running there:

```
$ kubectl label node worker1.infra.backend app-
node "worker1.infra.backend" labeled
$ kubectl get ds
NAME      DESIRED   CURRENT   READY     NODE-SELECTOR    AGE
app-b     0         0         0         app=app-b-node   4m
```

For more information, check the [Kubernetes DaemonSets admin guide][k8s-daemonset] and the [DaemonSets design document][k8s-daemonset-design].

[daemon-sets]: http://kubernetes.io/docs/admin/daemons/
[global-units]: https://coreos.com/fleet/docs/latest/unit-files-and-scheduling.html#systemd-specifiers
[k8s-daemonset-design]: https://github.com/kubernetes/community/blob/master/contributors/design-proposals/daemon.md
[k8s-daemonset]: http://kubernetes.io/docs/admin/daemons/
