# CoreOS Container Linux cluster architectures

## Overview

Depending on the size and expected use of your Container Linux cluster, you will have different architectural requirements. A few of the common cluster architectures, as well as their strengths and weaknesses, are described below.

Most of these scenarios dedicate a few machines, physical hardware of virtual machines, to running central cluster services. These may include etcd and the distributed controllers for applications like Kubernetes, Mesos, and OpenStack. Excluding these services onto a few known machines helps to ensure they are distributed across cabinets/availability zones. It also helps in setting up static networking to allow for easy bootstrapping. If you're concerned about relying on a discovery service, this architecture helps resolve a lot of those problems.

## Docker dev environment on laptop

<img class="img-center" src="img/laptop.png" alt="Laptop Environment Diagram"/>
<div class="caption">Laptop development environment with Container Linux VM</div>

| Cost | Great For          | Set Up Time | Production |
|------|--------------------|-------------|------------|
| Low  | Laptop development | Minutes     | No         |

If you're developing locally but plan to run containers in production, it's best practice to mirror that environment locally. This can easily be done by running Docker commands on your laptop that control a Container Linux VM in VMware Fusion or VirtualBox.

### Configuring your laptop

Start a single Container Linux VM with the Docker remote socket enabled in the Container Linux config. Here's what the cloud-config looks like:

```yaml
systemd:
  units:
    - name: docker-tcp.socket
      enable: yes
      mask: false
      contents: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
    - name: enable-docker-tcp.service
      enable: true
      contents: |
        [Unit]
        Description=Enable the Docker Socket for the API

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl enable docker-tcp.socket
```

This file is used to provision your local CoreOS machine on it's first boot. It enables the docker sets up and enables the docker socket in systemd.

Using the Container Linux Config Transpiler, or `ct`, ([download][ct-getting-started]) convert the above yaml into an [ignition][ignition-getting-started]. Once you have the ignition configuration file, pass it to your provider ([complete list of supported ignition platforms][ignition-supported]).

Once the local VM is running, tell your Docker binary to use the remote port by exporting an environment variable and start running Docker commands:

```
$ export DOCKER_HOST=tcp://localhost:2375
$ docker ps
```

This avoids potentially breaking differences between your local development environment and where the container will *actually* run in production.

### Related local installation tools

There are a myriad of alternative solutions for testing CoreOS locally:

- [coreos-vagrant][coreos-vagrant] is not an officially fully supported platform, however may be a good resource to check out if you are already comfortable with Vagrant and are unable to use one of ignition's officially supported platforms.
- [coreos-kubernetes][coreos-kubernetes] provides resources to run a local Kubernetes cluster with one or more nodes provisioned by Vagrant.
- [Minikube][minikube] is used for local Kubernetes development. This does not use CoreOS but is very fast to setup and is the easiest way to test-drive use Kubernetes.

## Small cluster

<img class="img-center" src="img/small.png" alt="Small Container Linux Cluster Diagram"/>
<div class="caption">Small Container Linux cluster running etcd on all machines</div>

| Cost | Great For                                  | Set Up Time | Production |
|------|--------------------------------------------|-------------|------------|
| Low  | Small clusters, trying out Container Linux | Minutes     | Yes        |

For small clusters, between 3-9 machines, running etcd on all of the machines allows for high availability without paying for extra machines that just run etcd.

Getting started is easy &mdash; a single Container Linux config can be used to provision all machines on your cloud-provider.

### Configuring the machines

Following the guide for each of the [supported platforms](https://coreos.com/docs#running-coreos) will be the easiest way to get started with this architecture. Boot the desired number of machines with the same Container Linux config and discovery token. The Container Linux config specifies that etcd and other services will be started on each machine.

## Easy development/testing cluster

<img class="img-center" src="img/dev.png" alt="Container Linux cluster optimized for development and testing"/>
<div class="caption">Container Linux cluster optimized for development and testing</div>

| Cost | Great For | Set Up Time | Production |
|------|-----------|-------------|------------|
| Low | Development/Testing | Minutes | No |

When getting started with Container Linux, you may find yourself booting/rebooting/destroying many machines. Instead of slowing down and distracting yourself, generating new discovery URLs and bootstrapping etcd. Instead, start a single etcd node and build your cluster around that.

You can now boot as many machines as you'd like as test workers that read from the etcd node. All the features of Locksmith and etcdctl will continue to work properly but will connect to the etcd node instead of using a local etcd instance. Since etcd isn't running on all of the machines you'll gain a little bit of extra CPU and RAM to play with.

Once this environment is set up, it'll be ready to take a beating. Pull the plug on a machine and watch Kubernetes reschedule the units, max out the CPU, etc.

### Configuration for etcd role

Since we're only using a single etcd node, there is no need to include a discovery token. There isn't any high availability for etcd in this configuration, but that's assumed to be OK for development and testing. Boot this machine first so you can configure the rest with its IP address, which is specified with the network unit.

The network unit is typically used for bare metal installations that require static networking. Check the documentation for your specific provider for examples.

Here's the Container Linux config for the etcd machine:

```yaml
etcd:
  version: 3.1.5
  name: "etcdserver"
  initial_cluster: "etcdserver=http://10.0.0.101:2380"
  initial_advertise_peer_urls: "http://10.0.0.101:2380"
  advertise_client_urls: "http://10.0.0.101:2379'
  listen_client_urls: "http://0.0.0.0:2379,http://0.0.0.0:4001"
  listen_peer_urls: "http://0.0.0.0:2380"
systemd:
  units:
    - name: etcd-member.service
      enable: true
      dropins:
        - name: conf1.conf
          contents: |
            [Service]
            Environment="ETCD_NAME=etcdserver"
networkd:
  units:
    - name: 00-eth0.network
      enable: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=1.2.3.4
        Address=10.0.0.101/24
        Gateway=10.0.0.1
```

### Configuration for worker role

This architecture allows you to boot any number of workers, as few as 1 or up to a large cluster for load testing. The notable configuration difference for this role is specifying that applications like Kubernetes should use our etcd proxy instead of starting etcd server locally.

The Container Linux config:

```
<<< ADD CONTAINER LINUX CONFIG >>>
```

## Production cluster with central services

<img class="img-center" src="img/prod.png" alt="Container Linux cluster optimized for production environments"/>
<div class="caption">Container Linux cluster separated into central services and workers.</div>

| Cost | Great For | Set Up Time | Production |
|------|-----------|-------------|------------|
| High | Large bare-metal installations | Hours | Yes |

For large clusters, it's recommended to set aside 3-5 machines to run central services. Once those are set up, you can boot as many workers as you wish. Each of the workers will use your distributed etcd cluster on the central machines via local etcd proxies. This is explained in greater depth below.

### Configuration for central services role

Our central services machines will run services like etcd and Kubernetes controllers that support the rest of the cluster. etcd is configured with static networking and a peers list.

[Managed Linux][managed-linux] customers can also specify a [CoreUpdate][core-update] group ID which allows you to subscribe these machines to a different update channel, controlling updates separately from the worker machines.

Here's an example cloud-config for one of the central service machines. Be sure to generate a new discovery token with the initial size of your cluster:

```yaml
etcd:
  version: 3.0.15
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery: https://discovery.etcd.io/<token>
  # multi-region and multi-cloud deployments need to use $public_ipv4
  advertise_client_urls: http://10.0.0.101:2379
  initial_advertise_peer_urls: http://10.0.0.101:2380
  listen_client_urls: http://0.0.0.0:2379
  listen_peer_urls: http://10.0.0.101:2380
update:
  # CoreUpdate group ID for "Production Central Services"
  # Use "stable", "beta", or "alpha" for non-subscribers.
  group: 9e98ecae-4623-48c1-9679-423549c44da6
  server: https://customer.update.core-os.net/v1/update/
systemd:
  units:
    - name: etcd-member.service
      enable: true
networkd:
  units:
    - name: 00-eth0.network
      enable: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=1.2.3.4
        Address=10.0.0.101/24
        Gateway=10.0.0.1
```

### Configuration for worker role

The worker roles will use DHCP and should be easy to add capacity or autoscaling.

Similar to the central services machines, fleet will be configured with metadata specifying the role and any additional metadata you wish to set. etcd will automatically fallback to a local proxy via discovery service.If not all machines have SSDs or you have a subset of machines with a ton of RAM, it's useful to set metadata for those attributes.

[Managed Linux](https://coreos.com/products/managed-linux) customers can also specify a [CoreUpdate](https://coreos.com/products/coreupdate) group ID to use a different channel and control updates separately from the central machines.

Here's an example cloud-config for a worker:

```yaml
etcd:
  version: 3.0.15
  # use the same discovery token for the central service machines
  # make sure you have used the discovery token to bootstrap the
  # central service successfully
  # this etcd will fallback to proxy automatically
  discovery: https://discovery.etcd.io/<token>
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client-urls: http://0.0.0.0:2379
locksmith:
  reboot: etcd-lock
  etcd_endpoints: "http://localhost:2379"
update:
  # CoreUpdate group ID for "Production Central Services"
  # Use "stable", "beta", or "alpha" for non-subscribers.
  group: 9e98ecae-4623-48c1-9679-423549c44da6
  # Non-subscribers should use server: "https://public.update.core-os.net/v1/update/"
  server: https://customer.update.core-os.net/v1/update/
systemd:
  units:
    - name: etcd-member.service
      enable: true
```

[ct-getting-started]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/getting-started.md
[ignition-getting-started]: https://coreos.com/ignition/docs/latest/getting-started.html
[ignition-supported]: https://coreos.com/ignition/docs/latest/supported-platforms.html
[coreos-vagrant]: https://github.com/coreos/coreos-vagrant/
[coreos-kubernetes]: https://github.com/coreos/coreos-kubernetes/
[minikube]: https://github.com/kubernetes/minikube
[managed-linux]: https://coreos.com/products/managed-linux
[core-update]: https://coreos.com/products/coreupdate
