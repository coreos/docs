# Using environment variables in systemd units

## Environment directive

systemd has an Environment directive which sets environment variables for executed processes. It takes a space-separated list of variable assignments. This option may be specified more than once in which case all listed variables will be set. If the same variable is set twice, the later setting will override the earlier setting. If the empty string is assigned to this option, the list of environment variables is reset, all prior assignments have no effect. Environments directives are used in built-in Container Linux systemd units, for example in etcd2 and flannel.

With the example below, you can configure your etcd2 daemon to use encryption. Just create `/etc/systemd/system/etcd2.service.d/30-certificates.conf` [drop-in] for etcd2.service:

```ini
[Service]
# Client Env Vars
Environment=ETCD_CA_FILE=/path/to/CA.pem
Environment=ETCD_CERT_FILE=/path/to/server.crt
Environment=ETCD_KEY_FILE=/path/to/server.key
# Peer Env Vars
Environment=ETCD_PEER_CA_FILE=/path/to/CA.pem
Environment=ETCD_PEER_CERT_FILE=/path/to/peers.crt
Environment=ETCD_PEER_KEY_FILE=/path/to/peers.key
```

Then run `sudo systemctl daemon-reload` and `sudo systemctl restart etcd2.service` to apply new environments to etcd2 daemon. You can read more about etcd2 certificates [here][customizing-etcd].

## EnvironmentFile directive

EnvironmentFile similar to Environment directive but reads the environment variables from a text file. The text file should contain new-line-separated variable assignments.

For example, in Container Linux, the `coreos-metadata.service` service creates `/run/metadata/coreos`. This environment file can be included by other services in order to inject dynamic configuration. Here's an example of the environment file when run on DigitalOcean (the IP addresses have been removed):

```
COREOS_DIGITALOCEAN_IPV4_ANCHOR_0=X.X.X.X
COREOS_DIGITALOCEAN_IPV4_PRIVATE_0=X.X.X.X
COREOS_DIGITALOCEAN_HOSTNAME=test.example.com
COREOS_DIGITALOCEAN_IPV4_PUBLIC_0=X.X.X.X
COREOS_DIGITALOCEAN_IPV6_PUBLIC_0=X:X:X:X:X:X:X:X
```

This environment file can then be sourced and its variables used. Here is an example drop-in for `etcd-member.service` which starts `coreos-metadata.service` and then uses the generated results:

```ini
[Unit]
Requires=coreos-metadata.service
After=coreos-metadata.service

[Service]
EnvironmentFile=/run/metadata/coreos
ExecStart=
ExecStart=/usr/bin/etcd2 \
  --advertise-client-urls=http://${COREOS_DIGITALOCEAN_IPV4_PUBLIC_0}:2379 \
  --initial-advertise-peer-urls=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2380 \
  --listen-client-urls=http://0.0.0.0:2379 \
  --listen-peer-urls=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2380 \
  --initial-cluster=%m=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2380
```

## Other examples

### Use host IP addresses and EnvironmentFile

You can also write your host IP addresses into `/etc/network-environment` file using [this](https://github.com/kelseyhightower/setup-network-environment) utility. Then you can run your Docker containers following way:

```ini
[Unit]
Description=Nginx service
Requires=etcd2.service
After=etcd2.service
[Service]
# Get network environmental variables
EnvironmentFile=/etc/network-environment
ExecStartPre=-/usr/bin/docker kill nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=/usr/bin/docker pull nginx
ExecStartPre=/usr/bin/etcdctl set /services/nginx '{"host": "%H", "ipv4_addr": ${DEFAULT_IPV4}, "port": 80}'
ExecStart=/usr/bin/docker run --rm --name nginx -p ${DEFAULT_IPV4}:80:80 nginx
ExecStop=/usr/bin/docker stop nginx
ExecStopPost=/usr/bin/etcdctl rm /services/nginx
```

This unit file will run nginx Docker container and bind it to specific IP address and port.

### System wide environment variables

You can define system wide environment variables using [cloud-config] as explained below:

```cloud-config
#cloud-config

write_files:
  - path: "/etc/systemd/system.conf.d/10-default-env.conf"
    content: |
      [Manager]
      DefaultEnvironment=HTTP_PROXY=http://192.168.0.1:3128
  - path: "/etc/profile.env"
    content: |
      export HTTP_PROXY=http://192.168.0.1:3128
```

or using [Ignition][ignition]:

```json
{
  "ignition": { "version": "2.0.0" },
  "files": [
    {
      "filesystem": "root",
      "path": "/etc/systemd/system.conf.d/10-default-env.conf",
      "contents": { "source": "data:,[Manager]\nDefaultEnvironment=HTTP_PROXY=http://192.168.0.1:3128" }
    },
    {
      "filesystem": "root",
      "path": "/etc/profile.env",
      "contents": { "source": "data:,export%20HTTP_PROXY=http://192.168.0.1:3128" }
    }
  ]
}
```

Where:

* `/etc/systemd/system.conf.d/10-default-env.conf` config file will set default environment variables for all systemd units.
* `/etc/profile.env` will set environment variables for all users logged in Container Linux.

### etcd2.service unit advanced example

A [complete example][etcd-cluster-reconfiguration] of combining environment variables and systemd [drop-ins][drop-in] to reconfigure an existing machine running etcd.

## More systemd examples

For more systemd examples, check out these documents:

[Customizing Docker][customizing-docker]
[Customizing the SSH Daemon][customizing-sshd]
[Using systemd Drop-In Units][drop-in]
[etcd Cluster Runtime Reconfiguration on Container Linux][etcd-cluster-reconfiguration]

[drop-in]: using-systemd-drop-in-units.md
[customizing-sshd]: customizing-sshd.md#changing-the-sshd-port
[customizing-etcd]: customize-etcd-unit.md
[customizing-docker]: customizing-docker.md#using-a-dockercfg-file-for-authentication
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[etcd-discovery]: cluster-discovery.md
[systemd-udev]: using-systemd-and-udev-rules.md
[etcd-cluster-reconfiguration]: ../etcd/etcd-live-cluster-reconfiguration.md
[ignition]: https://github.com/coreos/ignition/blob/master/doc/getting-started.md

## More Information

<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.exec.html">systemd.exec Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
