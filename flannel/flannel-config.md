# Configuring flannel for container networking

## Overview

With Docker, each container is assigned an IP address that can be used to communicate with other containers on the _same_ host. For communicating over a network, containers are tied to the IP addresses of the host machines and must rely on port-mapping to reach the desired container. This makes it difficult for applications running inside containers to advertise their external IP and port as that information is not available to them.

flannel solves the problem by giving each container an IP that can be used for container-to-container communication. It uses packet encapsulation to create a virtual overlay network that spans the whole cluster. More specifically, flannel gives each host an IP subnet (/24 by default) from which the Docker daemon is able to allocate IPs to the individual containers.

flannel uses [etcd](https://coreos.com/using-coreos/etcd/) to store mappings between the virtual IP and host addresses. A `flanneld` daemon runs on each host and is responsible for watching information in etcd and routing the packets.

## Configuration

### Publishing config to etcd

flannel looks up its configuration in etcd. Therefore the first step to getting started with flannel is to publish the configuration to etcd. By default, flannel looks up its configuration in `/coreos.com/network/config`. At the bare minimum, you must tell flannel an IP range (subnet) that it should use for the overlay. Here is an example of the minimum flannel configuration:

```json
{ "Network": "10.1.0.0/16" }
```

Use `etcdctl` utility to publish the config:

```bash
$ etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
```

You can put this into a drop-in for flanneld.service via a Container Linux Config:

```yaml container-linux-config
systemd:
  units:
    - name: flanneld.service
      dropins:
        - name: 50-network-config.conf
          contents: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
```

This config instructs flannel to allocate /28 subnets to individual hosts and make sure not to issue subnets outside of 10.1.10.0 - 10.1.50.0 range.

### Firewall

flannel uses UDP port 8285 for sending encapsulated IP packets. Make sure to enable this traffic to pass between the hosts. If you find that you can't ping containers across hosts, this port is probably not open.

### Enabling flannel via a Container Linux Config

The last step is to enable `flanneld.service` by creating the `flannel` section in our Container Linux Config. Options for flannel can be specified in this section.

```yaml container-linux-config
flannel: ~
```

*Important*: Other units that will run in containers, including those scheduled via fleet, should include `Requires=flanneld.service`, `After=flanneld.service`, and `Restart=always|on-failure` directives. These directive are necessary because flanneld.service may fail due to etcd not being available yet. It will keep restarting and it is important for Docker based services to also keep trying until flannel is up.

### Specifying SSL certificates

Flannel requires SSL certificates to communicate with a secure etcd cluster. By default, flannel looks for these certificates in `/etc/ssl/etcd`. To use different certificates, add `Environment=ETCD_SSL_DIR` to a drop-in file for `flanneld.service`. Use the following configuration snippet to achieve this:

```yaml container-linux-config
systemd:
  units:
    - name: flanneld.service
      dropins:
        - name: 50-ssl.conf
          contents: |
            [Service]
            Environment=ETCD_SSL_DIR=/etc/ssl
```

## Under the hood

To reduce the Container Linux image size, flannel daemon is stored in CoreOS Enterprise Registry as an ACI and not shipped in the Container Linux image. For those users wishing not to use flannel, it helps to keep their installation minimal. When `flanneld.service` is started, it pulls the flannel ACI from the registry.

Here is the sequence of events that happens when `flanneld.service` is started followed by a service that runs a Docker container (e.g. redis server):

1. `flanneld.service` gets started and executes `/usr/bin/rkt run --net=host quay.io/coreos/flannel:$FLANNEL_VER` (the actual invocation is slightly more complex; the full version can be seen [here](https://github.com/coreos/coreos-overlay/blob/master/app-admin/flannel/files/flanneld.service) or by running `systemctl cat flanneld.service`, which also includes any drop in units).
2. flanneld starts and writes out `/run/flannel/subnet.env` with the acquired IP subnet information.
3. `ExecStartPost` in `flanneld.service` converts information in `/run/flannel/subnet.env` into Docker daemon command line args (such as `--bip` and `--mtu`), storing them in `/run/flannel/flannel_docker_opts.env`.
4. `redis.service` gets started which invokes `docker run ...`, triggering socket activation of `docker.service`.
5. `docker.service` sources in `/run/flannel/flannel_docker_opts.env` which contains env variables with command line options and starts the Docker with them.
6. `redis.service` runs Docker redis container.
