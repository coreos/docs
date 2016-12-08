# Affinity and anti-affinity

For a variety of reasons a service or container should only run on a specific type of hardware. Maybe one machine has faster disk speeds, another is running a conflicting application, and yet another is part of your bare-metal cluster. Each of these would be a good reason to run an application *here* instead of *there*, and being able to control *where* an application gets run can make all of the difference.

In fleet dictating where a container gets run is called [Affinity and Anti-Affinity][fleet-affinity]. In Kubernetes it is called the [nodeSelector][k8s-node-selection].

[comment]: # (nodeSelector and how it differs from fleet affinity/anti-affinity)

## Affinity and anti-affinity in fleet


## nodeSelector in Kubernetes

[k8s-node-selection]: http://kubernetes.io/docs/user-guide/node-selection/
[fleet-affinity]: https://coreos.com/blog/cluster-level-container-orchestration.html
