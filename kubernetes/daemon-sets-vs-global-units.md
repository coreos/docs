# Kubernets Daemon Sets vs fleet Global units

Running a container on all nodes is a common task. Aggregating service logs, collecting node metrics, or running a networked storage cluster all require a container to be replicated across all nodes. In the world of fleet this is done with a [Global unit][global-units] and in the world of Kubernetes this is done with a [Daemon Set][daemon-sets].

[comment]: # (DaemonSets and how they differ from fleet Global unit files)

## Global units


## Daemon Sets


[daemon-sets]: http://kubernetes.io/docs/admin/daemons/
[global-units]: https://coreos.com/fleet/docs/latest/unit-files-and-scheduling.html#systemd-specifiers
