# Using environment variables in systemd units

## Environment directive

systemd has an Environment directive which sets environment variables for executed processes. It takes a space-separated list of variable assignments. This option may be specified more than once in which case all listed variables will be set. If the same variable is set twice, the later setting will override the earlier setting. If the empty string is assigned to this option, the list of environment variables is reset, all prior assignments have no effect. Environments directives are used in built-in CoreOS systemd units, for example in etcd2 and flannel.

With the example below, you can configure your etcd2 daemon to use encryption. Just create `/etc/systemd/system/etcd2.service.d/30-certificates.conf` [drop-in] for etcd2.service:

```
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

It is impossible to use scripts in Environment directive. So you can not dynamically define Environment, i.e. this doesn't work `Environment=/usr/bin/curl http://example.com/something`. When you need to update your environment values dynamically you can combine systemd service unit and EnvironmentFile directive.

For example in CoreOS `flanneld.service` unit file creates `/run/flannel_docker_opts.env` environment file which is used by `docker.service` unit to configure Docker use flannel interface. You can use similar example in your containers' unit files:

```
cat fleet_machines.service
[Unit]
Description=Generates /etc/fleet_machines.env file
After=etcd2.service
Requires=etcd2.service
After=fleet.service
Requires=fleet.service

[Service]
Type=oneshot
ExecStart=/usr/bin/sh -c "/usr/bin/echo -n FLEET_MACHINES= > /etc/fleet_machines.env"
ExecStart=/usr/bin/sh -c "/usr/bin/fleetctl list-machines -fields='ip,machine' -no-legend=true -full=true | tr '\t' '=' | tr '\n' ',' >> /etc/fleet_machines.env"
```

```
cat container.service
[Unit]
Description=My test Docker container
After=docker.service
Requires=docker.service
After=fleet_machines.service
Requires=fleet_machines.service

[Service]
EnvironmentFile=/etc/fleet_machines.env
ExecStartPre=-/usr/bin/docker kill %p
ExecStartPre=-/usr/bin/docker rm %p
ExecStartPre=/usr/bin/docker pull ubuntu:latest
ExecStart=/usr/bin/docker run --rm --name %p -e FLEET_MACHINES ubuntu:latest /bin/bash -c "trap 'exit 0' INT TERM; while true; do echo "$FLEET_MACHINES"; sleep 1; done"
```

## Other examples

### Use host IP addresses and EnvironmentFile

You can also write your host IP addresses into `/etc/network-environment` file using [this](https://github.com/kelseyhightower/setup-network-environment) utility. Then you can run your Docker containers following way:

```
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

```yaml
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
* `/etc/profile.env` will set environment variables for all users logged in CoreOS.

### etcd2.service unit advanced example

A [complete example][etcd-cluster-reconfiguration] of combining environment variables and systemd [drop-ins][drop-in] to reconfigure an existing machine running etcd.

## More systemd examples

For more systemd examples, check out these documents:

[Customizing Docker][customizing-docker]
[Customizing the SSH Daemon][customizing-sshd]
[Using systemd Drop-In Units][drop-in]
[etcd Cluster Runtime Reconfiguration on CoreOS][etcd-cluster-reconfiguration]

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
