# Container replication in Kubernetes vs fleet

[comment]: # (ReplicaSets and how they differ from fleet template unit files)

[comment]: # (Introduction about the tools used to replicate a service in fleet vs k8s)

## Tooling Breakdown

| Task                          | Kubernetes solution                                   | Fleet solution                                            |
|:-----------------------------:|:-----------------------------------------------------:|:---------------------------------------------------------:|
| Defining a replicated service | [Deployments][k8s-deployments]                        | [systemd template unit files][fleet-template-unit-files]  |
|                               | [Replication Controllers][k8s-replication-controller] |                                                           |
|                               | [Replica Sets][k8s-replica-set]                       |                                                           |

## Fleet Deployments

hello@.service:

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

```
core@core-01 ~ $ fleetctl start hello@1
Unit hello@1.service inactive
Unit hello@1.service launched on 370aa586.../172.17.8.102
core@core-01 ~ $ fleetctl start hello@2
Unit hello@2.service inactive
Unit hello@2.service launched on a7abd52c.../172.17.8.101
core@core-01 ~ $ fleetctl start hello@3
Unit hello@3.service inactive
Unit hello@3.service launched on ff3fba16.../172.17.8.103
core@core-01 ~ $ fleetctl list-units
UNIT        MACHINE             ACTIVE  SUB
hello@1.service 370aa586.../172.17.8.102    active  running
hello@2.service a7abd52c.../172.17.8.101    active  running
hello@3.service ff3fba16.../172.17.8.103    active  running
```

## Kubernetes Deployments

Kubernetes deployments are used to declaratively describe the state of a resource.

From the kubernetes docs:

> A typical use case is:
>
> * Create a Deployment to bring up a Replica Set and Pods.
> * Check the status of a Deployment to see if it succeeds or not.
> * Later, update that Deployment to recreate the Pods (for example, to use a new image).
> * Rollback to an earlier Deployment revision if the current Deployment isn’t stable.
> * Pause and resume a Deployment.

This is in contrast with how fleet attacks the problem with systemd template unit files.

## Kubernetes Replication Controllers and Replica Sets

Kubernetes [Replication Controllers][k8s-replication-controller] and [Replica Sets][k8s-replica-set]

[k8s-deployments]: http://kubernetes.io/docs/user-guide/deployments/
[k8s-replication-controller]: http://kubernetes.io/docs/user-guide/replication-controller/
[k8s-replica-set]: http://kubernetes.io/docs/user-guide/replicasets/
[fleet-template-unit-files]: https://coreos.com/fleet/docs/latest/unit-files-and-scheduling.html#template-unit-files
