# Enabling HTTPS in an existing etcd cluster

This guide outlines the process of migrating an existing etcd cluster from HTTP communication to encrypted HTTPS. For added security, it also shows how to require TLS peer certificates to authenticate connections.

## Prepare cluster components

### Check insecure port availability

By default, etcd communicates with clients over two ports: 2379, the current and official IANA port designation, and 4001, for clients who may implement versions of the protocol older than 0.4. We leverage this quirk of legacy support to migrate a running cluster from insecure plain-HTTP communication (on the old port, 4001) to encrypted HTTPS (on the current port, 2379) without cluster downtime. We restrict the legacy communication on port 4001 to the local interface.

If you've configured flannel, fleet, or other components to use custom ports, or 2379 only, they will be reconfigured to use port 4001.

If etcd isn't listening on port 4001, it must also be reconfigured. If you used cloud-config to spin up your machines, you can retrieve the `ETCD_LISTEN_CLIENT_URLS` value from `/run/systemd/system/etcd2.service.d/20-cloudinit.conf` to verify the etcd ports:

```sh
$ grep ETCD_LISTEN_CLIENT_URLS /run/systemd/system/etcd2.service.d/20-cloudinit.conf
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379"
```

In this case etcd is listening only on port 2379. We'll add port 4001 with a systemd [drop-in][drop-ins] unit file. Create the file `/etc/systemd/system/etcd2.service.d/25-insecure_localhost.conf`. In this file, write an excerpt that appends the new URL on port 4001 to the existing value we retrieved in the step above:

```
[Service]
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://127.0.0.1:4001"
```

Run `systemctl daemon-reload` followed by `systemctl restart etcd2` to restart etcd. Check cluster status using the [`etcdctl`][etcdctl] commands:

```sh
$ etcdctl member list
$ etcdctl cluster-health
```

Repeat these steps on each etcd cluster member.

### Generate TLS key pairs

Follow the guide to [generating self-signed certificates][self-signed-ca] to create the certificate/key pairs needed for each etcd cluster member.

### Copy key pairs to nodes

Assume we have three Container Linux machines, running three etcd cluster members: server1, server2, server3; with corresponding IP addresses: 172.16.0.101, 172.16.0.102, and 172.16.0.103. We will use the following key pair file names in our example:

```
server1.pem
server1-key.pem
```

Create the `/etc/ssl/etcd` directory, then copy the corresponding certificate and key there. Set permissions to secure the directory and key file:

```
$ chown -R etcd:etcd /etc/ssl/etcd
$ chmod 600 /etc/ssl/etcd/*-key.pem
```

Copy the `ca.pem` CA certificate file into `/etc/ssl/etcd` as well.

Alternatively, copy `ca.pem` into `/etc/ssl/certs` instead, and run the `update-ca-certificates` script to update the system certificates bundle. After doing so, the added CA will be available to any program running on the node, and it will not be necessary to set the CA path for each application.

Repeat this step on the rest of the cluster members.

### Using an etcd proxy

If you typically connect to a remote etcd cluster, this is a good time to configure an [etcd proxy][etcd proxy] that handles the remote connection and TLS termination, and to reconfigure your apps to communicate through the proxy on localhost. In this case, you must generate a client key pair (e.g. `client1.pem` and `client1-key.pem`) and repeat the *Copy Key Pairs* step above with the client key pair files.

It is also necessary to modify your systemd [unit files][systemd-unit-file] or [drop-ins][drop-ins] which use `etcdctl` in `ExecStart*=` or `ExecStop*=` directives to replace the invocation of `/usr/bin/etcdctl` with `/usr/bin/etcdctl --no-sync`. This will force `etcdctl` to use the proxy for all operations.

## Configure etcd key pair

Now we will configure etcd to use the new certificates. Create a `/etc/systemd/system/etcd2.service.d/30-certs.conf` [drop-in][drop-ins] file with the following contents:

```
[Service]
Environment="ETCD_CERT_FILE=/etc/ssl/etcd/server1.pem"
Environment="ETCD_KEY_FILE=/etc/ssl/etcd/server1-key.pem"
Environment="ETCD_TRUSTED_CA_FILE=/etc/ssl/etcd/ca.pem"
Environment="ETCD_CLIENT_CERT_AUTH=true"
Environment="ETCD_PEER_CERT_FILE=/etc/ssl/etcd/server1.pem"
Environment="ETCD_PEER_KEY_FILE=/etc/ssl/etcd/server1-key.pem"
Environment="ETCD_PEER_TRUSTED_CA_FILE=/etc/ssl/etcd/ca.pem"
Environment="ETCD_PEER_CLIENT_CERT_AUTH=true"
```

Reload systemd configs with `systemctl daemon-reload` then restart etcd by invoking `systemctl restart etcd2`. Check cluster health:

```sh
$ etcdctl member list
$ etcdctl cluster-health
```

Repeat this step on the rest of the cluster members.

### Configure etcd proxy key pair

If proxying etcd connections as discussed above, create a systemd [drop-in][drop-ins] unit file named `/etc/systemd/system/etcd2.service.d/30-certs.conf` with the following contents:

```
[Service]
Environment="ETCD_CERT_FILE=/etc/ssl/etcd/client1.pem"
Environment="ETCD_KEY_FILE=/etc/ssl/etcd/client1-key.pem"
Environment="ETCD_TRUSTED_CA_FILE=/etc/ssl/etcd/ca.pem"
Environment="ETCD_PEER_CERT_FILE=/etc/ssl/etcd/client1.pem"
Environment="ETCD_PEER_KEY_FILE=/etc/ssl/etcd/client1-key.pem"
Environment="ETCD_PEER_TRUSTED_CA_FILE=/etc/ssl/etcd/ca.pem"
# Listen only on loopback interface.
Environment="ETCD_LISTEN_CLIENT_URLS=http://127.0.0.1:2379,http://127.0.0.1:4001"
```

Reload systemd configs with `systemctl daemon-reload`, then restart etcd with `systemctl restart etcd2`. Check proxy status with, e.g.:

```sh
$ curl http://127.0.0.1:4001/v2/stats/self
```

## Change etcd peer URLs

Use `etcdctl` piped through an `awk` filter to print the commands needed to reconfigure the cluster peer URLs. After reviewing the command lines, we will invoke them on one etcd cluster member.

### Current etcd

On etcd v2.2 or later, invoke:

```sh
$ etcdctl member list | awk -F'[: =]' '{print "etcdctl member update "$1" https:"$7":"$8}'
```

A series of command lines will be printed, one for each etcd cluster member:

```sh
etcdctl member update 2428639343c1baab https://172.16.0.102:2380
etcdctl member update 50da8780fd6c8919 https://172.16.0.103:2380
etcdctl member update 81901418ed658b78 https://172.16.0.101:2380
```

On any one etcd cluster member, run each of the printed commands -- *except the last one*. We will change the peer URL for the last etcd cluster member only after completing any proxy configuration below.

Check cluster health:

```sh
$ etcdctl member list
$ etcdctl cluster-health
```

If the cluster members report as expected, we can move on to configuring the local etcd proxy, if neeeded, then invoking the last of the printed command lines on a cluster member.

### etcd proxy

An operating etcd proxy will automatically adopt new peer URLs within 30 seconds of each update (that is, the default [`--proxy-refresh-interval][proxy-refresh] 30000`).

### etcd versions 2.1 and older

For etcd versions 2.1 and earlier, the awk filter to produce the peer URL change commands is different:

```sh
$ etcdctl member list | awk -F'[: =]' '{print "curl -XPUT -H \"Content-Type: application/json\" http://localhost:2379/v2/members/"$1" -d \x27{\"peerURLs\":[\"https:"$7":"$8"\"]}\x27"}'
```

This will produce a set of command lines like:

```sh
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/2428639343c1baab -d '{"peerURLs":["https://172.16.0.102:2380"]}'
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/50da8780fd6c8919 -d '{"peerURLs":["https://172.16.0.103:2380"]}'
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/81901418ed658b78 -d '{"peerURLs":["https://172.16.0.101:2380"]}'
```

Apply the changes in the same manner described above, by running each of the printed commands, except the last one, on any one etcd cluster member. Finally, invoke the last printed command after completing any etcd proxy configuration in the previous section.

## Change etcd client URLs

Create a [drop-in][drop-ins] file named `/etc/systemd/system/etcd2.service.d/40-tls.conf` and write the following there:

```
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=https://172.16.0.101:2379"
Environment="ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379,http://127.0.0.1:4001"
Environment="ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380"
```

Reload systemd configs with `systemctl daemon-reload` and restart etcd by issuing `systemctl restart etcd2`. Check that HTTPS connections are working properly with, e.g.:

```sh
$ curl --cacert /etc/ssl/etcd/ca.pem --cert /etc/ssl/etcd/server1.pem --key /etc/ssl/etcd/server1-key.pem https://172.16.0.101:2379/v2/stats/self
```

Check cluster health with `etcdctl`, now under HTTPS encryption:

```sh
$ etcdctl --ca-file /etc/ssl/etcd/ca.pem --cert-file /etc/ssl/etcd/server1.pem --key-file /etc/ssl/etcd/server1-key.pem member list
$ etcdctl --ca-file /etc/ssl/etcd/ca.pem --cert-file /etc/ssl/etcd/server1.pem --key-file /etc/ssl/etcd/server1-key.pem cluster-health
```

The certificate options can be read from environment variables to shorten the commands:

```sh
$ export ETCDCTL_CERT_FILE=/etc/ssl/etcd/server1.pem
$ export ETCDCTL_KEY_FILE=/etc/ssl/etcd/server1-key.pem
$ export ETCDCTL_CA_FILE=/etc/ssl/etcd/ca.pem
$ etcdctl member list
$ etcdctl cluster-health
```

Check etcd status and availability of the insecure port on the loopback interface:

```sh
$ systemctl status etcd2
$ curl http://127.0.0.1:4001/v2/stats/self
```

Check fleet and flannel:

```sh
$ journalctl -u flanneld -f
$ journalctl -u fleet -f
```

Error messages from an otherwise functional cluster may be ignored on the last etcd restart, but they should not appear thereafter.

Once again, after verifying status, repeat this step on each etcd cluster member.

[drop-ins]: ../os/using-systemd-drop-in-units.md
[self-signed-ca]: ../os/generate-self-signed-certificates.md
[systemd-unit-file]: ../os/getting-started-with-systemd.md#unit-file
[etcd proxy]: https://github.com/coreos/etcd/blob/master/Documentation/v2/proxy.md
[etcdctl]: https://github.com/coreos/etcd/blob/master/etcdctl/README.md
[proxy-refresh]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/configuration.md#--proxy-refresh-interval
