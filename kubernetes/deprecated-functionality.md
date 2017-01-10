# Deprecated functionality

Despite many functional similarities, some fleet features do not exist in Kubernetes. Thankfully there are usually workarounds for almost every use-case.

## Container Dependencies

Using systemd service dependencies fleet is able to outline dependencies. Containers can be started in a specific order and only *after* services they depend on have begun.

While this has been [discussed at length][pod-deps-discussion]. There are two workarounds for this in Kubernetes:

1. Grouping related containers in a Pod.
2. [Init containers][k8s-init-containers]

### Grouping containers in Pods

This is the most straight forward to approach the problem. Pods specs can contain multiple containers. By grouping related containers in one Pod then Kubernetes will co-locate them and monitor if all of the containers are functioning correctly.

[comment]: # (TODO: Include an example?)

### Init containers

[Init containers][k8s-init-containers] are containers run before a Pod starts up. They can be used to manage assets, wait for services, and perform general pre-pod setup. A pod is not scheduled until it's init-containers complete.

[comment]: # (TODO: Include an example?)

## Graceful Exit Command (ExecStop)

Fleet uses the systemd option [ExecStop][fleet-execstop] to instruct systemd how to stop a service gracefully. While this functionality does not exist in Kubernetes, the `ExecPreStop` does have an analogue in the Kubernetes world: `lifecycle.preStop`!

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

[fleet-execstop]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[prestop]: http://kubernetes.io/docs/user-guide/pods/#termination-of-pods
[lifecycle-hooks]: http://kubernetes.io/docs/user-guide/production-pods/#lifecycle-hooks-and-termination-notice
[pod-deps-discussion]: https://github.com/kubernetes/kubernetes/issues/2385
[k8s-init-containers]: http://kubernetes.io/docs/user-guide/pods/init-container/
