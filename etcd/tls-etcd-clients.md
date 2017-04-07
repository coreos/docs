# Configure CoreOS Container Linux components to connect to etcd with TLS

This document explains how to configure Container Linux components to use secure HTTPS connections to an etcd cluster. The target etcd cluster must already be using HTTPS for its own communications, as explained in the [etcd HTTP to HTTPS migration guide][etcd-live-http-https].

The primary Container Linux components that use etcd are:

* [flannel][flannel]
* [fleet][fleet]
* [locksmith][locksmith]

This document assumes three Container Linux nodes will be booted and will be running three etcd cluster members: Call them server1, server2, and server3, with IP addresses 172.16.0.101, 172.16.0.102, and 172.16.0.103, respectively. We further assume that the [necessary Certificate Authority (CA) and client certificate/key pairs have been created][self-signed-ca].

## Configure flannel to Use secure etcd connection

Flannel options can be specified in a Container Linux Config. For an example, this is a config that sets the etcd endpoints flannel will use and specifies tls resources to encrypt the connection:

```container-linux-config
flannel:
  etcd_endpoints: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
  etcd_cafile:    /etc/ssl/etcd/ca.pem
  etcd_certfile:  /etc/ssl/etcd/client.pem
  etcd_keyfile:   /etc/ssl/etcd/client-key.pem
```

If you're going to use a directory other than `/etc/ssl/etcd` to store etcd client certificates, you will need to update `flanneld.service` with your custom folder.  This is because flanneld.service is running as a container.

Suppose you're using `/etc/etcd/ssl` instead, you will need to adjust the flanneld.service drop in to set an updated `ETCD_SSL_DIR` environmental variable.
 
A complete example would look like:

```container-linux-config
flannel:
  etcd_endpoints: "https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
  etcd_cafile:    /etc/ssl/etcd/ca.pem
  etcd_certfile:  /etc/ssl/etcd/client.pem
  etcd_keyfile:   /etc/ssl/etcd/client-key.pem
systemd:
  units:
    - name: flanneld.service
      dropins:
        - name: 50-network-config.conf
          contents: |
            Environment="ETCD_SSL_DIR=/etc/etcd/ssl"
```

## Configure fleet to use secure etcd connection

Due to the [deprecation of fleet][fleet-deprecation], Container Linux Configs don't have a convenient syntax for configuring fleet like for flannel. Fleet can still be easily configured however with the use of a systemd drop-in.

```container-linux-config
systemd:
  units:
    - name: fleet.service
      dropins:
        - name: 20-fleet-config.conf
          contents: |
            [Service]
            Environment="FLEET_ETCD_CAFILE=/etc/ssl/etcd/ca.pem"
            Environment="FLEET_ETCD_CERTFILE=/etc/ssl/etcd/client.pem"
            Environment="FLEET_ETCD_KEYFILE=/etc/ssl/etcd/client-key.pem"
            Environment="FLEET_ETCD_SERVERS=https://172.16.0.101:2379,https://172.16.0.102:2379,https://172.16.0.103:2379"
            Environment="FLEET_METADATA=hostname=server1"
            Environment="FLEET_PUBLIC_IP=172.16.0.101"
```

## Configure Locksmith to use secure etcd connection

Example Container Linux Config excerpt for Locksmith configuration:

```container-linux-config
systemd:
  units:
    - name: locksmithd.service
      dropins:
        - name: 20-locksmithd-config.conf
          contents: |
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
[etcd-live-http-https]: etcd-live-http-to-https-migration.md
[fleet-deprecation]: https://coreos.com/blog/migrating-from-fleet-to-kubernetes.html
