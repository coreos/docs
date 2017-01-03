# Container replication in Kubernetes vs fleet

[comment]: # (ReplicaSets and how they differ from fleet template unit files)

Replica Sets, Deployments, and Replication Controllers are all mechanisms Kubernetes uses to manage where, when, and how many of a particular Pod are running. They are functionally similar to and more roubst than fleet's use of systemd unit files.

[comment]: # (Introduction about the tools used to replicate a service in fleet vs k8s)

## Tooling Breakdown

| Task                          | Kubernetes solution                                   | Fleet solution                                            |
|:-----------------------------:|:-----------------------------------------------------:|:---------------------------------------------------------:|
| Defining a replicated service | [Deployments][k8s-deployments]                        | [systemd template unit files][fleet-template-unit-files]  |
|                               | [Replication Controllers][k8s-replication-controller] |                                                           |
|                               | [Replica Sets][k8s-replica-set]                       |                                                           |

## Fleet Deployments

A fleet deployment can be defined using systemd unit files. For instance let's define the service `hello@.service`:

```
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
```

The above service can be deployed to three of our nodes using the following syntax:

```
core@core-01 ~ $ fleetctl start hello@{1,2,3}
Unit hello@1.service inactive
Unit hello@2.service inactive
Unit hello@3.service inactive
Unit hello@1.service launched on 370aa586.../172.17.8.102
Unit hello@2.service launched on a7abd52c.../172.17.8.101
Unit hello@3.service launched on ff3fba16.../172.17.8.103
core@core-01 ~ $ fleetctl list-units
UNIT        MACHINE             ACTIVE  SUB
hello@1.service 370aa586.../172.17.8.102    active  running
hello@2.service a7abd52c.../172.17.8.101    active  running
hello@3.service ff3fba16.../172.17.8.103    active  running
```

## Kubernetes Replication Controllers and Replica Sets

Kubernetes [Replica Sets][k8s-replica-set] are the closest analogue to a fleet unit file. The Kubernetes documentation describes it as *"A ReplicaSet ensures that a specified number of pod 'replicas' are running at any given time."*. The Replica Set feature is more useful as a component of Kubernetes Deployments (more on those below) but are worth going into on their own.

Here we will define a *very* simple Replica Set which replicates a 'Hello World' pod three times across our Kubernetes cluster.

`replica-set.yaml`:

```yaml
apiVersion: extensions/v1beta1
kind: ReplicaSet
metadata:
  name: foo
spec:
  replicas: 3
  # Selectors default to the values in the pod template,
  # but can be over-ridden with the `selector` directive.
  selector:
    matchLabels:
      tier: foo
    matchExpressions:
      - key: tier
        operator: In
        values:
        - foo
  template:
    metadata:
      labels:
        app: bar
        tier: foo
    spec:
      # This pod doesn't serve a useful purpose,
      # It just repeats 'bar' every five seconds.
      containers:
      - name: hello-world-pod
        image: busybox:latest
        command: ['sh', '-c', 'while true; do echo hello world && sleep 5; done']
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
```

The above Replica Set can be deployed and verified with the following commands:

```
$ kubectl create -f replica-set.yaml 
replicaset "foo" created
13:12 $ kubectl get rs,pods
NAME      DESIRED   CURRENT   READY     AGE
rs/foo    3         3         3         1m

NAME           READY     STATUS    RESTARTS   AGE
po/foo-ao2lk   1/1       Running   0          1m
po/foo-c5m8e   1/1       Running   0          1m
po/foo-p227f   1/1       Running   0          1m
13:11 $ kubectl describe rs/foo
Name:        foo
Namespace:   default
Image(s):    busybox:latest
Selector:    tier=foo,tier in (foo)
Labels:      app=bar-app
             tier=foo
Replicas:    3 current / 3 desired
Pods Status:    3 Running / 0 Waiting / 0 Succeeded / 0 Failed
No volumes.
Events:
  FirstSeen    LastSeen    Count    From                SubObjectPath    Type        Reason            Message
  ---------    --------    -----    ----                -------------    --------    ------            -------
  16s        16s        1    {replicaset-controller }            Normal        SuccessfulCreate    Created pod: foo-c5m8e
  16s        16s        1    {replicaset-controller }            Normal        SuccessfulCreate    Created pod: foo-ao2lk
  16s        16s        1    {replicaset-controller }            Normal        SuccessfulCreate    Created pod: foo-p227f
```

## Kubernetes Deployments

Deployments are the *recommended* way to manage Pod orchestration. They are a layer of abstraction above Replica Sets which can update, re-deploy, rollback, and scale a set of Pods.

To demonstrate how powerful Deployments are we will do the following:

- Deploy 3 replicas of `myapp v1`.
- Create a rolling update of `myapp v2`.
- Create *another* rolling update to `myapp v3`, which is broken.
- Rollback from `myapp v3` to `myapp v2`.


First let's start by creating a file `deploy-v1.yaml` which will echo `v1` into the logs.

`deploy-v1.yaml`:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app-deploy
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: busybox:latest
        command: ['sh', '-c', 'while true; do echo v1 && sleep 5; done']
    metadata:
      name: app-v1
      labels:
        app: myapp
```

This is deployed with `kubectl create -f deploy-v1.yaml`.

```
$ kubectl create -f deploy-v1.yaml
deployment "app-deploy" created
$ kubectl get all --selector='app=myapp'
NAME                             READY     STATUS    RESTARTS   AGE
po/app-deploy-3127290674-88b5l   1/1       Running   0          5m
po/app-deploy-3127290674-8k97c   1/1       Running   0          5m
po/app-deploy-3127290674-cpjg2   1/1       Running   0          5m

NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-deploy   3         3         3            3           5m

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-deploy-3127290674   3         3         3         5m
```

Great!

Some time passes and we have a robust new version of our application in it's own file `deploy-v2.yaml` which -- you guessed it -- will echo `v2` into the logs.

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: app-deploy
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: busybox:latest
        command: ['sh', '-c', 'while true; do echo v2 && sleep 5; done']
    metadata:
      name: app-v2
      labels:
        app: myapp
```

Now we will `kubectl apply` the changes to `app-deploy`. 

```
$ kubectl apply -f deploy-v2.yaml
deployment "app-deploy" configured
$ kubectl get all --selector='app=myapp'
NAME                            READY     STATUS    RESTARTS   AGE
po/app-deploy-623088328-16fnz   1/1       Running   0          2m
po/app-deploy-623088328-67d3k   1/1       Running   0          3m
po/app-deploy-623088328-t39d7   1/1       Running   0          2m

NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-deploy   3         3         3            3           9m

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-deploy-3127290674   0         0         0         9m
rs/app-deploy-623088328    3         3         3         3m
```

We have successfully applied an update to our deployment.

More time passes and we want to create a *third* version of our deployment, `deploy-v3.yaml`.

```yaml

```

```
$ kubectl apply -f deploy-v3.yaml
deployment "app-deploy" configured
$ kubectl get all --selector='app=myapp'
NAME                             READY     STATUS             RESTARTS   AGE
po/app-deploy-4136413792-mld31   1/1       Running            0          10m
po/app-deploy-4136413792-skz5b   1/1       Running            0          10m
po/app-deploy-733784683-dx0sr    0/1       ImagePullBackOff   0          56s
po/app-deploy-733784683-rpn9b    0/1       ImagePullBackOff   0          56s

NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-deploy   3         4         2            2           10m

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-deploy-3942754910   0         0         0         10m
rs/app-deploy-4136413792   2         2         2         10m
rs/app-deploy-733784683    2         2         0         56s
```

Oh no! We made the mistake of setting our container image to `busybox:newest` instead of `busybox:latest`. As we can see our old service and some of our old pods are still running; Kubernetes has transitioned from `deploy-v2` to `deploy-v3` gracefully by keeping the old containers and service around until the update succeeds (which it has not).

Now that we know `deploy-v3.yaml` is broken, we need to fix it. In the meantime we should `kubectl rollout undo`; this reverts our deployment to a previous (working) state.

```
$ kubectl rollout history
deployments "app-deploy"
REVISION	CHANGE-CAUSE
1		<none>
2		<none>
3		<none>
$ kubectl rollout undo deploy/app-deploy
deployment "app-deploy" rolled back
$ kubectl get all --selector='app=myapp'
NAME                             READY     STATUS    RESTARTS   AGE
po/app-deploy-4136413792-lnx9b   1/1       Running   0          15s
po/app-deploy-4136413792-mld31   1/1       Running   0          16m
po/app-deploy-4136413792-skz5b   1/1       Running   0          16m

NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/app-deploy   3         3         3            3           17m

NAME                       DESIRED   CURRENT   READY     AGE
rs/app-deploy-3942754910   0         0         0         17m
rs/app-deploy-4136413792   3         3         3         16m
rs/app-deploy-733784683    0         0         0         7m
```

As we can see all three of our `app-deploy` pods are running, the Replica Set is functioning correctly, and the Deployment is healthy.

### Some notes on updating Deployments:

- The `name` of a deployment must be the same when using the `apply` subcommand for *that* deployment to be udpated.
- In practice the `apply` acts more like applying a diff and less like replacing a configuration. This means that if you change the `name` of a container (for example) it will *add* that container to the deployment and not *replace* the existing container.
- When an update to a deployment is made the previous Replica Set is saved but is set to have `Replicas: 0 current / 0 desired`.

[k8s-deployments]: http://kubernetes.io/docs/user-guide/deployments/
[k8s-replication-controller]: http://kubernetes.io/docs/user-guide/replication-controller/
[k8s-replica-set]: http://kubernetes.io/docs/user-guide/replicasets/
[fleet-template-unit-files]: https://coreos.com/fleet/docs/latest/unit-files-and-scheduling.html#template-unit-files
