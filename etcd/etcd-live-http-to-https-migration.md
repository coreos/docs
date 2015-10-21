# etcd Live HTTP to HTTPS migration

If you already have existing etcd cluster which uses insecure HTTP connections and you would like to switch from HTTP to HTTPS and in addition enable TLS certificate authentication, you have to follow instruction below.

## Prepare Cluster Components

### Check insecure port availability

By default fleet and flannel use two etcd client ports: 2379 (IANA port assignment) and 4001 (legacy port). Last one is used for etcd v0.4 backward compatibility. In this example we will use 4001 TCP port for insecure HTTP connections and our etcd members will listen that port only on local interface for security reason. This will allow us to switch transparently to HTTPS configuration without services downtime and simplify configuration

If you've configured flannel, fleetd or other local components to use custom or 2379 port only, you have to configure them to use 4001 TCP port.

If your etcd configuration doesn't have configured 4001 client port, you have to enable it before we proceed with this manual. For example you use Cloud-Config to configure your CoreOS cluster. In this case you have to retrieve `ETCD_LISTEN_CLIENT_URLS` value from `/run/systemd/system/etcd2.service.d/20-cloudinit.conf` config file:

```sh
grep ETCD_LISTEN_CLIENT_URLS /run/systemd/system/etcd2.service.d/20-cloudinit.conf
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379"
```

Then create `/etc/systemd/system/etcd2.service.d/` directory if it doesn't exist and create [drop-in][drop-ins] file: `/etc/systemd/system/etcd2.service.d/25-insecure_localhost.conf`. Use value we've retrieved above and append `http://127.0.0.1:4001` URL at the end:

```
[Service]
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://127.0.0.1:4001"
```

Then run `systemctl daemon-reload` and `systemctl restart etcd2` to restart etcd. Check cluster availability using these commands:

```sh
etcdctl member list
etcdctl cluster-health
```

Repeat these steps on each CoreOS host which has etcd member.

### Generate TLS keypairs

Follow [generate self signed certificates][self-signed-ca] doc to generate self-signed certificates.

### Copy Keypairs

Let's assume we have three CoreOS hosts with three etcd cluster members: server1, server2, server3 and corresponding IP addresses: 172.16.0.101, 172.16.0.102, 172.16.0.103. We will use following keypairs filenames in our example:

```
server1.pem
server1-key.pem
```

Copy your `ca.pem` CA certificate into `/etc/ssl/certs` directory and run `update-ca-certificates` script to update your certificates bundle.

Create `/etc/etcd2` directory, copy there corresponding certificate and key and set file permissions:

```
chown -R etcd:etcd /etc/etcd2/
chmod 600 /etc/etcd2/*-key.pem
```

Repeat this step on rest of the member nodes.

### Using etcd Proxy

If you typically connect to an etcd cluster at a remote location, it's recommended to use this opportunity to configure an [etcd proxy][etcd proxy] that handles the remote connection logic and TLS termination, and reconfigure your apps to communicate through the proxy on localhost. In this case you have to generate client keypair (i.e. `client1.pem` and `client1-key.pem`) and follow the previous step.

## Configure etcd Keypair

Now we should configure etcd paths to the new certificates. Create `/etc/systemd/system/etcd2.service.d/30-certs.conf` [drop-in][drop-ins] with contents below:

```
[Service]
Environment="ETCD_CERT_FILE=/etc/etcd2/server1.pem"
Environment="ETCD_KEY_FILE=/etc/etcd2/server1-key.pem"
Environment="ETCD_PEER_CERT_FILE=/etc/etcd2/server1.pem"
Environment="ETCD_PEER_KEY_FILE=/etc/etcd2/server1-key.pem"
```

Reload systemd config files `systemctl daemon-reload` and restart etcd2 `systemctl restart etcd2`. Then check your cluster health:

```sh
etcdctl member list
etcdctl cluster-health
```

If everything is ok, repeat this step on rest of the member nodes.

### Configure etcd Proxy

In the case of using an etcd proxy you have to use `/etc/systemd/system/etcd2.service.d/30-certs.conf` [drop-in][drop-ins] with the contents below:

```
[Service]
Environment="ETCD_CERT_FILE=/etc/etcd2/client1.pem"
Environment="ETCD_KEY_FILE=/etc/etcd2/client1-key.pem"
# listen only loopback interface for security reasons
Environment="ETCD_LISTEN_CLIENT_URLS=http://127.0.0.1:2379,http://127.0.0.1:4001"
```

Reload systemd config files `systemctl daemon-reload` and restart etcd2 `systemctl restart etcd2`. Then check proxy health: 

```sh
curl http://127.0.0.1:4001/v2/stats/self
```

## Change etcd Peer URLs

The command below should generate commands which you have to run manually on one of the member nodes:

```sh
etcdctl member list | awk -F'[: =]' '{print "curl -XPUT -H \"Content-Type: application/json\" http://localhost:2379/v2/members/"$1" -d \x27{\"peerURLs\":[\"https:"$7":"$8"\"]}\x27"}'
```

Output should look like:

```sh
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/2428639343c1baab -d '{"peerURLs":["https://172.16.0.102:2380"]}'
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/50da8780fd6c8919 -d '{"peerURLs":["https://172.16.0.103:2380"]}'
curl -XPUT -H "Content-Type: application/json" http://localhost:2379/v2/members/81901418ed658b78 -d '{"peerURLs":["https://172.16.0.101:2380"]}'
```

If you use etcd v2.2 or later, you can run this command:

```sh
etcdctl member list | awk -F'[: =]' '{print "etcdctl member update "$1" https:"$7":"$8}'
```

And its output will look like:

```sh
etcdctl member update 2428639343c1baab https://172.16.0.102:2380
etcdctl member update 50da8780fd6c8919 https://172.16.0.103:2380
etcdctl member update 81901418ed658b78 https://172.16.0.101:2380
```

You have to run each generated command on one of the member nodes and check etcd cluster health:

```sh
etcdctl member list
etcdctl cluster-health
```

If everything is ok we are ready to configure etcd members to use secure client URLs.

### etcd Proxy

In the case of using an etcd proxy, it should automatically update peer URLs after each URL change. It is recommended to wait 30 seconds (default `--proxy-refresh-interval 30000`) after each update as above.

## Change etcd Client URLs

Create `/etc/systemd/system/etcd2.service.d/40-tls.conf` [drop-in][drop-ins]:

```
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=https://172.16.0.101:2379"
Environment="ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379,http://127.0.0.1:4001"
Environment="ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380"
```

Reload systemd config files `systemctl daemon-reload` and restart etcd2 `systemctl restart etcd2`. Then check your cluster health already with certificates:

```sh
etcdctl --cert-file /etc/etcd2/server1.pem --key-file /etc/etcd2/server1-key.pem member list
etcdctl --cert-file /etc/etcd2/server1.pem --key-file /etc/etcd2/server1-key.pem cluster-health
```

or using environment variables:

```sh
export ETCDCTL_CERT_FILE=/etc/etcd2/server1.pem
export ETCDCTL_KEY_FILE=/etc/etcd2/server1-key.pem
etcdctl member list
etcdctl cluster-health
```

Check etcd status and availability of insecure local port:

```sh
systemctl status etcd2
curl http://127.0.0.1:4001/v2/stats/self
```

Check fleet and flannel:

```sh
journalctl -u flanneld -f
journalctl -u fleet -f
```

Error messages are fine for the last etcd restart but they should not appear again continuously.

If everything is ok, repeat this step on all your etcd member nodes.

[drop-ins]: /os/using-systemd-drop-in-units.md
[self-signed-ca]: /os/generate-self-signed-certificates.md
[etcd proxy]: https://github.com/coreos/etcd/blob/master/Documentation/proxy.md
