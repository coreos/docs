# Manual configuration of etcd3 on Container Linux

The etcd v3 binary is not slated to ship with Container Linux. With this in mind, you might be wondering, how do I run the newest etcd on my Container Linux node? The short answer: systemd and rkt.

**Before we begin**: If you are able to use Container Linux Configs [to provision your Container Linux nodes][easier-setup], you should go that route. Use this guide only if you must set up etcd the *hard* way.

This tutorial outlines how to set up the newest version of etcd on a Container Linux cluster using the `etcd-member` systemd service. This service spawns a rkt container which houses the etcd process.

It is expected that you have some familiarity with etcd operations before entering this guide and have at least skimmed the [etcd clustering guide][etcd-clustering] first.

We will deploy a simple 2 node etcd v3 cluster on two local virtual machines. This tutorial does not cover setting up TLS, however principles and commands in the [etcd clustering guide][etcd-clustering] carry over into this workflow.

| Node # | IP              | etcd member name |
| ------ | --------------- | ---------------- |
| 0      | 192.168.100.100 | my-etcd-0        |
| 1      | 192.168.100.101 | my-etcd-1        |

These IP addresses are visible from within your two machines as well as on the host machine. Once the VMs are setup you should be able to run `ping 192.168.100.100` and `ping 192.168.100.101`, where those are the ip addresses of the VMs.

SSH into your first node and run `systemctl edit etcd-member` and paste the following code into the editor:

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

This will create a systemd unit *override* and open the new file in `vi`. The file is empty to begin and *you* populate it with the above code. Paste the above code into the editor and `:wq` to save it.

Replace:

| Variable                           | value                                                                                        |
| ---------------------------------- | -------------------------------------------------------------------------------------------- |
| `http://192.168.100.100`           | Your first node's IP address. Found easily by running `ifconfig`.                            |
| `http://192.168.100.101`           | The second node's IP address.                                                                |
| `my-etcd-0`                        | The first node's name (can be whatever you want).                                            |
| `my-etcd-1`                        | The other node's name.                                                                       |
| `f7b787ea26e0c8d44033de08c2f80632` | The discovery token obtained from https://discovery.etcd.io/new?size=2 (generate your own!). |

> To create a cluster of more than 2 nodes, set `size=#`, where `#` is the number of nodes you wish to create. If not set, any extra nodes will become proxies.

1. Edit the service override.
2. Save the changes.
3. Run `systemctl daemon-reload`.
4. Do the same on the other node, swapping the names and ip-addresses appropriately. It should look something like this:


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

Note that the arguments used in this configuration file are the same as those passed to the etcd binary when starting a cluster. For more information on help and sanity checks, see the [etcd clustering guide][etcd-clustering].

## Verification

1. To verify that services have been configured, run `systemctl cat etcd-member` on the manually configured nodes. This will print the service and it's override conf to the screen. You should see the overrides on both nodes.

2. To enable the service on boot, run `systemctl enable etcd-member` on all nodes.

3. To start the service, run `systemctl start etcd-member`. This command may take a while to complete becuase it is downloading a rkt container and setting up etcd.

If the last command hangs for a very long time (10+ minutes), press <Ctrl>+c on your keyboard to exit the commadn and run `journalctl -xef`. If this outputs something like `rafthttp: request cluster ID mismatch (got 7db8ba5f405afa8d want 5030a2a4c52d7b21)` this means there is existing data on the nodes. Since we are starting completely new nodes we will wipe away the existing data and re-start the service. Run the following on both nodes:

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

There you have it! You have now set up etcd v3 by hand. Pat yourself on the back. Take five.

## Troubleshooting

In the process of setting up your etcd cluster if you got it into a non-working state, you have a few options:

* Reference the [runtime configuration guide][runtime-guide].
* Reset your environment.

Since etcd is running in a container, the second option is very easy.

Run the following commands on the Container Linux nodes:


1. `systemctl stop etcd-member` to stop the service.
2. `systemctl status etcd-member` to verify the service has exited. The output should look like:

```sh
● etcd-member.service - etcd (System Application Container)
   Loaded: loaded (/usr/lib/systemd/system/etcd-member.service; disabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/etcd-member.service.d
           └─override.conf
   Active: inactive (dead)
     Docs: https://github.com/coreos/etcd
```

3. `rm /var/lib/etcd2` to remove the etcd v2 data.
4. `rm /var/lib/etcd` to remove the etcd v3 data.

> If you set a custom data directory for the etcd-member service, you will need to run a modified `rm` command.

5. Edit the etcd-member service with `systemctl edit etcd-member`.
6. Restart the etcd-member service with `systemctl start etcd-member`.

[runtime-guide]: https://coreos.com/etcd/docs/latest/op-guide/runtime-configuration.html
[etcd-clustering]: https://coreos.com/etcd/docs/latest/op-guide/clustering.html
[easier-setup]: getting-started-with-etcd.md
