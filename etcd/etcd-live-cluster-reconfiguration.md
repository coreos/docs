# etcd cluster runtime reconfiguration on CoreOS Container Linux

This document describes the reconfiguration or recovery of an etcd cluster running on Container Linux, using a combination of `systemd` features and `etcdctl` commands.

## Change etcd cluster size

When [cloud-config][cloud-config] is used to configure an etcd member on a Container Linux node, it compiles a special `/run/systemd/system/etcd2.service.d/20-cloudinit.conf` [drop-in unit file][drop-in]. That is, the cloud-config below:

```cloud-config
#cloud-config

coreos:
  etcd2:
    advertise-client-urls: http://<PEER_ADDRESS>:2379
    initial-advertise-peer-urls: http://<PEER_ADDRESS>:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://0.0.0.0:2380
    discovery: https://discovery.etcd.io/<token>
```

will generate the following [drop-in][drop-in]:

```ini
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=http://<PEER_ADDRESS>:2379"
Environment="ETCD_DISCOVERY=https://discovery.etcd.io/<token>"
Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=http://<PEER_ADDRESS>:2380"
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://0.0.0.0:4001"
Environment="ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380"
```

If the etcd cluster is secured with TLS, use `https://` instead of `http://` in the command examples below.

Assume that you have created a five-node Container Linux cluster, but did not specify cluster size in the [discovery][etcd-discovery] URL. Since the default discovery cluster size is 3, the remaining two nodes were configured as proxies. You would like to promote these proxies to full etcd cluster members, without bootstrapping a new etcd cluster.

The existing cluster can be reconfigured. Run `etcdctl member add node4 http://10.0.1.4:2380`. Later steps will use information from the output of this command, so it's a good idea to copy and paste it somewhere convenient. The output of a successful member addition will look like this:

```
added member 9bf1b35fc7761a23 to cluster

ETCD_NAME="node4"
ETCD_INITIAL_CLUSTER="1dc800dbf6a732d8839bc71d0538bb99=http://10.0.1.1:2380,f961e5cb1b0cb8810ea6a6b7a7c8b5cf=http://10.0.1.2:2380,8982fae69ad09c623601b68c83818921=http://10.0.1.3:2380,node4=http://10.0.1.4:2380"
ETCD_INITIAL_CLUSTER_STATE=existing
```

The `ETCD_DISCOVERY` environment variable defined in `20-cloudinit.conf` conflicts with the `ETCD_INITIAL_CLUSTER` setting needed for these steps, so the first step is clearing it by overriding `20-cloudinit.conf` with a new drop-in, `99-restore.conf`. `99-restore.conf` contains an empty `Environment="ETCD_DISCOVERY="` string.

The complete example looks like this. On the `node4` Container Linux host, create a  temporary systemd drop-in, `/run/systemd/system/etcd2.service.d/99-restore.conf` with the contents below, filling in the information from the output of the `etcd member add` command we ran previously:

```ini
[Service]
# remove previously created proxy directory
ExecStartPre=/usr/bin/rm -rf /var/lib/etcd2/proxy
# NOTE: use this option if you would like to re-add broken etcd member into cluster
# Don't forget to make a backup before
#ExecStartPre=/usr/bin/rm -rf /var/lib/etcd2/member /var/lib/etcd2/proxy
# here we clean previously defined ETCD_DISCOVERY environment variable, we don't need it as we've already bootstrapped etcd cluster and ETCD_DISCOVERY conflicts with ETCD_INITIAL_CLUSTER environment variable
Environment="ETCD_DISCOVERY="
Environment="ETCD_NAME=node4"
# We use ETCD_INITIAL_CLUSTER variable value from previous step ("etcdctl member add" output)
Environment="ETCD_INITIAL_CLUSTER=node1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,node3=http://10.0.1.3:2380,node4=http://10.0.1.4:2380"
Environment="ETCD_INITIAL_CLUSTER_STATE=existing"
```

Run `sudo systemctl daemon-reload` to parse the new and edited units. Check whether the new [drop-in][drop-in] is valid by checking the service's journal: `sudo journalctl _PID=1 -e -u etcd2`. If everything is ok, run `sudo systemctl restart etcd2` to activate your changes. You will see that the former proxy node has become a cluster member:

```
etcdserver: start member 9bf1b35fc7761a23 in cluster 36cce781cb4f1292
```

Once your new member node is up and running, and `etcdctl cluster-health` shows a healthy cluster, remove the temporary drop-in file and reparse the services: `sudo rm /run/systemd/system/etcd2.service.d/99-restore.conf && sudo systemctl daemon-reload`.

## Replace a failed etcd member on CoreOS Container Linux

This section provides instructions on how to recover a failed etcd member. It is important to know that an etcd cluster cannot be restored using only a discovery URL; the discovery URL is used only once during cluster bootstrap.

In this example, we use a 3-member etcd cluster with one failed node, that is still running and has maintained [quorum][majority]. An etcd member node might fail for several reasons: out of disk space, an incorrect reboot, or issues on the underlying system. Note that this example assumes you used [cloud-config][cloud-config] with an etcd [discovery URL][etcd-discovery] to bootstrap your cluster, with the following default options:

```cloud-config
#cloud-config

coreos:
  etcd2:
    advertise-client-urls: http://<PEER_ADDRESS>:2379
    initial-advertise-peer-urls: http://<PEER_ADDRESS>:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://0.0.0.0:2380
    discovery: https://discovery.etcd.io/<token>
```

If the etcd cluster is protected with TLS, use `https://` instead of `http://` in the examples below.

Let's assume that your etcd cluster has a faulty member `10.0.1.2`:

```sh
$ etcdctl cluster-health
member fe2f75dd51fa5ff is healthy: got healthy result from http://10.0.1.1:2379
failed to check the health of member 1609b5a3a078c227 on http://10.0.1.2:2379: Get http://10.0.1.2:2379/health: dial tcp 10.0.1.2:2379: connection refused
member 1609b5a3a078c227 is unreachable: [http://10.0.1.2:2379] are all unreachable
member 60e8a32b09dc91f1 is healthy: got healthy result from http://10.0.1.3:2379
cluster is healthy
```

Run `etcdctl` from a working node, or use the [`ETCDCTL_ENDPOINT`][etcdctl-endpoint] environment variable or command line option to point `etcdctl` at any healthy member node.

[Remove the failed member][etcdctl-member-remove] `10.0.1.2` from the etcd cluster. The remove subcommand informs all other cluster nodes that a human has determined this node is dead and not available for connections:

```sh
$ etcdctl member remove 1609b5a3a078c227
Removed member 1609b5a3a078c227 from cluster
```

Then, on the failed node (`10.0.1.2`), stop the etcd2 service:

```sh
$ sudo systemctl stop etcd2
```

Clean up the `/var/lib/etcd2` directory:

```sh
$ sudo rm -rf /var/lib/etcd2/*
```

Check that the `/var/lib/etcd2/` directory exists and is empty. If you removed this directory accidentally, you can recreate it with the proper modes by using:

```sh
$ sudo systemd-tmpfiles --create /usr/lib64/tmpfiles.d/etcd2.conf
```

Next, reinitialize the failed member. Note that `10.0.1.2` is an example IP address. Use the IP address corresponding to your failed node:

```sh
$ etcdctl member add node2 http://10.0.1.2:2380
Added member named node2 with ID 4fb77509779cac99 to cluster

ETCD_NAME="node2"
ETCD_INITIAL_CLUSTER="52d2c433e31d54526cf3aa660304e8f1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,2cb7bb694606e5face87ee7a97041758=http://10.0.1.3:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
```

With the new node added, create a systemd [drop-in][drop-in] `/run/systemd/system/etcd2.service.d/99-restore.conf`, replacing the node data with the appropriate information from the output of the `etcdctl member add` command executed in the last step.

```ini
[Service]
# here we clean previously defined ETCD_DISCOVERY environment variable, we don't need it as we've already bootstrapped etcd cluster and ETCD_DISCOVERY conflicts with ETCD_INITIAL_CLUSTER environment variable
Environment="ETCD_DISCOVERY="
Environment="ETCD_NAME=node2"
# We use ETCD_INITIAL_CLUSTER variable value from previous step ("etcdctl member add" output)
Environment="ETCD_INITIAL_CLUSTER=52d2c433e31d54526cf3aa660304e8f1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,2cb7bb694606e5face87ee7a97041758=http://10.0.1.3:2380"
Environment="ETCD_INITIAL_CLUSTER_STATE=existing"
```

**Note:** Make sure to remove the excess double quotes just after `ETCD_INITIAL_CLUSTER=` entry.

Parse the new drop-in:

```sh
$ sudo systemctl daemon-reload
```

Check whether the new [drop-in][drop-in] is valid:

```sh
sudo journalctl _PID=1 -e -u etcd2
```

And finally, if everything is ok start the `etcd2` service:

```sh
$ sudo systemctl start etcd2
```

Check cluster health:

```sh
$ etcdctl cluster-health
```

If your cluster has healthy state, etcd successfully wrote cluster configuration into the `/var/lib/etcd2` directory. Now it is safe to remove the temporary `/run/systemd/system/etcd2.service.d/99-restore.conf` drop-in file.

## etcd disaster recovery on CoreOS Container Linux

If a cluster is totally broken and [quorum][majority] cannot be restored, all etcd members must be reconfigured from scratch. This procedure consists of two steps:

* Initialize a one-member etcd cluster using the initial [data directory][data-dir]
* Resize this etcd cluster by adding new etcd members by following the steps in the [change the etcd cluster size][change-cluster-size] section, above.

This document is an adaptation for Container Linux of the official [etcd disaster recovery guide][disaster-recovery], and uses systemd [drop-ins][drop-in] for convenience.

Let's assume a 3-node cluster with no living members. First, stop the `etcd2` service on all the members:

```sh
$ sudo systemctl stop etcd2
```

If you have etcd proxy nodes, they should update members list automatically according to the [`--proxy-refresh-interval`][proxy-refresh] configuration option.

Then, on one of the *member* nodes, run the following command to backup the current [data directory][data-dir]:

```sh
$ sudo etcdctl backup --data-dir /var/lib/etcd2 --backup-dir /var/lib/etcd2_backup
```

Now that we've made a backup, we tell etcd to start a one-member cluster. Create the `/run/systemd/system/etcd2.service.d/98-force-new-cluster.conf` [drop-in][drop-in] file with the following contents:

```ini
[Service]
Environment="ETCD_FORCE_NEW_CLUSTER=true"
```

Then run `sudo systemctl daemon-reload`. Check whether the new [drop-in][drop-in] is valid by looking in its journal for errors: `sudo journalctl _PID=1 -e -u etcd2`. If everything is ok, start the `etcd2` daemon: `sudo systemctl start etcd2`.

Check the cluster state:

```sh
$ etcdctl member list
e6c2bda2aa1f2dcf: name=1be6686cc2c842db035fdc21f56d1ad0 peerURLs=http://10.0.1.2:2380 clientURLs=http://10.0.1.2:2379
$ etcdctl cluster-health
member e6c2bda2aa1f2dcf is healthy: got healthy result from http://10.0.1.2:2379
cluster is healthy
```

If the output contains no errors, remove the `/run/systemd/system/etcd2.service.d/98-force-new-cluster.conf` drop-in file, and reload systemd services: `sudo systemctl daemon-reload`. It is not necessary to restart the `etcd2` service after this step.

The next steps are those described in the [Change etcd cluster size][change-cluster-size] section, with one difference: Remove the `/var/lib/etcd2/member` directory as well as `/var/lib/etcd2/proxy`.


[change-cluster-size]: #change-etcd-cluster-size
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[data-dir]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/configuration.md#-data-dir
[disaster-recovery]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/recovery.md#disaster-recovery
[drop-in]: ../os/using-systemd-drop-in-units.md
[etcd-discovery]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/clustering.md#lifetime-of-a-discovery-url
[etcdctl-endpoint]: https://github.com/coreos/etcd/tree/master/etcdctl#--endpoint
[etcdctl-member-remove]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/runtime-configuration.md#remove-a-member
[machine-id]: http://www.freedesktop.org/software/systemd/man/machine-id.html
[majority]: https://github.com/coreos/etcd/blob/master/Documentation/v2/admin_guide.md#fault-tolerance-table
[proxy-refresh]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/configuration.md#--proxy-refresh-interval
