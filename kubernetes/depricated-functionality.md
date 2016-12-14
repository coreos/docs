# Deprecated functionality

Despite many functional similarities, some fleet features don't exist in Kubernetes.


## Socket Activation

[Socket Activation Docs][fleet-socket-activation]


## Container Dependencies

Kubernetes groups related containers in resource-sharing *pods*, rather than having systemd dependencies enforce a graph of interservice relationships.

- Fleet container dependencies defined in unit files, enforced grouping of services. Order and `requires`, sequence timing.
- k8s sidekicks for this kind of work?
- k8s pod structure for comm dependencies

## ExecStop

[ExecStop Docs][fleet-execstop]

Fleet uses this systemd option to run a command to stop a service gracefully, this concept does not exist in Kubernetes.


[fleet-container-dependencies]:
[fleet-execstop]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[fleet-socket-activation]: https://coreos.com/fleet/docs/latest/deployment-and-configuration.html#api
