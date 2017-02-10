# Deprecated functionality

While fleet and Kubernetes are similar in functionality, some fleet features do not have direct equivalents in Kubernetes. Workarounds exist for many of these cases. Several of these features and workarounds are outlined below.

## Container Dependencies

Fleet uses systemd service dependencies to outline a limited dependency graph. When units are co-located, then containers may be specified to start in a specific order; only beginning a service after others it depends on have begun. This is not really a fleet feature but rather a systemd feature. It is limited by the design and features of systemd.

There are two workarounds for this in Kubernetes:

1. Grouping related containers in a Pod.
2. [Init containers][k8s-init-containers]

### Grouping containers in Pods

This is the most straightforward to approach the problem. Pods specs can contain multiple containers. By grouping related containers in one Pod, Kubernetes will co-locate them and monitor if all of the containers are running.

[comment]: # (TODO: Include an example?)

### Init containers

[Init containers][k8s-init-containers] are containers that run before a Pod starts up. They can be used to manage assets, wait for services, and perform general setup. A pod is not scheduled until it's init containers complete.

[comment]: # (TODO: Include an example?)

## Graceful Exit Command (ExecStop)

Fleet uses the systemd option [ExecStop][fleet-execstop] to instruct systemd how to stop a service gracefully. (The fleet ExecStop feature exhibits a [bug depending on how service termination is invoked][fleet-exec-issue].)

While this exact feature does not exist in Kubernetes, the `ExecPreStop` does have an analogue: `lifecycle.preStop`.

A Pod [lifecycle.preStop][lifecycle-hooks] directive specifies a command run before Kubernetes terminates an application with `SIGTERM`. This provides a mechanism to perform pre-termination actions to stop applications gracefully.

Here is an example of using `lifecycle.preStop`, inspired by the Kubernetes docs:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    lifecycle:
      preStop:
        exec:
          # SIGTERM triggers a quick exit; gracefully terminate instead
          command: ["/usr/sbin/nginx","-s","quit"]
```

[comment]: # (TODO: Think of a better example for preStop. Need a clearer demo.)

After a grace period, a running application in the pod will be killed via `SIGTERM`. The pod's `terminationGracePeriodSeconds` defaults to 30 seconds, but can be set to a longer period.

More information can be found in the [Kubernetes Pods user guide][prestop].

[fleet-exec-issue]: https://github.com/coreos/fleet/issues/1000
[fleet-execstop]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[k8s-init-containers]: http://kubernetes.io/docs/user-guide/pods/init-container/
[lifecycle-hooks]: http://kubernetes.io/docs/user-guide/production-pods/#lifecycle-hooks-and-termination-notice
[pod-deps-discussion]: https://github.com/kubernetes/kubernetes/issues/2385
[prestop]: http://kubernetes.io/docs/user-guide/pods/#termination-of-pods
