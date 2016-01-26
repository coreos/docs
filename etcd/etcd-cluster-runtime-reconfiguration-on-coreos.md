# etcd Cluster Runtime Reconfiguration on CoreOS

## Change the etcd Cluster Size

When you use [Cloud-Config][cloud-config] to configure etcd member on your CoreOS node it compiles special `/run/systemd/system/etcd2.service.d/20-cloudinit.conf` [drop-in] unit file. I.e. Cloud-Config below: 

```yaml
#cloud-config

coreos:
  etcd2:
    advertise-client-urls: http://<PEER_ADDRESS>:2379
    initial-advertise-peer-urls: http://<PEER_ADDRESS>:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://0.0.0.0:2380
    discovery: https://discovery.etcd.io/<token>
```

will generate following [drop-in]:

```ini
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=http://<PEER_ADDRESS>:2379"
Environment="ETCD_DISCOVERY=https://discovery.etcd.io/<token>"
Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=http://<PEER_ADDRESS>:2380"
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://0.0.0.0:4001"
Environment="ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380"
```

If you have etcd cluster with TLS, just use `https://` instead of `http://` in commands' examples below.

Let's assume that you have created five-nodes CoreOS cluster but have forgot to set cluster size in [discovery][etcd-discovery] URL and its cluster size is three by default. Your rest two nodes became proxy and you would like to convert them to etcd2 member.

You can solve this problem without new cluster bootstrapping. Just run `etcdctl member add node4 http://10.0.1.4:2380` and remember its output (we will use it later):

```
added member 9bf1b35fc7761a23 to cluster

ETCD_NAME="node4"
ETCD_INITIAL_CLUSTER="1dc800dbf6a732d8839bc71d0538bb99=http://10.0.1.1:2380,f961e5cb1b0cb8810ea6a6b7a7c8b5cf=http://10.0.1.2:2380,8982fae69ad09c623601b68c83818921=http://10.0.1.3:2380,node4=http://10.0.1.4:2380"
ETCD_INITIAL_CLUSTER_STATE=existing
```

Already defined in `20-cloudinit.conf` `ETCD_DISCOVERY` conflicts with `ETCD_INITIAL_CLUSTER` environment variable, so we have to clean it. We can do that overriding `20-cloudinit.conf` by `99-restore.conf` drop-in with the `Environment="ETCD_DISCOVERY="` string.

The complete example will look this way. On `node4` CoreOS host create temporarily systemd drop-in unit `/run/systemd/system/etcd2.service.d/99-restore.conf` with the content below (we use variables from `etcdctl member add` output):

```
[Service]
# remove previously created proxy directory
ExecStartPre=/usr/bin/rm -rf /var/lib/etcd2/proxy
# here we clean previously defined ETCD_DISCOVERY environment variable, we don't need it as we've already bootstrapped etcd cluster and ETCD_DISCOVERY conflicts with ETCD_INITIAL_CLUSTER environment variable
Environment="ETCD_DISCOVERY="
Environment="ETCD_NAME=node4"
# We use ETCD_INITIAL_CLUSTER variable value from previous step ("etcdctl member add" output)
Environment="ETCD_INITIAL_CLUSTER=node1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,node3=http://10.0.1.3:2380,node4=http://10.0.1.4:2380"
Environment="ETCD_INITIAL_CLUSTER_STATE=existing"
```

**Note:** make sure you've removed double quotes just after `ETCD_INITIAL_CLUSTER=` entry.

Run `sudo systemctl daemon-reload` and `sudo systemctl restart etcd2` to apply your changes. You will see that your proxy node became cluster member:

```
etcdserver: start member 9bf1b35fc7761a23 in cluster 36cce781cb4f1292
```

Once your proxy node became member node and `etcdctl cluster-health` shows healthy cluster, you can remove your temporarily drop-in `sudo rm /run/systemd/system/etcd2.service.d/99-restore.conf && sudo systemctl daemon-reload`.

## Replace A Failed etcd Member on CoreOS

Here you will find step-by-step instructions on how to recover your failed etcd member. It is important to know that you can not restore your etcd cluster using only discovery URL. Discovery URL is used only once at bootstrap.

In this example we will review 3-members etcd cluster with one failed node. etcd member node could be failed by several reasons: out of disk space, incorrect reboot, and other reasons. It is important to take into consideration that this example assumes you used [Cloud-Config][cloud-config] with [discovery URL][etcd-discovery] to bootstrap your cluster with the following default options:

```yaml
#cloud-config

coreos:
  etcd2:
    advertise-client-urls: http://<PEER_ADDRESS>:2379
    initial-advertise-peer-urls: http://<PEER_ADDRESS>:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://0.0.0.0:2380
    discovery: https://discovery.etcd.io/<token>
```

If you have etcd cluster with TLS, just use `https://` instead of `http://` in commands' examples below. Let's assume that your etcd cluster has faulty `10.0.1.2` member:

```sh
$ etcdctl cluster-health
member fe2f75dd51fa5ff is healthy: got healthy result from http://10.0.1.1:2379
failed to check the health of member 1609b5a3a078c227 on http://10.0.1.2:2379: Get http://10.0.1.2:2379/health: dial tcp 192.168.122.69:2379: connection refused
member 1609b5a3a078c227 is unreachable: [http://10.0.1.2:2379] are all unreachable
member 60e8a32b09dc91f1 is healthy: got healthy result from http://10.0.1.3:2379
cluster is healthy
```

We have to run `etcdctl` from a working node, or just use [`ETCDCTL_ENDPOINT`][etcdctl-endpoint] environment variable or parameter to specify `etcdctl` to use healthy member node.

Then we have to [remove failed][etcdctl-member-remove] 10.0.1.2 member from your etcd cluster. This will tell all the other nodes in the cluster that a human has determined this node is dead and not to connect to it ever again:

```sh
$ etcdctl member remove 1609b5a3a078c227
Removed member 1609b5a3a078c227 from cluster
```

Then on the failed node (10.0.1.2) we have to stop etcd2 service:

```sh
$ sudo systemctl stop etcd2
```

And clean up the `/var/lib/etcd2` directory:

```sh
$ sudo rm -rf /var/lib/etcd2/*
```

You have to make sure that this directory exists and empty. It you removed this directory accidentally, you can recreate it with the command below:

```sh
$ sudo systemd-tmpfiles --create /usr/lib64/tmpfiles.d/etcd2.conf
```

or with this one:

```sh
$ sudo install -m 755 -d -o etcd -g etcd /var/lib/etcd2
```

At the next step we have to reinitialize failed member (please note that 10.0.1.2 is an example IP address, you have to use IP address which corresponds to your failed node):

```sh
$ etcdctl member add node2 http://10.0.1.2:2380
Added member named node2 with ID 4fb77509779cac99 to cluster

ETCD_NAME="node2"
ETCD_INITIAL_CLUSTER="52d2c433e31d54526cf3aa660304e8f1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,2cb7bb694606e5face87ee7a97041758=http://10.0.1.3:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
```

`etcdctl` will print a tip which we will use to configure new etcd member.

Now we have to create systemd [drop-in] `/run/systemd/system/etcd2.service.d/99-restore.conf` with the options we got on previous step:

```
[Service]
# here we clean previously defined ETCD_DISCOVERY environment variable, we don't need it as we've already bootstrapped etcd cluster and ETCD_DISCOVERY conflicts with ETCD_INITIAL_CLUSTER environment variable
Environment="ETCD_DISCOVERY="
Environment="ETCD_NAME=node4"
# We use ETCD_INITIAL_CLUSTER variable value from previous step ("etcdctl member add" output)
Environment="ETCD_INITIAL_CLUSTER=52d2c433e31d54526cf3aa660304e8f1=http://10.0.1.1:2380,node2=http://10.0.1.2:2380,2cb7bb694606e5face87ee7a97041758=http://10.0.1.3:2380"
Environment="ETCD_INITIAL_CLUSTER_STATE=existing"
```

**Note:** make sure you've removed double quotes just after `ETCD_INITIAL_CLUSTER=` entry.

Reload systemd daemon to apply new drop-in:

```sh
$ sudo systemctl daemon-reload
```

And finally start etcd2 service:

```sh
$ sudo systemctl start etcd2
```

You can check whether your cluster is healthy:

```sh
$ etcdctl cluster-health
```

When your cluster has healthy state that means that etcd successfully wrote cluster configuration into `/var/lib/etcd2` directory. And now it is safe to remove `/run/systemd/system/etcd2.service.d/99-restore.conf` drop-in. Or leave it as is because on next boot it will be cleaned up automatically.

[machine-id]: http://www.freedesktop.org/software/systemd/man/machine-id.html
[drop-in]: /os/using-systemd-drop-in-units.md
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[etcd-member-name]: https://github.com/coreos/etcd/blob/master/Documentation/configuration.md#-name
[etcd-discovery]: https://github.com/coreos/etcd/blob/master/Documentation/clustering.md#lifetime-of-a-discovery-url
[etcdctl-endpoint]: https://github.com/coreos/etcd/tree/master/etcdctl#--endpoint
[etcdctl-member-remove]: https://github.com/coreos/etcd/blob/master/Documentation/runtime-configuration.md#remove-a-member
[locksmith]: https://github.com/coreos/locksmith
[fleet]: https://github.com/coreos/fleet
