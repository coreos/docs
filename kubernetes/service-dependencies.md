# Service startup depencies

Service startup often demands an order of operations because of functional dependencies. For instance your application depends on a caching system, without the cacheing container the entire service will fall on it's face. The simplest solution to this problem is to create a serivce dependency in which one container only starts after another has successfully begun running.


# fleet: ExecPre

[comment]: # (In the world of fleet: ExecPre)


# Kubernetes: init containers

[comment]: # (In the world of kubernetes: init containers)


[exec-pre]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[init-containers]: http://kubernetes.io/docs/user-guide/production-pods/#handling-initialization
