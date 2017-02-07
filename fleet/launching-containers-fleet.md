# Launching containers with fleet

**Fleet is no longer under active development, and receives only critical security fixes. After 2/1/2018, fleet will no longer be included in CoreOS Container Linux. New clusters should use [Kubernetes](CoreOS.com/kubernetes/docs/latest). Legacy fleet clusters should [run fleet in a container](CoreOS.com/fleet/docs/latest/launching-containers-fleet.html#running-fleet-with-ignition).**

`fleet` is a cluster manager that controls `systemd` at the cluster level. To run your services in the cluster, you must submit regular systemd units combined with a few [fleet-specific properties](https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md).

If you're not familiar with systemd units, check out our [Getting Started with systemd](../os/getting-started-with-systemd.md) guide.

This guide assumes you're running `fleetctl` locally from a Container Linux machine that's part of a Container Linux cluster. You can also [control your cluster remotely](https://github.com/coreos/fleet/blob/master/Documentation/using-the-client.md#get-up-and-running). All of the units referenced in this blog post are contained in the [unit-examples](https://github.com/coreos/unit-examples/tree/master/simple-fleet) repository. You can clone this onto your Container Linux box to make unit submission easier.

## Types of fleet units

Two types of units can be run in your cluster &mdash; standard and global units. Standard units are long-running processes that are scheduled onto a single machine. If that machine goes offline, the unit will be migrated onto a new machine and started.

Global units will be run on all machines in the cluster. These are ideal for common services like monitoring agents or components of higher-level orchestration systems like Kubernetes, Mesos or OpenStack. There are two fleetctl commands to view units in the cluster: `list-unit-files`, which shows the units that fleet knows about and whether or not they are global, and `list-units`, which shows the current state of units actively loaded into machines in the cluster. Here's an example cluster with 3 machines, running both types of units:

```sh
$ fleetctl list-unit-files
UNIT                   HASH     DSTATE    STATE     TMACHINE
global-unit.service    8ff68b9  launched  launched  3 of 3
standard-unit.service  7710e8a  launched  launched  148a18ff.../10.10.1.1
```

You can view all of the machines in the cluster by running `list-machines`:

```sh
$ fleetctl list-machines
MACHINE                                 IP          METADATA
148a18ff-6e95-4cd8-92da-c9de9bb90d5a    10.10.1.1   -
491586a6-508f-4583-a71d-bfc4d146e996    10.10.1.2   -
c9de9451-6a6f-1d80-b7e6-46e996bfc4d1    10.10.1.3   -
```

Now when looking at the status of units, we should expect to see 3 copies of global-unit.service - one running on each machine:

```sh
$ fleetctl list-units
UNIT                    MACHINE                  ACTIVE    SUB
global-unit.service     148a18ff.../10.10.1.1    active    running
global-unit.service     491586a6.../10.10.1.2    active    running
global-unit.service     c9de9451.../10.10.1.3    active    running
standard-unit.service   148a18ff.../10.10.1.1    active    running
```

## Run a container in the cluster

Running a single container is very easy. All you need to do is provide a regular unit file without an `[Install]` section. Let's run the same unit from the [Getting Started with systemd](../os/getting-started-with-systemd.md) guide. First save these contents as `myapp.service` on the Container Linux machine:

```ini
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill busybox1
ExecStartPre=-/usr/bin/docker rm busybox1
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name busybox1 busybox /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop busybox1
```

If you've been running docker commands manually, be sure you don't copy a `docker run` command that starts a container in detached mode (`-d`). Detached mode won't start the container as a child of the unit's pid. This will cause the unit to run for just a few seconds and then exit.

Run the start command to start up the container on the cluster:

```sh
$ fleetctl start myapp.service
```
The unit should have been scheduled to a machine in your cluster:

```sh
$ fleetctl list-units
UNIT              MACHINE                 ACTIVE    SUB
myapp.service     c9de9451.../10.10.1.3   active    running

```

You can view all of the machines in the cluster by running `list-machines`:

```sh
$ fleetctl list-machines
MACHINE                                 IP          METADATA
148a18ff-6e95-4cd8-92da-c9de9bb90d5a    10.10.1.1   -
491586a6-508f-4583-a71d-bfc4d146e996    10.10.1.2   -
c9de9451-6a6f-1d80-b7e6-46e996bfc4d1    10.10.1.3   -
```

## Run a high availability service

The main benefit of using Container Linux is to have your services run in a highly available manner. Let's walk through deploying a service that consists of two identical containers running the Apache web server. Afterwards, we'll walk through the failure of a machine and the steps fleet takes to relaunch our tasks on another machine.

First, let's write a unit file that we'll run two copies of. To do that, we'll use a template unit, named `apache@.service`. The template stays on disk and is used as a base to generate two instances, named `apache@1.service` and `apache@2.service`:

```ini
[Unit]
Description=My Apache Frontend
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill apache1
ExecStartPre=-/usr/bin/docker rm apache1
ExecStartPre=/usr/bin/docker pull coreos/apache
ExecStart=/usr/bin/docker run --rm --name apache1 -p 80:80 coreos/apache /usr/sbin/apache2ctl -D FOREGROUND
ExecStop=/usr/bin/docker stop apache1

[X-Fleet]
Conflicts=apache@*.service
```

The `Conflicts` attribute tells `fleet` that these two services can't be run on the same machine, giving us high availability. A full list of options for this section can be found in the [fleet units guide](https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md).

Let's start both units and verify that they're on two different machines:

```sh
$ fleetctl start apache@1
$ fleetctl start apache@2
$ fleetctl list-units
UNIT              MACHINE                 ACTIVE    SUB
myapp.service     c9de9451.../10.10.1.3   active    running
apache@1.service  491586a6.../10.10.1.2   active    running
apache@2.service  148a18ff.../10.10.1.1   active    running
```

As you can see, the Apache units are now running on two different machines in our cluster.

How do we route requests to these containers? The best strategy is to run a "sidekick" container that performs other duties that are related to our main container but shouldn't be directly built into that application. Examples of common sidekick containers are for service discovery and controlling external services such as cloud load balancers or DNS.

### Recovering from machine failure

Machines in your fleet cluster are constantly in communication with the rest of cluster and elect a leader to make scheduling decisions. The leader is responsible for parsing newly submitted/started units, finding a qualified machine to run them (via X-Fleet parameters), and then informing the machine(s) to start the unit.

When a machine fails to heartbeat back to the fleet leader, all units running on that machine are marked for rescheduling. During that process, qualified machines are found for each unit and they are started on the new machine. Units that can't be rescheduled will remain stopped until a qualified machine can be found. If the failed machine recovers, the fleet leader will tell it to cease operations of the old units, which have been rescheduled,  and then the machine will be available for new work.

You can test out this process by stopping fleet (`sudo systemctl stop fleet`) on one of the machines running our Apache unit. The fleet logs (`sudo journalctl -u fleet`) will provide more clarity on what's going on under the hood.

## Run a simple sidekick

The simplest sidekick example is for [service discovery](https://github.com/coreos/fleet/blob/master/Documentation/examples/service-discovery.md). This unit blindly announces that our container has been started. We'll run one of these for each Apache unit that's already running. Again, we'll use a template unit with two instances. Make a template unit called `apache-discovery@.service`.

```ini
[Unit]
Description=Announce Apache1
BindsTo=apache@%i.service
After=apache@%i.service

[Service]
ExecStart=/bin/sh -c "while true; do etcdctl set /services/website/apache@%i '{ \"host\": \"%H\", \"port\": 80, \"version\": \"52c7248a14\" }' --ttl 60;sleep 45;done"
ExecStop=/usr/bin/etcdctl rm /services/website/apache@%i

[X-Fleet]
MachineOf=apache@%i.service
```

This unit has a few interesting properties. First, it uses `BindsTo` to link the unit to our `apache@%i.service` unit. When the Apache unit is stopped, this unit will stop as well, causing it to be removed from our `/services/website` directory in `etcd`. A TTL of 60 seconds is also being used here to remove the unit from the directory if our machine suddenly died for some reason.

Second is `%i`, a variable built into systemd that represents the instance name of an instantiated unit (a unit launched from a template). This variable expands to any value after the `@` in the unit's name. In our case, it will expand to `1` (for `apache-discovery@1`) and `2` (for `apache-discovery@2`).

Third is `%H`, a variable built into systemd, that represents the hostname of the machine running this unit. Variable usage is covered in our [Getting Started with systemd](../os/getting-started-with-systemd.md#unit-variables) guide as well as in [systemd documentation](http://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers).

The fourth is a [fleet-specific property](https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md) called `MachineOf`. This property causes the unit to be placed onto the same machine that the corresponding apache service is running on (e.g., `apache-discovery@1.service` will be scheduled on the same machine as `apache@1.service`).

Let's verify that each unit was placed on to the same machine as the Apache service is bound to:

```sh
$ fleetctl start apache-discovery@1
$ fleetctl start apache-discovery@2
$ fleetctl list-units
UNIT                        MACHINE                 ACTIVE    SUB
myapp.service               c9de9451.../10.10.1.3   active    running
apache@1.service            491586a6.../10.10.1.2   active    running
apache@2.service            148a18ff.../10.10.1.1   active    running
apache-discovery@1.service  491586a6.../10.10.1.2   active    running
apache-discovery@2.service  148a18ff.../10.10.1.1   active    running
```

Now let's verify that the service discovery is working correctly:

```sh
$ etcdctl ls /services/ --recursive
/services/website
/services/website/apache@1
/services/website/apache@2
$ etcdctl get /services/website/apache@1
{ "host": "ip-10-182-139-116", "port": 80, "version": "52c7248a14" }
```

## Run an external service sidekick

If you're running in the cloud, many services have APIs that can be automated based on actions in the cluster. For example, you may update DNS records or add new containers to a cloud load balancer. Our [Example Deployment with fleet](https://github.com/coreos/fleet/blob/master/Documentation/examples/example-deployment.md#service-files) contains a pre-made presence container that updates an Amazon Elastic Load Balancer with new backends.

<iframe width="636" height="375" src="//www.youtube.com/embed/u91DnN-yaJ8?rel=0" frameborder="0" allowfullscreen></iframe>

## Run a global unit

As mentioned earlier, global units are useful for running a unit across all of the machines in your cluster. It doesn't differ very much from a regular unit other than a new `X-Fleet` parameter called `Global=true`. Here's an example unit from a [blog post to use Data Dog with Container Linux](https://www.datadoghq.com/blog/monitor-coreos-scale-datadog/). You'll need to set an etcd key `ddapikey` before this example will work &mdash; more details are in the post.

```ini
[Unit]
Description=Monitoring Service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill dd-agent
ExecStartPre=-/usr/bin/docker rm dd-agent
ExecStartPre=/usr/bin/docker pull datadog/docker-dd-agent
ExecStart=/usr/bin/bash -c \
"/usr/bin/docker run --privileged --name dd-agent -h `hostname` \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /proc/mounts:/host/proc/mounts:ro \
-v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
-e API_KEY=`etcdctl get /ddapikey` \
datadog/docker-dd-agent"

[X-Fleet]
Global=true
```

If we start this unit, it should be running on all 3 of our machines:

```sh
$ fleetctl start datadog.service
$ fleetctl list-units
UNIT                        MACHINE                 ACTIVE    SUB
myapp.service               c9de9451.../10.10.1.3   active    running
apache@1.service            491586a6.../10.10.1.2   active    running
apache@2.service            148a18ff.../10.10.1.1   active    running
apache-discovery@1.service  491586a6.../10.10.1.2   active    running
apache-discovery@2.service  148a18ff.../10.10.1.1   active    running
datadog.service             148a18ff.../10.10.1.1   active    running
datadog.service             491586a6.../10.10.1.2   active    running
datadog.service             c9de9451.../10.10.1.3   active    running
```

Global units can deployed to a subset of matching machines with the `MachineMetadata` parameter, which is explained in the next section.

## Schedule based on machine metadata

Applications with complex and specific requirements can target a subset of the cluster for scheduling via machine metadata. Powerful deployment topologies can be achieved &mdash; schedule units based on the machine's region, rack location, disk speed or anything else you can think of.

Metadata can be provided via [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md#coreos) or a [config file](https://github.com/coreos/fleet/blob/master/Documentation/deployment-and-configuration.md). Here's an example config file:

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
MachineMetadata=disk=ssd
```

If you wanted to ensure very high availability you could have 3 unit files that must be scheduled across providers but in the same region:

```ini
[X-Fleet]
Conflicts=webapp*
MachineMetadata=provider=rackspace
MachineMetadata=platform=metal
MachineMetadata=region=east
```

```ini
[X-Fleet]
Conflicts=webapp*
MachineMetadata=provider=rackspace
MachineMetadata=platform=cloud
MachineMetadata=region=east
```

```ini
[X-Fleet]
Conflicts=webapp*
MachineMetadata=provider=amazon
MachineMetadata=platform=cloud
MachineMetadata=region=east
```

## Running fleet via Ignition

On Container Linux, only fleet 0.11.x is available under /usr/bin. That one might be obsolete for users who want to try out more recent versions. In that case, users should define their own custom Ignition configuration to be able to run any version of fleet as they want. For example:

```json
{
  "ignition": { "version": "2.0.0" },
  "storage": {
    "files": [{
      "filesystem": "root",
      "path": "/opt/bin/fleet-wrapper",
      "mode": 493,
      "contents": {
        "source": "https://raw.githubusercontent.com/coreos/fleet/master/scripts/fleet-wrapper"
      }
    }]
  },
  "systemd": {
    "units": [
      {
        "name": "fleet.service",
        "enable": true,
        "contents": "[Unit]\nAfter=etcd.service etcd2.service etcd-member.service\nWants=network.target fleet.socket\nRequires=etcd2.service\n\n[Service]\nType=notify\nRestart=always\nRestartSec=10s\nLimitNOFILE=40000\nTimeoutStartSec=0\nExecStartPre=/usr/bin/mkdir --parents /etc/fleet /run/dbus /run/fleet/units\nExecStartPre=/usr/bin/rkt trust --prefix \"quay.io/coreos/fleet\" --skip-fingerprint-review\nExecStart=/opt/bin/fleet-wrapper\n\n[Install]\nWantedBy=multi-user.target"
      },
      {
        "name": "fleet.socket",
        "enable": true,
        "contents": "[Unit]\nDescription=Fleet API Socket\nPartOf=fleet.service\n\n[Socket]\nListenStream=/var/run/fleet.sock\nSocketMode=0660\nSocketUser=fleet\nSocketGroup=fleet"
      }
    ]
  }
}
```

#### More information

<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/examples/example-deployment.md">Example Deployment with fleet</a>
<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md">fleet Unit Specifications</a>
<a class="btn btn-default" href="https://github.com/coreos/fleet/blob/master/Documentation/deployment-and-configuration.md">fleet Configuration</a>
