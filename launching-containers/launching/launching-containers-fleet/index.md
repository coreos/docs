---
layout: docs
slug: guides
title: Launching Containers with fleet
category: launching_containers
sub_category: launching
weight: 2
---

# Launching Containers with fleet

`fleet` is a cluster manager that controls `systemd` at the cluster level. To run your services in the cluster, you must submit regular systemd units combined with a few fleet-specific properties.

If you're not familiar with systemd units, check out our [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) guide.

This guide assumes you're running `fleetctl` locally from a CoreOS machine that's part of a CoreOS cluster. You can also [control your cluster remotely]({{site.url}}/docs/launching-containers/launching/fleet-using-the-client/#get-up-and-running).

## Run a Container in the Cluster

Running a single container is very easy. All you need to do is provide a regular unit file without an `[Install]` section. Let's run the same unit from the [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) guide. First save these contents as `myapp.service` on the CoreOS machine:

```
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
```

Run the start command to start up the container on the cluster:

```
$ fleetctl start myapp.service
```

Now list all of the units in the cluster to see the current status. The unit should have been scheduled to a machine in your cluster:

```
$ fleetctl list-units
UNIT             LOAD    ACTIVE  SUB      DESC    MACHINE
myapp.service  	 loaded  active  running  MyApp   c9de9451.../10.10.1.3
```

You can view all of the machines in the cluster by running `list-machines`:

```
$ fleetctl list-machines
MACHINE                                 IP          METADATA
148a18ff-6e95-4cd8-92da-c9de9bb90d5a    10.10.1.1   -
491586a6-508f-4583-a71d-bfc4d146e996    10.10.1.2   -
c9de9451-6a6f-1d80-b7e6-46e996bfc4d1    10.10.1.3   -
```

## Run a High Availability Service

The main benefit of using CoreOS is to have your services run in a highly available manner. Let's walk through deploying a service that consists of two identical containers running the Apache web server.

First, let's write a unit file that we'll run two copies of, named `apache.1.service` and `apache.2.service`:

```
[Unit]
Description=My Apache Frontend
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run --name apache -p 80:80 coreos/apache /usr/sbin/apache2ctl -D FOREGROUND
ExecStop=/usr/bin/docker stop apache

[X-Fleet]
X-Conflicts=apache.*.service
```

The `X-Conflicts` attribute tells `fleet` that these two services can't be run on the same machine, giving us high availability. Let's start both units and verify that they're on two different machines:

```
$ fleetctl start apache.*
$ fleetctl list-units
UNIT               LOAD    ACTIVE  SUB      DESC    			MACHINE
myapp.service  	   loaded  active  running  MyApp               c9de9451.../10.10.1.3
apache.1.service   loaded  active  running  My Apache Frontend  491586a6.../10.10.1.2
apache.2.service   loaded  active  running  My Apache Frontend  148a18ff.../10.10.1.1
```

As you can see, the Apache units are now running on two different machines in our cluster.

How do we route requests to these containers? The best strategy is to run a "sidekick" container that performs other duties that are related to our main container but shouldn't be directly built into that application. Examples of common sidekick containers are for service discovery and controlling external services such as cloud load balancers.

## Run a Simple Sidekick

The simplest sidekick example is for [service discovery](https://github.com/coreos/fleet/blob/master/Documentation/service-discovery.md). This unit blindly announces that our container has been started. We'll run one of these for each Apache unit that's already running. Make two copies of the unit called `apache-discovery.1.service` and `apache-discovery.2.service`. Be sure to change all instances of `apache.1.service` to `apache.2.service` when you create the second unit.

```
[Unit]
Description=Announce Apache1
BindsTo=apache.1.service

[Service]
ExecStart=/bin/sh -c "while true; do etcdctl set /services/website/apache1 '{ \"host\": \"%H\", \"port\": 80, \"version\": \"52c7248a14\" }' --ttl 60;sleep 45;done"
ExecStop=/usr/bin/etcdctl rm /services/website/apache1

[X-Fleet]
X-ConditionMachineOf=apache.1.service
```

This unit has a few interesting properties. First, it uses `BindsTo` to link the unit to our `apache.1.service` unit. When the Apache unit is stopped, this unit will stop as well, causing it to be removed from our `/services/website` directory in `etcd`. A TTL of 60 seconds is also being used here to remove the unit from the directory if our machine suddenly died for some reason.

Second is `%H`, a variable built into systemd, that represents the hostname of the machine running this unit. Variable usage is coverd in our [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd/#unit-variables) guide as well as in [systemd documentation](http://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers).

The third is a fleet-specific property called `X-ConditionMachineOf`. This property causes the unit to be placed onto the same machine that `apache.1.service` is running on.

Let's verify that each unit was placed on to the same machine as the Apache service is is bound to:

```
$ fleetctl start apache-discovery.1.service
$ fleetctl list-units
UNIT              			LOAD    ACTIVE  SUB      DESC    			 MACHINE
myapp.service  	  			loaded  active  running  MyApp               c9de9451.../10.10.1.3
apache.1.service 			loaded  active  running  My Apache Frontend  491586a6.../10.10.1.2
apache.2.service  			loaded  active  running  My Apache Frontend  148a18ff.../10.10.1.1
apache-discovery.1.service  loaded  active  running  Announce Apache1    491586a6.../10.10.1.2
apache-discovery.2.service  loaded  active  running  Announce Apache2    148a18ff.../10.10.1.1
```

Now let's verify that the service discovery is working correctly:

```
$ etcdctl ls /services/ --recursive
/services/website
/services/website/apache1
/services/website/apache2
$ etcdctl get /services/website/apache1
{ "host": "ip-10-182-139-116", "port": 80, "version": "52c7248a14" }
```

## Run an External Service Sidekick

If you're running in the cloud, many services have APIs that can be automated based on actions in the cluster. For example, you may update DNS records or add new containers to a cloud load balancer. Our [Example Deployment with fleet]({{site.url}}/docs/launching-containers/launching/fleet-example-deployment/#service-files) contains a pre-made presence container that updates an Amazon Elastic Load Balancer with new backends.

<iframe width="636" height="375" src="//www.youtube.com/embed/u91DnN-yaJ8?rel=0" frameborder="0" allowfullscreen></iframe>

#### More Information
<a class="btn btn-default" href="{{site.url}}/docs/launching-containers/launching/fleet-example-deployment">Example Deployment with fleet</a>
<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/unit-files.md">fleet Unit Specifications</a>
<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/configuration.md">fleet Configuration</a>