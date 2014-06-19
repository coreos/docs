---
layout: docs
slug: guides
title: Launching Containers with fleet
category: launching_containers
sub_category: launching
weight: 2
---

# Launching Containers with fleet

`fleet` is a cluster manager that controls `systemd` at the cluster level. To run your services in the cluster, you must submit regular systemd units combined with a few [fleet-specific properties]({{site.url}}/docs/launching-containers/launching/fleet-unit-files/).

If you're not familiar with systemd units, check out our [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) guide. 

This guide assumes you're running `fleetctl` locally from a CoreOS machine that's part of a CoreOS cluster. You can also [control your cluster remotely]({{site.url}}/docs/launching-containers/launching/fleet-using-the-client/#get-up-and-running). All of the units referenced in this blog post are contained in the [unit-examples](https://github.com/coreos/unit-examples/tree/master/simple-fleet) repository. You can clone this onto your CoreOS box to make unit submission easier.

## Run a Container in the Cluster

Running a single container is very easy. All you need to do is provide a regular unit file without an `[Install]` section. Let's run the same unit from the [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) guide. First save these contents as `myapp.service` on the CoreOS machine:

```ini
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
```

Run the start command to start up the container on the cluster:

```sh
$ fleetctl start myapp.service
```

Now list all of the units in the cluster to see the current status. The unit should have been scheduled to a machine in your cluster:

```sh
$ fleetctl list-units
UNIT             LOAD    ACTIVE  SUB      DESC    MACHINE
myapp.service  	 loaded  active  running  MyApp   c9de9451.../10.10.1.3
```

You can view all of the machines in the cluster by running `list-machines`:

```sh
$ fleetctl list-machines
MACHINE                                 IP          METADATA
148a18ff-6e95-4cd8-92da-c9de9bb90d5a    10.10.1.1   -
491586a6-508f-4583-a71d-bfc4d146e996    10.10.1.2   -
c9de9451-6a6f-1d80-b7e6-46e996bfc4d1    10.10.1.3   -
```

## Run a High Availability Service

The main benefit of using CoreOS is to have your services run in a highly available manner. Let's walk through deploying a service that consists of two identical containers running the Apache web server.

First, let's write a unit file that we'll run two copies of, named `apache.1.service` and `apache.2.service`:

```ini
[Unit]
Description=My Apache Frontend
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker run -rm -name apache -p 80:80 coreos/apache /usr/sbin/apache2ctl -D FOREGROUND
ExecStop=/usr/bin/docker rm -f apache

[X-Fleet]
X-Conflicts=apache.*.service
```

The `X-Conflicts` attribute tells `fleet` that these two services can't be run on the same machine, giving us high availability. A full list of options for this section can be found in the [fleet units guide]({{site.url}}/docs/launching-containers/launching/fleet-unit-files/).

Let's start both units and verify that they're on two different machines:

```sh
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

The simplest sidekick example is for [service discovery](https://github.com/coreos/fleet/blob/master/Documentation/service-discovery.md). This unit blindly announces that our container has been started. We'll run one of these for each Apache unit that's already running. Make two copies of the unit called `apache-discovery.1.service` and `apache-discovery.2.service`. Be sure to change all instances of `apache.1.service` to `apache.2.service` and `apache1` to `apache2` when you create the second unit.

```ini
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

Second is `%H`, a variable built into systemd, that represents the hostname of the machine running this unit. Variable usage is covered in our [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd/#unit-variables) guide as well as in [systemd documentation](http://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers).

The third is a [fleet-specific property]({{site.url}}/docs/launching-containers/launching/fleet-unit-files/) called `X-ConditionMachineOf`. This property causes the unit to be placed onto the same machine that `apache.1.service` is running on.

Let's verify that each unit was placed on to the same machine as the Apache service is is bound to:

```sh
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

```sh
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

## Schedule Based on Machine Metadata

Applications with complex and specific requirements can target a subset of the cluster for scheduling via machine metadata. Powerful deployment topologies can be achieved &mdash; schedule units based on the machine's region, rack location, disk speed or anything else you can think of.

Metadata can be provided via [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/#coreos) or a [config file](https://github.com/coreos/fleet/blob/master/Documentation/configuration.md). Here's an example config file:

```ini
# Comma-delimited key/value pairs that are published to the fleet registry.
# This data can be referenced in unit files to affect scheduling decisions.
# An example could look like: metadata="region=us-west,az=us-west-1"
metadata="platform=metal,provider=rackspace,region=east,disk=ssd"
```

Metadata can be viewed in the machine list when configured:

```sh
$ fleetctl list-machines
MACHINE     IP            METADATA
29db5063... 172.17.8.101  disk=ssd,platform=metal,provider=rackspace,region=east
ebb97ff7... 172.17.8.102  disk=ssd,platform=cloud,provider=rackspace,region=east
f823e019... 172.17.8.103  disk=ssd,platform=cloud,provider=amazon,region=east
```

The unit file for a service that does a lot of disk I/O but doesn't care where it runs could look like:

```ini
[X-Fleet]
X-ConditionMachineMetadata=disk=ssd
```

If you wanted to ensure very high availability you could have 3 unit files that must be scheduled across providers but in the same region:

```ini
[X-Fleet]
X-Conflicts=webapp*
X-ConditionMachineMetadata=provider=rackspace
X-ConditionMachineMetadata=platform=metal
X-ConditionMachineMetadata=region=east
```

```ini
[X-Fleet]
X-Conflicts=webapp*
X-ConditionMachineMetadata=provider=rackspace
X-ConditionMachineMetadata=platform=cloud
X-ConditionMachineMetadata=region=east
```

```ini
[X-Fleet]
X-Conflicts=webapp*
X-ConditionMachineMetadata=provider=amazon
X-ConditionMachineMetadata=platform=cloud
X-ConditionMachineMetadata=region=east
```

#### More Information
<a class="btn btn-default" href="{{site.url}}/docs/launching-containers/launching/fleet-example-deployment">Example Deployment with fleet</a>
<a class="btn btn-default" href="{{site.url}}/docs/launching-containers/launching/fleet-unit-files/">fleet Unit Specifications</a>
<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/configuration.md">fleet Configuration</a>
