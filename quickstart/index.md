---
layout: docs
title: CoreOS Quick Start
#redirect handled in alias_generator.rb
---

# Quick Start

If you don't have a CoreOS machine running, check out the guides on [running CoreOS]({{site.url}}/docs/#running-coreos) on most cloud providers ([EC2]({{site.url}}/docs/running-coreos/cloud-providers/ec2), [Rackspace]({{site.url}}/docs/running-coreos/cloud-providers/rackspace), [GCE]({{site.url}}/docs/running-coreos/cloud-providers/google-compute-engine)), virtualization platforms ([Vagrant]({{site.url}}/docs/running-coreos/platforms/vagrant), [VMware]({{site.url}}/docs/running-coreos/platforms/vmware), [OpenStack]({{site.url}}/docs/running-coreos/platforms/openstack), [QEMU/KVM]({{site.url}}/docs/running-coreos/platforms/qemu)) and bare metal servers ([PXE]({{site.url}}/docs/running-coreos/bare-metal/booting-with-pxe), [iPXE]({{site.url}}/docs/running-coreos/bare-metal/booting-with-ipxe), [ISO]({{site.url}}/docs/running-coreos/platforms/iso), [Installer]({{site.url}}/docs/running-coreos/bare-metal/installing-to-disk)). With any of these guides you will have machines up and running in a few minutes.

It's highly recommended that you set up a cluster of at least 3 machines &mdash; it's not as much fun on a single machine. If you don't want to break the bank, [Vagrant][vagrant-guide] allows you to run an entire cluster on your laptop. For a cluster to be properly bootstrapped, you have to provide cloud-config via user-data, which is covered in each platform's guide.

CoreOS gives you three essential tools: service discovery, container management and process management. Let's try each of them out.

First, connect to a CoreOS machine via SSH as the user `core`. For example, on Amazon, use:

```sh
$ ssh -A core@an.ip.compute-1.amazonaws.com
CoreOS (beta)
```

The `-A` forwards your ssh-agent to the machine, which is needed for the fleet section of this guide. If you haven't already done so, you will need to add your private key to the SSH agent running on your client machine - for example:

```sh
$ ssh-add
Identity added: .../.ssh/id_rsa (.../.ssh/id_rsa)
```

If you're using Vagrant, you'll need to connect a bit differently:

```sh
$ ssh-add ~/.vagrant.d/insecure_private_key
Identity added: /Users/core/.vagrant.d/insecure_private_key (/Users/core/.vagrant.d/insecure_private_key)
$ vagrant ssh core-01 -- -A
CoreOS (beta)
```

## Service Discovery with etcd

The first building block of CoreOS is service discovery with **etcd** ([docs][etcd-docs]). Data stored in etcd is distributed across all of your machines running CoreOS. For example, each of your app containers can announce itself to a proxy container, which would automatically know which machines should receive traffic. Building service discovery into your application allows you to add more machines and scale your services seamlessly.

If you used an example [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config) from a guide linked in the first paragraph, etcd is automatically started on boot.

A good starting point would be something like:

```
#cloud-config

hostname: coreos0
ssh_authorized_keys:
  - ssh-rsa AAAA...
coreos:
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
  etcd:
    name: coreos0
    discovery: https://discovery.etcd.io/<token>
    addr: $public_ipv4:4001
    peer-addr: $private_ipv4:7001
```

In order to get the discovery token, visit [https://discovery.etcd.io/new] and you will receive a URL including your token. Paste the whole thing into your cloud-config file.

The API is easy to use. From a CoreOS machine, you can simply use curl to set and retrieve a key from etcd:

Set a key `message` with value `Hello world`:

```sh
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello world"
```

Read the value of `message` back:

```sh
curl -L http://127.0.0.1:4001/v1/keys/message
```

If you followed a guide to set up more than one CoreOS machine, you can SSH into another machine and can retrieve this same value.

#### More Detailed Information
<a class="btn btn-primary" href="{{ site.url }}/docs/distributed-configuration/getting-started-with-etcd/" data-category="More Information" data-event="Docs: Getting Started etcd">View Complete Guide</a>
<a class="btn btn-default" href="{{site.url}}/docs/distributed-configuration/etcd-api/">Read etcd API Docs</a>

## Container Management with docker

The second building block, **docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each CoreOS machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a Ubuntu container in two different ways:

Run a command in the container and then stop it: 

```sh
docker run busybox /bin/echo hello world
```

Open a shell prompt inside the container:

```sh
docker run -i -t busybox /bin/sh
```

#### More Detailed Information
<a class="btn btn-primary" href="{{ site.url }}/docs/launching-containers/building/getting-started-with-docker" data-category="More Information" data-event="Docs: Getting Started docker">View Complete Guide</a>
<a class="btn btn-default" href="http://docs.docker.io/">Read docker Docs</a>

## Process Management with fleet

The third building block of CoreOS is **fleet**, a distributed init system for your cluster. You should use fleet to manage the life cycle of your docker containers.

Fleet works by receiving [systemd unit files]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd/) and scheduling them onto machines in the cluster based on declared conflicts and other preferences encoded in the unit file. Using the `fleetctl` tool, you can query the status of a unit, remotely access its logs and more.

First, let's construct a simple systemd unit that runs a docker container. Save this as `hello.service` in the home directory:

#### hello.service

```ini
[Unit]
Description=My Service
After=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill hello
ExecStartPre=-/usr/bin/docker rm hello
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name hello busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop hello
```

The [Getting Started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) guide explains the format of this file in more detail.

Then load and start the unit:

```sh
$ fleetctl load hello.service
Job hello.service loaded on 8145ebb7.../172.17.8.105
$ fleetctl start hello.service
Job hello.service launched on 8145ebb7.../172.17.8.105
```

Your container has been started somewhere on the cluster. To verify the status, run:

```sh
$ fleetctl status hello.service
● hello.service - My Service
   Loaded: loaded (/run/fleet/units/hello.service; linked-runtime)
   Active: active (running) since Wed 2014-06-04 19:04:13 UTC; 44s ago
 Main PID: 27503 (bash)
   CGroup: /system.slice/hello.service
           ├─27503 /bin/bash -c /usr/bin/docker start -a hello || /usr/bin/docker run --name hello busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"
           └─27509 /usr/bin/docker run --name hello busybox /bin/sh -c while true; do echo Hello World; sleep 1; done

Jun 04 19:04:57 core-01 bash[27503]: Hello World
..snip...
Jun 04 19:05:06 core-01 bash[27503]: Hello World
```

To stop the container, run:

```sh
fleetctl destroy hello.service
```

Fleet has many more features that you can explore in the guides below.

#### More Detailed Information
<a class="btn btn-primary" href="{{ site.url }}/docs/launching-containers/launching/launching-containers-fleet/" data-category="More Information" data-event="Docs: Launching Containers Fleet">View Complete Guide</a>
<a class="btn btn-default" href="{{ site.url }}/docs/launching-containers/launching/getting-started-with-systemd/" data-category="More Information" data-event="Docs: Getting Started with systemd">View Getting Started with systemd Guide</a>
