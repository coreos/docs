# Setting up etcd v3 on Container Linux "by hand"

The etcd v3 binary is not slated to ship with Container Linux. With this in mind, you might be wondering, how do I run the newest etcd on my Container Linux node? The short answer: systemd and rkt!

**Before we begin** if you are able to use Container Linux Configs or ignition configs [to provision your Container Linux nodes][easier-setup], you should go that route. Only follow this guide if you *have* to setup etcd the 'hard' way.

This tutorial outlines how to setup the newest version of etcd on a Container Linux cluster using the `etcd-member` systemd service. This service spawns a rkt container which houses the etcd process.

We will deploy a simple 2 node etcd v3 cluster on two local Virtual Machines. This tutorial does not cover setting up TLS, however principles and commands in the [etcd clustering guide][etcd-clustering] carry over into this workflow.

| Node # | IP              | etcd member name |
| ------ | --------------- | ---------------- |
| 0      | 192.168.100.100 | my-etcd-0        |
| 1      | 192.168.100.101 | my-etcd-1        |

First, run `sudo systemctl edit etcd-member` and paste the following code into the editor:

```ini
[Service]
Environment="ETCD_IMAGE_TAG=v3.1.7"
Environment="ETCD_OPTS=\
  --name=\"my-etcd-0\" \
  --listen-client-urls=\"http://192.168.100.100:2379\" \
  --advertise-client-urls=\"http://192.168.100.100:2379\" \
  --listen-peer-urls=\"http://192.168.100.100:2380\" \
  --initial-advertise-peer-urls=\"http://192.168.100.100:2380\" \
  --initial-cluster=\"my-etcd-0=http://192.168.100.100:2380,my-etcd-1=http://192.168.100.101:2380\" \
  --initial-cluster-token=\"f7b787ea26e0c8d44033de08c2f80632\" \
  --initial-cluster-state=\"new\""
```

Replace:

| Variable                           | value                                                                                        |
| ---------------------------------- | -------------------------------------------------------------------------------------------- |
| `http://192.168.100.100`           | Your first node's IP address. Found easily by running `ifconfig`.                            |
| `http://192.168.100.101`           | The second node's IP address.                                                                |
| `my-etcd-0`                        | The first node's name (can be whatever you want).                                            |
| `my-etcd-1`                        | The other node's name.                                                                       |
| `f7b787ea26e0c8d44033de08c2f80632` | The discovery token obtained from https://discovery.etcd.io/new?size=2 (generate your own!). |

*If you want a cluster of more than 2 nodes, make sure `size=#` where # is the number of nodes you want. Otherwise the extra ndoes will become proxies.*

1. Edit the file appropriately and save it. Run `systemctl daemon-reload`.
2. Do the same on the other node, swapping the names and ip-addresses appropriately. It should look like this:


```ini
[Service]
Environment="ETCD_IMAGE_TAG=v3.1.7"
Environment="ETCD_OPTS=\
  --name=\"my-etcd-1\" \
  --listen-client-urls=\"http://192.168.100.101:2379\" \
  --advertise-client-urls=\"http://192.168.100.101:2379\" \
  --listen-peer-urls=\"http://192.168.100.101:2380\" \
  --initial-advertise-peer-urls=\"http://192.168.100.101:2380\" \
  --initial-cluster=\"my-etcd-0=http://192.168.100.100:2380,my-etcd-1=http://192.168.100.101:2380\" \
  --initial-cluster-token=\"f7b787ea26e0c8d44033de08c2f80632\" \
  --initial-cluster-state=\"new\""
```

*If at any point you get confused about this configuration file, keep in mind that these arguments are the same as those passed to the etcd binary when starting a cluster. With that in mind, reference the [etcd clustering guide][etcd-clustering] for help and sanity-checks.*

## Verification

You can verify that the services have been configured by running `systemctl cat etcd-member`. This will print the service and it's override conf to the screen. You should see your changes on both nodes.

On both nodes run `systemctl enable etcd-member && systemctl start etcd-member`.

If this command hangs for a very long time, <Ctrl>+c to exit out and run `journalctl -xef`. If this outputs something like `rafthttp: request cluster ID mismatch (got 7db8ba5f405afa8d want 5030a2a4c52d7b21)` this means there is existing data on the nodes. Since we are starting completely new nodes we will wipe away the existing data and re-start the service. Run the following on both nodes:

```sh
$ rm -rf /var/lib/etcd
$ systemctl restart etcd-member
```

On your local machine, you should be able to run etcdctl commands which talk to this etcd cluster.

```sh
$ etcdctl --endpoints="http://192.168.100.100:2379,http://192.168.100.101:2379" cluster-health
member fccad8b3e5be5a7 is healthy: got healthy result from http://192.168.100.100:2379
member c337d56ffee02e40 is healthy: got healthy result from http://192.168.100.101:2379
cluster is healthy
$ etcdctl --endpoints="http://192.168.100.100:2379,http://192.168.100.101:2379" set it-works true
true
$ etcdctl --endpoints="http://192.168.100.100:2379,http://192.168.100.101:2379" get it-works 
true
```

There you have it! You have now setup etcd v3 by hand. Pat yourself on the back. Take five.

## Troubleshooting

In the process of setting up your etcd cluster you got it into a non-working state, you have a few options:

1. Reference the [runtime configuration guide][runtime-guide].
2. Reset your environment.

Since etcd is running in a container, the second option is very easy.

Start by stopping the `etcd-member` service (run these commands *on* the Container Linux nodes).

```sh
$ systemctl stop etcd-member
$ systemctl status etcd-member
● etcd-member.service - etcd (System Application Container)
   Loaded: loaded (/usr/lib/systemd/system/etcd-member.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/etcd-member.service.d
           └─override.conf
   Active: inactive (dead)
     Docs: https://github.com/coreos/etcd
```

Next, delete the etcd data (again, run on the Container Linux nodes):

```sh
$ rm /var/lib/etcd2
$ rm /var/lib/etcd
```

*If you set the etcd-member to have a custom data directory, you will need to run a different `rm` command.*

Edit the etcd-member service, restart the `etcd-member` service, and basically start this guide again from the top.

[runtime-guide]: https://coreos.com/etcd/docs/latest/op-guide/runtime-configuration.html
[etcd-clustering]: https://coreos.com/etcd/docs/latest/op-guide/clustering.html
[easier-setup]: getting-started-with-etcd.md
