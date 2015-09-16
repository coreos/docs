# Using Environment Variables In systemd Units

## Environment directive

Systemd has Environment directive which sets environment variables for executed processes. It takes a space-separated list of variable assignments. This option may be specified more than once in which case all listed variables will be set. If the same variable is set twice, the later setting will override the earlier setting. If the empty string is assigned to this option, the list of environment variables is reset, all prior assignments have no effect. Environments directives are used in built-in CoreOS systemd units, for example in etcd2 and flannel.

With example below you can configure your etcd2 daemon to use encryption. Just create `/etc/systemd/system/etcd2.service.d/30-certificates.conf` [drop-in] for etcd2.service:

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

Then run `sudo systemctl daemon-reload` and `sudo systemct restart etcd2.service` to apply new environments to etcd2 daemon. You can read more about etcd2 certificates [here](customize-etcd-unit.html).

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
Description=My test docker container
After=docker.service
Requires=docker.service
After=fleet_machines.service
Requires=fleet_machines.service

[Service]
EnvironmentFile=/etc/fleet_machines.env
ExecStartPre=-/usr/bin/docker kill %p
ExecStartPre=-/usr/bin/docker rm %p
ExecStartPre=/usr/bin/docker pull ubuntu:latest
ExecStart=/usr/bin/docker run --rm --name %p -e FLEET_MACHINES ubuntu:latest bash -c 'while true; do echo "$FLEET_MACHINES"; sleep 1; done'
```

## Another Examples

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

This unit file will run nginx docker container and bind it to specific IP address and port.

### etcd2.service Unit Advanced Example

Let's review another etcd2.service [drop-in] unit example. [Cloud-config][cloud-config] compiles special `/run/systemd/system/etcd2.service.d/20-cloudinit.conf` [drop-in] unit file using options defined in "etcd2:" yaml section: 

```
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=http://10.0.1.10:2379"
Environment="ETCD_DISCOVERY=https://discovery.etcd.io/<token>"
Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=http://10.0.1.10:2380"
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://0.0.0.0:4001"
Environment="ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380"
```

For example you have created five-nodes CoreOS cluster but have forgot to set cluster size in [discovery][etcd-discovery] URL and its cluster size is three by default. Your rest two nodes became proxy and you would like to convert them to etcd2 member.

You can solve this problem without new cluster bootstrapping. Run `etcdctl member add node4 http://10.0.1.13:2380` and remember its output (we will use it later):

```
added member 9bf1b35fc7761a23 to cluster

ETCD_NAME="node4"
ETCD_INITIAL_CLUSTER="node1=http://10.0.1.10:2380,node2=http://10.0.1.11:2380,node3=http://10.0.1.12:2380,node4=http://10.0.1.13:2380"
ETCD_INITIAL_CLUSTER_STATE=existing
```

Already defined in `20-cloudinit.conf` `ETCD_DISCOVERY` conflicts with `ETCD_INITIAL_CLUSTER` environment variable, so we have to clean it. We can do that overriding `20-cloudinit.conf` by `99-restore.conf` drop-in with the `Environment="ETCD_DISCOVERY="` string.

The complete example will look this way. On `node4` CoreOS host create temporarily systemd drop-in unit `/run/systemd/system/etcd2.service.d/99-restore.conf` with the content below (we use variables from `etcdctl member add` output):

```
[Service]
# remove previously created proxy directory
ExecStartPre=/usr/bin/rm -rf /var/lib/etcd2/proxy
# here we clean previously defined ETCD_DISCOVERY environment variable, we don't need it as we've already bootstrapped etcd cluster and ETCD_DISCOVERY conflicts with ETCD_INITIAL_CLUSTER environment variable
Environment="ETCD_DISCOVERY="
Environment="ETCD_NAME=node4"
Environment="ETCD_INITIAL_CLUSTER=node1=http://10.0.1.10:2380,node2=http://10.0.1.11:2380,node3=http://10.0.1.12:2380,node4=http://10.0.1.13:2380"
Environment="ETCD_INITIAL_CLUSTER_STATE=existing"
```

Run `sudo systemctl daemon-reload` and `sudo systemctl restart etcd2` to apply your changes. You will see that your proxy node became cluster member:

```
etcdserver: start member 9bf1b35fc7761a23 in cluster 36cce781cb4f1292
```

Once your proxy node became member node and `etcdctl cluster-health` shows healthy cluster, you can remove your temporarily drop-in `sudo rm /run/systemd/system/etcd2.service.d/99-restore.conf && sudo systemctl daemon-reload`.

## More systemd Examples

For more systemd examples, check out these documents:

[Customizing Docker][customizing-docker]
[Customizing the SSH Daemon][customizing-sshd]
[Using systemd Drop-In Units][drop-in]

[drop-in]: using-systemd-drop-in-units.html
[customizing-sshd]: customizing-sshd.html#changing-the-sshd-port
[customizing-docker]: customizing-docker.html#using-a-dockercfg-file-for-authentication
[cloud-config]: cloud-config.html
[etcd-discovery]: cluster-discovery.html
[systemd-udev]: using-systemd-and-udev-rules.html

## More Information
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.exec.html">systemd.exec Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
