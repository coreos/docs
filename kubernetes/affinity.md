# Affinity and anti-affinity

For a variety of reasons a service or container should only run on a specific type of hardware. Maybe one machine has faster disk speeds, another is running a conflicting application, and yet another is part of your bare-metal cluster. Each of these would be a good reason to run an application *here* instead of *there*, and being able to control *where* an application gets run can make all of the difference.

In fleet dictating where a container gets run is called [Affinity and Anti-Affinity][fleet-affinity]. In Kubernetes this is called the [nodeSelector][k8s-node-selector] and [nodeAffinity/podAffinity][k8s-node-affinity] fields under PodSpec.

[comment]: # (nodeSelector and how it differs from fleet affinity/anti-affinity)

## Affinity in fleet

In the world of fleet, affinity and anti-affinity are achieved through [fleet-specific options in systemd unit-files][fleet-affinity]. These options include:

* `MachineID`: Run a unit on a specific host.
* `MachineOf`: Run a unit on the same host as another unit.
* `MachineMetadata`: Run on a host matching some arbitrary metadata defined in `fleet.conf`.
* `Conflicts`: Prevent a unit from running on the same node as some other unit.
* `Global`: Runs a unit on every node.
* `Replaces`: Run a unit in place of another unit.

These are described [in greater depth at the fleet documentation][fleet-specific-options].

These options allow one to specify with arbitrary granularly how, where, and when to schedule a unit on a fleet cluster.

## Affinity in Kubernetes

Kubernetes implements node affinity with the `nodeSelector` and `nodeAffinity` fields in PodSpec. These fields use both [pre-populated metadata][k8s-affinity-labels] or [user-defined metadata][k8s-user-node-labels].

### User-defined metadata:

These user-defined labels are set like so:

```
$ kubectl label nodes some-k8s-node.internal.hostename.ext key=value
```

And they can be retrieved like so:

```
$ kubectl get nodes --show-labels
NAME                                       STATUS                     AGE       LABELS
some-k8s-node.internal.hostname.ext        Ready                      8m        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=instance-type,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=some-us-region-2,failure-domain.beta.kubernetes.io/zone=some-us-region-2c,kubernetes.io/hostname=ip-10-0-0-101.some-us-region-2.internal,key=value
...
```

### `nodeSelector`

`nodeSelector` is the most basic way to set node affinity in Kubernetes. Given a set of `key: value` pair of requirements, a pod can be scheduled to run (or not run) on certain nodes.

The general form of this node selection looks like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    key1: value1
    key2: value2
```

#### `nodeSelector` Example

Let's say we're running a Kubernetes cluster on AWS and we want to run an Nginx pod on `m3.medium` instance. We also want a different `httpd` pod to only run in the `us-west-2` region and only on nodes with the `hello` key set to `world`. Here's how that `mypods.yaml` would look:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    beta.kubernetes.io/instance-type: m3.medium
    hello: world
---
apiVersion: v1
kind: Pod
metadata:
  name: httpd
  labels:
    env: test
spec:
  containers:
  - name: httpd
    image: httpd
  nodeSelector:
    failure-domain.beta.kubernetes.io/region: us-west-2
```

We create the pods just like usual:

```
$ kubectl create -f mypods.yaml 
pod "nginx" created
pod "wordpress" created
```

After a while we can see that the `httpd` pod has been created, but the `nginx` is still `pending`.

```
$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
httpd     1/1       Running   0          1m
nginx     0/1       Pending   0          1m
```

This is because our worker nodes don't meet one of the `nginx` pod requirements; neither have the `hello` key set to `world`!

```
$ kubectl get nodes --show-labels
NAME                                       STATUS                     AGE       LABELS
ip-10-0-0-187.us-west-2.compute.internal   Ready                      47m       beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=m3.medium,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=us-west-2,failure-domain.beta.kubernetes.io/zone=us-west-2c,key=value,kubernetes.io/hostname=ip-10-0-0-187.us-west-2.compute.internal
ip-10-0-0-188.us-west-2.compute.internal   Ready                      47m       beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=m3.medium,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=us-west-2,failure-domain.beta.kubernetes.io/zone=us-west-2c,kubernetes.io/hostname=ip-10-0-0-188.us-west-2.compute.internal
ip-10-0-0-50.us-west-2.compute.internal    Ready,SchedulingDisabled   47m       beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=m3.medium,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=us-west-2,failure-domain.beta.kubernetes.io/zone=us-west-2c,kubernetes.io/hostname=ip-10-0-0-50.us-west-2.compute.internal
```

If we add the `hello=world` key to one of our nodes, the `nginx` pod will get scheduled to that node.
Once we have the `hello` key set to `world`, the `nginx` pod will have a node to be assigned to and it will automatically start running.

```
$ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
httpd     1/1       Running   0          1m
nginx     0/1       Pending   0          1m
$ kubectl label node \
    ip-10-0-0-187.us-west-2.compute.internal \
    hello=world
node "ip-10-0-0-187.us-west-2.compute.internal" labeled
$ kubectl get pods -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP          NODE
httpd     1/1       Running   0          9m        10.2.26.5   ip-10-0-0-187.us-west-2.compute.internal
nginx     1/1       Running   0          9m        10.2.26.6   ip-10-0-0-187.us-west-2.compute.internal
```

Keep in mind: **when a node label changes, pods are not moved**. We can demonstrate this by changing the `hello` key on `ip-10-0-0-187.us-west-2.compute.internal` to `not-world`, and then add the `hello:world` lable to our other worker node to see what happens:

```
$ kubectl label nodes --overwrite ip-10-0-0-187.us-west-2.compute.internal hello=not-world
node "ip-10-0-0-187.us-west-2.compute.internal" labeled
$ kubectl label nodes ip-10-0-0-188.us-west-2.compute.internal hello=world
node "ip-10-0-0-188.us-west-2.compute.internal" labeled
$ kubectl get nodes --show-labels
NAME                                       STATUS                     AGE       LABELS
ip-10-0-0-187.us-west-2.compute.internal   Ready                      1h        [...],hello=not-world,[...]
ip-10-0-0-188.us-west-2.compute.internal   Ready                      1h        [...],hello=world,[...]
$ kubectl get pods -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP          NODE
httpd     1/1       Running   0          15m       10.2.26.5   ip-10-0-0-187.us-west-2.compute.internal
nginx     1/1       Running   0          15m       10.2.26.6   ip-10-0-0-187.us-west-2.compute.internal
```

As you can see, the both pods keep running on the same host, even though the `httpd` pod should have moved. Further httpd pods will be assigned to the second node.

### `affinity`

Kubernetes also has a more nuanced way of setting affinity called [`nodeAffinity` and `podAffinity`][k8s-node-affinity]. These are fields in under `Pod` metadata and take automatic or user-defined metadata to dictate where to schedule pods. `affinity` differs from `nodeSelector` in the following ways:

- Schedule a pod based on which other pods are or are not running on a node.
- *Request* without *requiring* that a pod be run on a node.
- Specify a *set* of allowable values instead of a *single* value requirement.

Affinity selector                                      | Requirements met | Requirements not met | Requirements lost
------------------------------------------------------ | ---------------- | -------------------- | ------------------
`requiredDuringSchedulingIgnoredDuringExecution`  | Runs             | Fails                | Keeps Running
`preferredDuringSchedulingIgnoredDuringExecution` | Runs             | Runs                 | Keeps Running
(un-implemented) `requiredDuringSchedulingRequiredDuringExecution` | Runs             | Fails                | Fails

In addition to affinity/anti-affinity for specific nodes `nodeAffinity`

#### `nodeAffinity` example

Lets take the above example of deploying a `nginx` and a `httpd` pod, except we have a more complicated set of requirements:

- `nginx` cannot run on the same node as `httpd`
- `httpd` *should* run on a node with the `x-web:yes` label, but *can* run anywhere.
- `nginx` *must* run on a node with `y-web:yes` label and should fail if not.

```yaml
TODO: Debug this example
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    nginx: yes
  annotations:
    scheduler.alpha.kubernetes.io/affinity: >
      {
        "nodeAffinity": {
          "requiredDuringSchedulingIgnoredDuringExecution": [
            {
              "labelSelector": {
                "matchExpressions": [
                  {
                    "key": "x-web",
                    "operator": "In",
                    "values": ["yes", "true"]
                  }
                ]
              }
            }
          ]
         },
         "podAntiAffinity": {
           "requiredDuringSchedulingIgnoredDuringExecution": [
             {
               "labelSelector": {
                 "matchExpressions": [
                   {
                     "key": "httpd",
                     "operator": "Exists"
                     "values": ["yes", "true"]
                   }
                 ]
               }
             }
           ]
         }
      }
spec:
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: httpd
  labels:
    nginx: yes
  annotations:
    scheduler.alpha.kubernetes.io/affinity: >
      {
        "nodeAffinity": {
          "preferredDuringSchedulingIgnoredDuringExecution": [
            {
              "labelSelector": {
                "matchExpressions": [
                  {
                    "key": "y-web",
                    "operator": "In",
                    "values": ["yes", "true"]
                  }
                ]
              }
            }
          ]
        }
      }
spec:
  containers:
  - name: httpd
    image: httpd
```

`nodeAffinity` and `podAffinity` will *eventually* replace `nodeSelector`. For now `nodeAffinty` does everything `nodeSelector` does **and more**.

[k8s-node-affinity]: http://kubernetes.io/docs/user-guide/node-selection/#alpha-features-affinity-and-anti-affinity
[k8s-node-selector]: http://kubernetes.io/docs/user-guide/node-selection/
[k8s-affinity-labels]: http://kubernetes.io/docs/user-guide/node-selection/#interlude-built-in-node-labels
[fleet-affinity]: https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md#fleet-specific-options 
[fleet-specific-options]: https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md#unit-scheduling
[k8s-user-node-labels]: http://kubernetes.io/docs/user-guide/node-selection/#step-one-attach-label-to-the-node
