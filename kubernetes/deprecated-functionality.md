# Deprecated functionality

While fleet and Kubernetes are largely similar in functionality, some specific fleet features do not have direct equivalents in Kubernetes.Fortunately, workarounds exist for almost every use-case. Several of these features and workarounds are outlined below.

## Container Dependencies

Fleet uses systemd service dependencies to outline a *limited* dependency graph. When units are co-located then containers may be specified to start in a specific order; only beginning a service *after* others it depends on have begun. This is not really a fleet feature but rather a systemd feature; it is limited by the design and feature-set of systemd

While this has been [discussed at length in the Kubernetes community][pod-deps-discussion] it has not been implemented in Kubernetes as of early 2017. There are two workarounds for this in Kubernetes:

1. Grouping related containers in a Pod.
2. [Init containers][k8s-init-containers]

### Grouping containers in Pods

This is the most straight forward to approach the problem. Pods specs can contain multiple containers. By grouping related containers in one Pod then Kubernetes will co-locate them and monitor if all of the containers are functioning correctly.

[comment]: # (TODO: Include an example?)

### Init containers

[Init containers][k8s-init-containers] are containers run before a Pod starts up. They can be used to manage assets, wait for services, and perform general pre-pod setup. A pod is not scheduled until it's init-containers complete.

[comment]: # (TODO: Include an example?)

## Graceful Exit Command (ExecStop)

Fleet uses the systemd option [ExecStop][fleet-execstop] to instruct systemd how to stop a service gracefully. **Note** that this feature has worked in fleet in the past, but [has proven to be problematic in practice][fleet-exec-issue].

While this functionality does not exist in Kubernetes, the `ExecPreStop` does have an analogue in the Kubernetes world: `lifecycle.preStop`!

A Pod [lifecycle.preStop][lifecycle-hooks] directive specifies a command run **before** Kubernetes terminates an application with `SIGTERM`. This achieves a similar result of gracefully stopping a container.

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

More information can be found at the [Kubernetes Pods user guide][prestop]

**Note:** The `preStop` directive is not a replacement for ExecStop. After a grace-period the container will still be killed via `SIGTERM`.

[fleet-exec-issue]: https://github.com/coreos/fleet/issues/1000
[fleet-execstop]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[k8s-init-containers]: http://kubernetes.io/docs/user-guide/pods/init-container/
[lifecycle-hooks]: http://kubernetes.io/docs/user-guide/production-pods/#lifecycle-hooks-and-termination-notice
[pod-deps-discussion]: https://github.com/kubernetes/kubernetes/issues/2385
[prestop]: http://kubernetes.io/docs/user-guide/pods/#termination-of-pods
