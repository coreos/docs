---
layout: docs
title: CoreOS Quick Start
#redirect handled in alias_generator.rb
---

<div class="coreos-docs-banner">
<span class="glyphicon glyphicon-info-sign"></span>These instructions have been updated for <a href="{{site.url}}/blog/new-filesystem-btrfs-cloud-config/">our new images</a>.
</div>

# Quick Start

If you don't have a CoreOS machine running, check out the guides on running CoreOS on [Vagrant][vagrant-guide], [Amazon EC2][ec2-guide], [QEMU/KVM][qemu-guide], [VMware][vmware-guide] and [OpenStack][openstack-guide]. With either of these guides you will have a machine up and running in a few minutes. 

CoreOS gives you three essential tools: service discovery, container management and process management. Let's try each of them out. 

First, connect to a CoreOS machine via SSH as the user `core`. For example, on Amazon, use:

```
ssh core@an.ip.compute-1.amazonaws.com
```

## Service Discovery with etcd

The first building block of CoreOS is service discovery with **etcd** ([docs][etcd-docs]). Data stored in etcd is distributed across all of your machines running CoreOS. For example, each of your app containers can announce itself to a proxy container, which would automatically know which machines should receive traffic. Building service discovery into your application allows you to add more machines and scale your services seamlessly.

The API is easy to use. From a CoreOS machine, you can simply use curl to set and retrieve a key from etcd:

Set a key `message` with value `Hello world`:

```
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello world"
```

Read the value of `message` back:

```
curl -L http://127.0.0.1:4001/v1/keys/message
```

If you followed a guide to set up more than one CoreOS machine, you can SSH into another machine and can retrieve this same value.

#### More Detailed Information
<a class="btn btn-primary" href="{{ site.url }}/docs/guides/etcd/" data-category="More Information" data-event="Docs: Getting Started etcd">View Complete Guide</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd">Read etcd API Docs</a>

## Container Management with docker

The second building block, **docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each CoreOS machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a Ubuntu container in two different ways:

Run a command in the container and then stop it: 

```
docker run busybox /bin/echo hello world
```

Open a shell prompt inside the container:

```
docker run -i -t busybox /bin/sh
```

#### More Detailed Information
<a class="btn btn-primary" href="{{ site.url }}/docs/guides/docker/" data-category="More Information" data-event="Docs: Getting Started docker">View Complete Guide</a>
<a class="btn btn-default" href="http://docs.docker.io/">Read docker Docs</a>

## Process Management with systemd

The third building block of CoreOS is **systemd** ([docs][systemd-docs]) and it is installed on each CoreOS machine. You should use systemd to manage the life cycle of your docker containers. The configuration format for systemd is straightforward. In the example below, the Ubuntu container is set up to print text after each reboot:

First, you will need to run all of this as `root` since you are modifying system state:

```
sudo -i
```

Create a file called `/etc/systemd/system/hello.service`:

```
[Unit]
Description=My Service
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=10s
ExecStart=/bin/bash -c '/usr/bin/docker start -a hello || /usr/bin/docker run --name hello busybox /bin/sh -c \
"while true; do echo Hello World; sleep 1; done"'
ExecStop=/bin/bash -c "/usr/bin/docker stop -t 2 hello"

[Install]
WantedBy=multi-user.target
```

See the [getting started with systemd]({{site.url}}/docs/launching-containers/launching/getting-started-with-systemd) page for more information on the format of this file.

Then run enable and start the unit:

```
sudo systemctl enable /etc/systemd/system/hello.service
sudo systemctl start hello.service
```

Your container is now started and is logging to the systemd journal. You can read the log by running:

```
journalctl -u hello.service -f
```

To stop the container, run:

```
sudo systemctl stop hello.service
```

#### More Detailed Information
<a class="btn btn-default" href="http://www.freedesktop.org/wiki/Software/systemd/">Read systemd Website</a>

#### Chaos Monkey
During our alpha period, Chaos Monkey (i.e. random reboots) is built in and will give you plenty of opportunities to test out systemd. CoreOS machines will automatically reboot after an update is applied unless you [configure them not to]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update).
