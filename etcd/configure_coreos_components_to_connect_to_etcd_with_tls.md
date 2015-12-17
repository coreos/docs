# Configure CoreOS Components to Connect to etcd with TLS

This document explains how to configure all CoreOS components to use secure HTTPS connections to an etcd cluster. The target etcd cluster must already be using HTTPS for its own communications, as explained in the [tcd HTTP to HTTPS migration guide][etcd-live-http-https]

The main CoreOS components that use etcd are:

* [flannel][flannel]
* [fleet][fleet]
* [locksmith][locksmith]

We assume that we have three CoreOS hosts with three etcd cluster members: server1, server2, server3 and corresponding IP addresses: 172.16.0.101, 172.16.0.102, 172.16.0.103. And we assume that we've already [created client keypairs][self-signed-ca] and CA certificate (`ca.pem`, `client.pem` and `client-key.pem`):

## Configure Flannel to Use Secure etcd Connection

Flannel systemd unit file uses `/run/flannel/options.env` [environemnt][systemd-environments] file which is created automatically by [Cloud-Config][cloud-config] in case when it has configured flannel section. For example the Cloud-Config file with the following contents:

```yaml
coreos:
  flannel:
    etcd_endpoints: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

will generate following `/run/flannel/options.env`:

```ini
FLANNELD_ETCD_ENDPOINTS=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379
FLANNELD_ETCD_CAFILE=/etc/ssl/etcd/ca.pem
FLANNELD_ETCD_CERTFILE=/etc/ssl/etcd/client.pem
FLANNELD_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem
```

If you don't want to use cloud-config in some case you can create environment file manually and save it on persistent storage (`/run` directory is recreated every boot) for example `/etc/flannel.env` path. To make flannel read this path instead of default one please use this [drop-in][drop-ins]:

```ini
[Service]
Environment="FLANNEL_ENV_FILE=/etc/flannel.env"
```

and save it by the following path `/etc/systemd/system/flanneld.service.d/10-custom_env.conf`, then run `systemctl daemon-reload` and `systemctl restart flanneld`. Check flannel logs using `journalctl -u flanneld -f`.

## Configure Fleet to Use Secure etcd Connection

To configure fleet you can also use both ways: Cloud-Config and drop-ins. In case of Cloud-Config please use this example:

```yaml
coreos:
  fleet:
    etcd_servers: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

An example above will generate `/run/systemd/system/fleet.service.d/20-cloudinit.conf` drop-in with the contents below:

```ini
[Service]
Environment="FLEET_ETCD_CAFILE=/etc/ssl/etcd/ca.pem"
Environment="FLEET_ETCD_CERTFILE=/etc/ssl/etcd/client.pem"
Environment="FLEET_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem"
Environment="FLEET_ETCD_SERVERS=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
Environment="FLEET_METADATA=hostname=server1"
Environment="FLEET_PUBLIC_IP=172.16.0.101"
```

You are free to store this drop-in by the `/etc/systemd/system/fleet.service.d/10-custom_env.conf` path manually as well. Then you have to run `systemctl daemon-reload` and `kill -9 $(pidof fleetd); systemctl restart fleet` (using `kill -9` we will avoid fleet units restart). Check fleet logs using `journalctl -u fleet -f`.

## Configure Locksmith to Use Secure etcd Connection

Example for the locksmith configuration:

```yaml
coreos:
  locksmith:
    endpoint: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
    etcd_cafile: /etc/ssl/etcd/ca.pem
    etcd_certfile: /etc/ssl/etcd/client.pem
    etcd_keyfile: /etc/ssl/etcd/client-key.pem
```

`/run/systemd/system/locksmithd.service.d/20-cloudinit.conf`

```ini
[Service]
Environment="LOCKSMITHD_ETCD_CAFILE=/etc/ssl/etcd/ca.pem"
Environment="LOCKSMITHD_ETCD_CERTFILE=/etc/ssl/etcd/client.pem"
Environment="LOCKSMITHD_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem"
Environment="LOCKSMITHD_ENDPOINT=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
```

## Remove Legacy Insecure etcd Ports Configuration

Once we've configured all our etcd based components to use secure ports we can disable legacy insecure configuration. If you've followed [etcd Live HTTP to HTTPS migration][etcd-live-http-https] doc we have to alter `/etc/systemd/system/etcd2.service.d/40-tls.conf` and remove `http://127.0.0.1:4001` value from `ETCD_LISTEN_CLIENT_URLS` env variable. As a result this file should look as follows:

```ini
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=https://172.16.0.101:2379"
Environment="ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379"
Environment="ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380"
```

then run `systemct daemon-reload` and `systemctl restart etcd2`. Please check etcd logs to make sure your configuration is valid: `journalctl -t etcd2 -f`.

[drop-ins]: /os/using-systemd-drop-in-units.md
[self-signed-ca]: /os/generate-self-signed-certificates.md
[locksmith]: https://github.com/coreos/locksmith
[flannel]: https://github.com/coreos/flannel
[fleet]: https://github.com/coreos/fleet
[systemd-environments]: /os/using-environment-variables-in-systemd-units.md
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[etcd-live-http-https]: etcd-live-http-to-https-migration.md
