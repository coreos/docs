# CoreOS cluster discovery

## Overview

CoreOS uses etcd, a service running on each machine, to handle coordination between software running on the cluster. For a group of CoreOS machines to form a cluster, their etcd instances need to be connected.

A discovery service, [https://discovery.etcd.io](https://discovery.etcd.io), is provided as a free service to help connect etcd instances together by storing a list of peer addresses, metadata and the initial size of the cluster under a unique address, known as the discovery URL. You can generate them very easily:

```
$ curl -w "\n" 'https://discovery.etcd.io/new?size=3'
https://discovery.etcd.io/6a28e078895c5ec737174db2419bb2f3
```

The discovery URL can be provided to each CoreOS machine via [cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config), a minimal config tool that's designed to get a machine connected to the network and join the cluster. The rest of this guide will explain what's happening behind the scenes, but if you're trying to get clustered as quickly as possible, all you need to do is provide a _fresh, unique_ discovery token in your cloud-config.

Boot each one of the machines with identical cloud-config and they should be automatically clustered:

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

Specific documentation are provided for each platform's guide. Not all providers support the $private_ipv4 variable substitution.

## New clusters

Starting a CoreOS cluster requires one of the new machines to become the first leader of the cluster. The initial leader is stored as metadata with the discovery URL in order to inform the other members of the new cluster. Let's walk through a timeline a new 3 machine CoreOS cluster discovering each other:

1. All three machines are booted via a cloud-provider with the same cloud-config in the user-data.
2. Machine 1 starts up first. It requests information about the cluster from the discovery token and submits its `-initial-advertise-peer-urls` address `10.10.10.1`.
3. No state is recorded into the discovery URL metadata, so machine 1 becomes the leader and records the state as `started`.
4. Machine 2 boots and submits its `-initial-advertise-peer-urls` address `10.10.10.2`. It also reads back the list of existing peers (only `10.10.10.1`) and attempts to connect to the address listed.
5. Machine 2 connects to Machine 1 and is now part of the cluster as a follower.
6. Machine 3 boots and submits its `-initial-advertise-peer-urls` address `10.10.10.3`. It reads back the list of peers (`10.10.10.1` and `10.10.10.2`) and selects one of the addresses to try first. When it connects to a machine in the cluster, the machine is given a full list of the existing other members of the cluster.
7. The cluster is now bootstrapped with an initial leader and two followers.

There are a few interesting things happening during this process.

First, each machine is configured with the same discovery URL and etcd figured out what to do. This allows you to load the same cloud-config into an auto-scaling group and it will work whether it is the first or 30th machine in the group.

Second, machine 3 only needed to use one of the addresses stored in the discovery URL to connect to the cluster. Since etcd uses the Raft consensus algorithm, existing machines in the cluster already maintain a list of healthy members in order for the algorithm to function properly. This list is given to the new machine and it starts normal operations with each of the other cluster members.

Third, if you specified `?size=3` upon discovery URL creation, any other machines that join the cluster in the future will automatically start as etcd proxies.

## Common problems with cluster discovery

### Existing clusters

[Do not use the public discovery service to reconfigure a running etcd cluster.][etcd-reconf-no-disc] The public discovery service is a convenience for bootstrapping new clusters, especially on cloud providers with dynamic IP assignment, but is not designed for the later case when the cluster is running and member IPs are known.

To promote proxy members or join new members into an existing etcd cluster, configure static discovery and add members. The [etcd cluster reconfiguration guide][etcd-reconf-on-coreos] details the steps for performing this reconfiguration on CoreOS systems that were originally deployed with public discovery. The more general [etcd cluster reconfiguration document][etcd-reconf] explains the operations for removing and adding cluster members in a cluster already configured with static discovery.

### Invalid cloud-config

The most common problem with cluster discovery is using invalid cloud-config, which will prevent the cloud-config from being applied to the machine. The YAML format uses indention to represent data hierarchy, which makes it easy to create an invalid cloud-config. You should always run newly written cloud-config through the [cloud-config validator](https://coreos.com/validate).

Unfortunately, if you are providing an SSH-key via cloud-config, it can be hard to read the `coreos-cloudinit` log to find out what's wrong. If you're using a cloud provider, you can normally provide an SSH-key via another method which will allow you to log in. If you're running on bare metal, the [coreos.autologin]({{site.baseurl}}/docs/running-coreos/bare-metal/booting-with-pxe/#setting-up-pxelinux.cfg) kernel option will bypass authentication, letting you read the journal.

Reading the `coreos-cloudinit` log will indicate which line is invalid:

```
journalctl _EXE=/usr/bin/coreos-cloudinit
```

### Stale tokens

Another common problem with cluster discovery is attempting to boot a new cluster with a stale discovery URL. As explained above, the initial leader election is recorded into the URL, which indicates that the new etcd instance should be joining an existing cluster.

If you provide a stale discovery URL, the new machines will attempt to connect to each of the old peer addresses, which will fail since they don't exist, and the bootstrapping process will fail.

If you're thinking, why can't the new machines just form a new cluster if they're all down. There's a really great reason for this &mdash; if an etcd peer was in a network partition, it would look exactly like the "full-down" situation and starting a new cluster would form a split-brain. Since etcd will never be able to determine whether a token has been reused or not, it must assume the worst and abort the cluster discovery.

If you're running into problems with your discovery URL, there are a few sources of information that can help you see what's going on. First, you can open the URL in a browser to see what information etcd is using to bootstrap itself:

```sh
{
  action: "get",
  node: {
    key: "/_etcd/registry/506f6c1bc729377252232a0121247119",
    dir: true,
    nodes: [
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/0d79b4791be9688332cc05367366551e",
        value: "http://10.183.202.105:7001",
        expiration: "2014-08-17T16:21:37.426001686Z",
        ttl: 576008,
        modifiedIndex: 72783864,
        createdIndex: 72783864
      },
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/c72c63ffce6680737ea2b670456aaacd",
        value: "http://10.65.177.56:7001",
        expiration: "2014-08-17T12:05:57.717243529Z",
        ttl: 560669,
        modifiedIndex: 72626400,
        createdIndex: 72626400
      },
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/f7a93d1f0cd4d318c9ad0b624afb9cf9",
        value: "http://10.29.193.50:7001",
        expiration: "2014-08-17T17:18:25.045563473Z",
        ttl: 579416,
        modifiedIndex: 72821950,
        createdIndex: 72821950
      }
    ],
    modifiedIndex: 69367741,
    createdIndex: 69367741
  }
}
```

To rule out firewall settings as a source of your issue, ensure that you can curl each of the IPs from machines in your cluster.

If all of the IPs can be reached, the etcd log can provide more clues:

```
journalctl -u etcd2
```

### Communicating with discovery.etcd.io

If your CoreOS cluster can't communicate out to the public internet, [https://discovery.etcd.io](https://discovery.etcd.io) won't work and you'll have to run your own discovery endpoint, which is described below.

### Setting advertised client addresses correctly

Each etcd instance submits the list of `-initial-advertise-peer-urls` of each etcd instance to the configured discovery service. It's important to select an address that *all* peers in the cluster can communicate with. If you are configuring a list of addresses, make sure each member can communicate with at least one of the addresses.

For example, if you're located in two regions of a cloud provider, configuring a private `10.x` address will not work between the two regions, and communication will not be possible between all peers. The `-listen-client-urls` flag allows you to bind to a specific list of interfaces and ports (or all interfaces) to ensure your etcd traffic is routed properly.

## Running your own discovery service

The public discovery service is just an etcd cluster made available to the public internet. Since the discovery service conducts and stores the result of the first leader election, it needs to be consistent. You wouldn't want two machines in the same cluster to think they were both the leader.

Since etcd is designed to this type of leader election, it was an obvious choice to use it for everyone's initial leader election. This means that it's easy to run your own etcd cluster for this purpose.

If you're interested in how discovery API works behind the scenes in etcd, read about [etcd clustering]({{site.baseurl}}/etcd/docs/latest/clustering.html).

[etcd-reconf]: https://coreos.com/etcd/docs/latest/runtime-configuration.html
[etcd-reconf-no-disc]: https://github.com/coreos/etcd/blob/master/Documentation/runtime-reconf-design.md#do-not-use-public-discovery-service-for-runtime-reconfiguration
[etcd-reconf-on-coreos]: ../etcd/etcd-live-cluster-reconfiguration.md
