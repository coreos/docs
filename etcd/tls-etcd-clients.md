# Configure CoreOS components to connect to etcd with TLS

This document explains how to configure CoreOS components to use secure HTTPS connections to an etcd cluster. The target etcd cluster must already be using HTTPS for its own communications, as explained in the [etcd HTTP to HTTPS migration guide][etcd-live-http-https].

The primary CoreOS components that use etcd are:

* [flannel][flannel]
* [fleet][fleet]
* [locksmith][locksmith]

This document assumes three CoreOS nodes are running three etcd cluster members: Call them server1, server2, and server3, with IP addresses 172.16.0.101, 172.16.0.102, and 172.16.0.103, respectively. We further assume that the [necessary Certificate Authority (CA) and client certificate/key pairs have been created][self-signed-ca].

## Configure flannel to Use secure etcd connection

The flannel systemd unit file reads the `/run/flannel/options.env` [environment][systemd-environments] file for configuration. `options.env` is created automatically by any [cloud-config][cloud-config] that contains a `flannel:` configuration section. For example, a cloud-config with the following contents:

```yaml
coreos:
  flannel:
    etcd_endpoints: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

will generate the following `/run/flannel/options.env`:

```ini
FLANNELD_ETCD_ENDPOINTS=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379
FLANNELD_ETCD_CAFILE=/etc/ssl/etcd/ca.pem
FLANNELD_ETCD_CERTFILE=/etc/ssl/etcd/client.pem
FLANNELD_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem
```

## Configure fleet to use secure etcd connection

The fleet systemd unit file reads `/run/systemd/system/fleet.service.d/20-cloudinit.conf` for configuration. `20-cloudinit.conf` is created by any [cloud-config][cloud-config] that contains a `fleet:` configuration section. For example, a cloud-config with the following contents:

```yaml
coreos:
  fleet:
    etcd_servers: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

will generate a [systemd drop-in][drop-ins] at `/run/systemd/system/fleet.service.d/20-cloudinit.conf` with these contents:

```ini
[Service]
Environment="FLEET_ETCD_CAFILE=/etc/ssl/etcd/ca.pem"
Environment="FLEET_ETCD_CERTFILE=/etc/ssl/etcd/client.pem"
Environment="FLEET_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem"
Environment="FLEET_ETCD_SERVERS=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
Environment="FLEET_METADATA=hostname=server1"
Environment="FLEET_PUBLIC_IP=172.16.0.101"
```

## Configure Locksmith to use secure etcd connection

Example cloud-config excerpt for Locksmith configuration:

```yaml
coreos:
  locksmith:
    endpoint: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

This results in a systemd drop-in file
`/run/systemd/system/locksmithd.service.d/20-cloudinit.conf` that looks like:

```ini
[Service]
Environment="LOCKSMITHD_ETCD_CAFILE=/etc/ssl/etcd/ca.pem"
Environment="LOCKSMITHD_ETCD_CERTFILE=/etc/ssl/etcd/client.pem"
Environment="LOCKSMITHD_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem"
Environment="LOCKSMITHD_ENDPOINT=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
```

## Remove legacy etcd ports configuration

Once all etcd clients are configured to use secure ports, the insecure legacy configuration can be disabled. If you've followed the [etcd Live HTTP to HTTPS migration][etcd-live-http-https] guide, it is now necessary to edit `/etc/systemd/system/etcd2.service.d/40-tls.conf` to remove the value `http://127.0.0.1:4001` from the `ETCD_LISTEN_CLIENT_URLS` environment variable. The edited `40-tls.conf` should end up looking like:

```ini
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=https://172.16.0.101:2379"
Environment="ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379"
Environment="ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380"
```

Then, as usual after a systemd configuration change, run `systemctl daemon-reload` and `systemctl restart etcd2`. Check the etcd logs to ensure your configuration is valid with a quick `journalctl -t etcd2 -f`.

[drop-ins]: ../os/using-systemd-drop-in-units.md
[self-signed-ca]: ../os/generate-self-signed-certificates.md
[locksmith]: https://github.com/coreos/locksmith
[flannel]: https://github.com/coreos/flannel
[fleet]: https://github.com/coreos/fleet
[systemd-environments]: ../os/using-environment-variables-in-systemd-units.md
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[etcd-live-http-https]: etcd-live-http-to-https-migration.md
