# Depricated functionality

Despite their many functional similarities, some features just don't exist in in Kubernetes like they did in the fleet.


## Socket Activation

[Socket Activation Docs][fleet-socket-activation]


## Container Dependencies

Kubernetes does not have this concept. Users trying to achieve this functionality should depend on retry-loops and monitoring solutions.


## ExecStop

[ExecStop Docs][fleet-execstop]

Fleet uses this systemd option to run a command to stop a service gracefully, this concept does not exist in Kubernetes.


[fleet-container-dependencies]:
[fleet-execstop]: https://coreos.com/fleet/docs/latest/launching-containers-fleet.html#run-a-container-in-the-cluster
[fleet-socket-activation]: https://coreos.com/fleet/docs/latest/deployment-and-configuration.html#api
