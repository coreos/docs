# etcd cluster runtime reconfiguration on CoreOS Container Linux

This document describes the reconfiguration and recovery of an etcd cluster running on Container Linux, using a combination of `systemd` features and `etcdctl` commands. The examples given in this document show the configuration for a three-node Container Linux cluster. Replace the IP addresses used in the examples with the corresponding real IPs.

## Configuring etcd using Container Linux Config

When a [Container Linux Config][cl-configs] is used for configuring an etcd member on a Container Linux node, it compiles a special `/etc/systemd/system/etcd-member.service.d/20-clct-etcd-member.conf` [drop-in unit file][drop-in]. For example:

```yaml container-linux-config
etcd:
  name: demo-etcd-1
  listen_client_urls: http://10.240.0.1:2379,http://0.0.0.0:4001
  advertise_client_urls: http://10.240.0.1:2379
  listen_peer_urls:            http://0.0.0.0:2380
  initial_advertise_peer_urls: http://10.240.0.1:2380
  initial_cluster:             demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380
  initial_cluster_token:       demo-etcd-token
  initial_cluster_state:       new
```

The above Container Linux config file can be used to provision a machine. Provisioning with a config file creates the following [drop-in][drop-in]:

```ini
[Service]
ExecStart=
ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
  --name="demo-etcd-1" \
  --listen-peer-urls="http://0.0.0.0:2380" \
  --listen-client-urls="http://10.240.0.1:2379,http://0.0.0.0:4001" \
  --initial-advertise-peer-urls="http://10.240.0.1:2380" \
  --initial-cluster="demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380" \
  --initial-cluster-state="new" \
  --initial-cluster-token="demo-etcd-token" \
  --advertise-client-urls="http://10.240.0.1:2379"
```

If the etcd cluster is secured with TLS, use `https://` instead of `http://` in the config files. If the peer addresses for the initial cluster are unknown when provisioning the cluster, use the etcd discovery service with the `--discovery="https://discovery.etcd.io/<token>` argument.

### Change etcd cluster size

Changing the size of an etcd cluster is as simple as adding a new member, and using the output of the member addition, such as name of the new etcd member, member IDs, state and URLs of the cluster, to the config file for provisioning on the Container Linux node.

1. Run the `etcdctl member add` command.

   For example:

    ```sh
    $ etcdctl member add node4 http://10.240.0.4:2380
    ```

    The output of a successful member addition is given below:

    ```sh
    added member 9bf1b35fc7761a23 to cluster

    ETCD_NAME="node4"
    ETCD_INITIAL_CLUSTER="demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380,node4=http://10.240.0.4:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"
    ```
2. Store the output of this command for later use.

3. Use the information from the output of the `etcdctl member add` command and provision a new Container Linux host with the following Container Linux Config:

    ```yaml container-linux-config
    etcd:
      name: node4
      listen_client_urls: http://10.240.0.4:2379,http://0.0.0.0:4001
      advertise_client_urls: http://10.240.0.4:2379
      listen_peer_urls: http://0.0.0.0:2380
      initial_advertise_peer_urls: http://10.240.0.4:2380
      initial_cluster: demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380,node4=http://10.240.0.4:2380
      initial_cluster_state: existing
    ```

4. Check whether the new member node is up and running:

    ```sh
    $ etcdctl cluster-health

    member 9bf1b35fc7761a23 is healthy: got healthy result from http://10.240.0.4:2379
    cluster is healthy
    ```

If your cluster has healthy state, etcd successfully writes cluster configuration into the `/var/lib/etcd` directory.

### Replace a failed etcd member on CoreOS Container Linux

An etcd member node might fail for several reasons: out of disk space, an incorrect reboot, or issues on the underlying system. This section provides instructions on how to recover a failed etcd member.

Consider a scenario where a member is failed in a three-member cluster. The cluster is still running and has maintained [quorum][majority].  The example assumes [a Container Linux Config][cl-configs] is used with the following default options:

```yaml container-linux-config
etcd:
  name: demo-etcd-1
  listen_client_urls: http://10.240.0.1:2379,http://0.0.0.0:4001
  advertise_client_urls: http://10.240.0.1:2379
  listen_peer_urls: http://0.0.0.0:2380
  initial_advertise_peer_urls: http://10.240.0.1:2380
  initial_cluster: ddemo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380
  initial_cluster_token: demo-etcd-token
  initial_cluster_state: new
```

If the etcd cluster is protected with TLS, use `https://` instead of `http://` in the examples below.

Assume that the given etcd cluster has a faulty member `10.240.0.2`:

```sh
$ etcdctl cluster-health
member fe2f75dd51fa5ff is healthy: got healthy result from http://10.240.0.1:2379
failed to check the health of member 1609b5a3a078c227 on http://10.240.0.2:2379: Get http://10.240.0.2:2379/health: dial tcp 10.240.0.2:2379: connection refused
member 1609b5a3a078c227 is unreachable: [http://10.240.0.2:2379] are all unreachable
member 60e8a32b09dc91f1 is healthy: got healthy result from http://10.240.0.3:2379
cluster is healthy
```


1. [Remove the failed member][etcdctl-member-remove] `1609b5a3a078c227` from the etcd cluster.

    ```sh
    $ etcdctl member remove 1609b5a3a078c227
    Removed member 1609b5a3a078c227 from cluster
    ```
    The remove subcommand informs all other cluster nodes that a human has determined this node is dead and not available for connections.

2. Stop the etcd-member service on the failed node (`10.240.0.2`):

    ```sh
    $ sudo systemctl stop etcd-member.service
    ```

3. Reinitialize the failed member.

    ```sh
    $ etcdctl member add demo-etcd-2 http://10.240.0.2:2380
    Added member named demo-etcd-2 with ID 4fb77509779cac99 to cluster

    ETCD_NAME="demo-etcd-2"
    ETCD_INITIAL_CLUSTER="demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380"
    ETCD_INITIAL_CLUSTER_STATE="existing"
    ```

4. Modify the existing systemd drop-in, `/etc/systemd/system/etcd-member.service.d/20-clct-etcd-member.conf` by replacing the node data with the appropriate information from the output of the `etcdctl member add` command executed in the last step.

    ```yaml container-linux-config
    etcd:
      name: demo-etcd-2
      listen_client_urls: http://10.240.0.2:2379,http://0.0.0.0:4001
      advertise_client_urls: http://10.240.0.2:2379
      listen_peer_urls: http://0.0.0.0:2380
      initial_advertise_peer_urls: http://10.240.0.2:2380
      initial_cluster: demo-etcd-1=http://10.240.0.1:2380,demo-etcd-2=http://10.240.0.2:2380,demo-etcd-3=http://10.240.0.3:2380
      initial_cluster_token: demo-etcd-token
      initial_cluster_state: existing
    ```

5. Check the cluster health:

    ```sh
    $ etcdctl cluster-health

    member e6c2bda2aa1f2dcf is healthy: got healthy result from http://10.240.0.2:2379
    cluster is healthy
    ```

If your cluster has healthy state, etcd successfully writes cluster configuration into the `/var/lib/etcd` directory.

### Recovering etcd on CoreOS Container Linux

#### etcd v3

1. Download `etcdctl` from the [etcd Release page][etcd-release] and install, for example, into `/opt/bin`.

2. Create a backup directory:

    ```sh
    $ sudo mkdir /var/lib/etcd_backup
    ```

3. Save a snapshot of the database to `/var/lib/etcd_backup/backup.db`:

    ```sh
    $ sudo ETCDCTL_API=3 /opt/bin/etcdctl snapshot save /var/lib/etcd_backup/backup.db
    ```

4. Restore the snapshot file into a new member directory `/var/lib/etcd_backup/etcd`:

    ```sh
    $ sudo ETCDCTL_API=3 /opt/bin/etcdctl snapshot --data-dir /var/lib/etcd_backup/etcd restore backup.db \
    --name new-demo-etcd-1 \
    --initial-cluster new-demo-etcd-1=http://10.240.0.1:2380
    --initial-cluster-token new-etcd-cluster-1 \
    --initial-advertise-peer-urls http://10.240.0.1:2380
    ```

5. Remove the obsolete directory:

    ```sh
    $ sudo rm -rf /var/lib/etcd
    ```

6. Move the restored member directory to `/var/lib/etcd`:

    ```sh
    $ sudo mv /var/lib/etcd_backup/etcd /var/lib/
    ```

7. Set the etcd user permissions:

    ```sh
    $ sudo chown etcd -R /var/lib/etcd
    ```

8. Start the etcd member service:

    ```sh
    $ sudo systemctl start etcd-member.service
    ```

9. Check the node health:

    ```sh
    $ etcdctl cluster-health
    ```

10. The restored cluster is now running with a single node. For information on adding more nodes, see [Change etcd cluster size][change-cluster-size].


#### etcd v2

If a cluster is totally broken and [quorum][majority] cannot be restored, all etcd members must be reconfigured from scratch. This procedure consists of two steps:

* Initialize a one-member etcd cluster using the initial [data directory][data-dir]
* Resize this etcd cluster by adding new etcd members by following the steps in the [change the etcd cluster size][change-cluster-size] section.

This document is an adaptation for Container Linux of the official [etcd disaster recovery guide][disaster-recovery], and uses systemd [drop-ins][drop-in] for convenience.

Consider a three-node cluster with two permanently lost members.

1. Stop the `etcd-member` service on all the members:

    ```sh
    $ sudo systemctl stop etcd-member.service
    ```

    If you have etcd proxy nodes, they should update members list automatically according to the [`--proxy-refresh-interval`][proxy-refresh] configuration option.

2. On one of the *member* nodes, run the following command to backup the current [data directory][data-dir]:

    ```sh
    $ sudo etcdctl backup --data-dir /var/lib/etcd --backup-dir /var/lib/etcd_backup
    ```

    Now that a backup has been created, start a single-member cluster.

3. Create the `/run/systemd/system/etcd-member.service.d/98-force-new-cluster.conf` [drop-in][drop-in] file with the following contents:

    ```ini
    [Service]
    Environment="ETCD_FORCE_NEW_CLUSTER=true"
    ```

4. Run `sudo systemctl daemon-reload`.

5. Check whether the new [drop-in][drop-in] is valid by looking in its journal for errors:

    ```sh
    $ sudo journalctl _PID=1 -e -u etcd-member.service
    ```

6. If everything is ok, start the `etcd-member` daemon:

    ```sh
    $ sudo systemctl start etcd-member.service
    ```

7. Check the cluster state:

    ```sh
    $ etcdctl member list
    e6c2bda2aa1f2dcf: name=1be6686cc2c842db035fdc21f56d1ad0 peerURLs=http://10.240.1.2:2380 clientURLs=http://10.240.1.2:2379
    $ etcdctl cluster-health
    member e6c2bda2aa1f2dcf is healthy: got healthy result from http://10.240.1.2:2379
    cluster is healthy
    ```

8. If the output contains no errors, remove the `98-force-new-cluster.conf` drop-in file.

    ```sh
    $ rm -rf /run/systemd/system/etcd-member.service.d/98-force-new-cluster.conf
    ```

9. Reload systemd services:

   ```
   $ sudo systemctl daemon-reload
   ```

    It is not necessary to restart the `etcd-member` service after reloading the systemd services.

10. Spin up new nodes. Ensure that the version is given in the config file.
    For information on adding more nodes, see [Change etcd cluster size][change-cluster-size].



[change-cluster-size]: #change-etcd-cluster-size
[cl-configs]: ../os/provisioning.md
[data-dir]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/configuration.md#-data-dir
[disaster-recovery]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/recovery.md#disaster-recovery
[disaster-recovery-doc]: https://coreos.com/etcd/docs/latest/op-guide/recovery.html
[drop-in]: ../os/using-systemd-drop-in-units.md
[etcd-discovery]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/clustering.md#lifetime-of-a-discovery-url
[etcdctl-endpoint]: https://github.com/coreos/etcd/tree/master/etcdctl#--endpoint
[etcdctl-member-remove]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/runtime-configuration.md#remove-a-member
[etcd-release]: https://github.com/coreos/etcd/releases/
[machine-id]: http://www.freedesktop.org/software/systemd/man/machine-id.html
[majority]: https://github.com/coreos/etcd/blob/master/Documentation/v2/admin_guide.md#fault-tolerance-table
[proxy-refresh]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/configuration.md#--proxy-refresh-interval
