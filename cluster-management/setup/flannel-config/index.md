---
layout: docs
title: Configuring flannel Networking
category: cluster_management
sub_category: setting_up
weight: 10
---

# Configuring flannel for Container Networking

*Note*: flannel is only available in [CoreOS versions 554]({{site.url}}/releases/#554.0.0) and later.

## Overview

With Docker, each container is assigned an IP address that can be used to communicate with other containers on the _same_ host.
For communicating over a network, containers are tied to the IP addresses of the host machines and must rely on port-mapping to reach the desired container.
This makes it difficult for applications running inside containers to advertise their external IP and port as that information is not available to them.

flannel solves the problem by giving each container an IP that can be used for container-to-container communication. It uses packet encapsulation
to create a virtual overlay network that spans the whole cluster. More specifically, flannel gives each host an IP subnet (/24 by default) from which the
Docker daemon is able to allocate IPs to the individual containers.

flannel uses [etcd](https://coreos.com/using-coreos/etcd/) to store mappings between the virtual IP and host addresses. A `flanneld` daemon runs on each
host and is responsible for watching information in etcd and routing the packets.

## Configuration

### Publishing config to etcd
flannel looks up its configuration in etcd. Therefore the first step to getting started with flannel is to publish the configuration to etcd.
By default, flannel looks up its configuration in `/coreos.com/network/config`. At the bare minimum, you must tell flannel an IP range (subnet) that
it should use for the overlay. Here is an example of the minimum flannel configuration:

```json
{ "Network": "10.1.0.0/16" }
```

Use `etcdctl` utility to publish the config:

```bash
$ etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
```

You can put this into a drop-in for flanneld.service via cloud-config:

```yaml
#cloud-config

coreos:
  units:
    - name: flanneld.service
      drop-ins:
        - name: 50-network-config.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
```

This will assign the specified /16 for the entire overlay network. By default, flannel will allocate a /24 to each host. This default, along with the
minimum and maximum subnet IP addresses is overridable in config:

```json
{
	"Network": "10.1.0.0/16",
	"SubnetLen": 28,
	"SubnetMin": "10.1.10.0",
	"SubnetMax": "10.1.50.0"
}
```

This config instructs flannel to allocate /28 subnets to individual hosts and make sure not to issue subnets outside of 10.1.10.0 - 10.1.50.0 range.

### Firewall

flannel uses UDP port 8285 for sending encapsulated IP packets. Make sure to enable this traffic to pass between the hosts. If you find that you can't ping containers across hosts, this port is probably not open.

### Enabling flannel via Cloud-Config
The last step is to enable `flanneld.service` in the cloud-config by adding `command: start` directive:

```yaml
#cloud-config

coreos:
  units:
    - name: flanneld.service
      drop-ins:
        - name: 50-network-config.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
      command: start

    # Example service running in a Docker container
    - name: redis.service
      content: |
        [Unit]
        Requires=flanneld.service
        After=flanneld.service

        [Service]
        ExecStart=/usr/bin/docker run redis
        Restart=always
      command: start
```

*Important*: If you are starting other units via cloud-config, `flanneld.service` needs to be listed _before_ any services that run Docker containers.
In addition, other units that will run in containers, including those scheduled via fleet, should include `Requires=flanneld.service`, `After=flanneld.service`, and `Restart=always|on-failure` directives.
These directive are necessary because flanneld.service may fail due to etcd not being available yet. It will keep restarting and it is important for Docker based services to also keep trying until flannel is up.

*Important*: If you are starting flannel on Vagrant, it should be instructed to use the correct network interface:

```yaml
#cloud-config

coreos:
  flannel:
    interface: $public_ipv4
```

## Under the Hood
To reduce the CoreOS image size, flannel daemon is stored in CoreOS Enterprise Registry as a Docker container and not shipped in the CoreOS image.
For those users wishing not to use flannel, it helps to keep their installation minimal. When `flanneld.service` it started, it pulls the Docker image
from the registry. There is, however, a chicken and the egg problem as flannel configures Docker bridge and Docker is needed to pull down the image.

In order to work around this, CoreOS is configured to optionally run a second copy of Docker daemon which we call early-docker. Early-docker daemon
is started with `--iptables=false` and containers that it executes need to run with host networking. This prevents Docker from starting `docker0` bridge.

Here is the sequence of events that happens when `flanneld.service` is started followed by a service that runs a Docker container (e.g. redis server):

1. `early-docker.service` gets started since it is a dependency of `flanneld.service`.
2. `early-docker.service` launches a Docker on a separate Unix socket &mdash; `/var/run/early-docker.sock`.
3. `flanneld.service` executes `DOCKER_HOST=unix:///var/run/early-docker.sock docker run --net=host quay.io/coreos/flannel:$FLANNEL_VER` (actual invocation is slightly more complex).
4. flanneld starts and writes out `/run/flannel/subnet.env` with the acquired IP subnet information.
5. `ExecStartPost` in `flanneld.service` converts information in `/run/flannel/subnet.env` into Docker daemon command line args (such as `--bip` and `--mtu`),
storing them in `/run/flannel_docker_opts.env`
6. `redis.service` gets started which invokes `docker run ...`, triggering socket activation of `docker.service`.
7. `docker.service` sources in `/run/flannel_docker_opts.env` which contains env variables with command line options and starts the Docker with them.
8. `redis.service` runs Docker redis container.

If you would like to learn more about these service files, you can check them out like so: `systemctl cat early-docker.service`.
