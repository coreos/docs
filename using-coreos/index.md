---
layout: docs
slug: using-coreos
title: Documentation - Using CoreOS
---

# Using CoreOS

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
<a class="btn btn-default" href="https://github.com/coreos/etcd">Read etcd API Docs</a>

## Container Management with docker

The second building block, **docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each CoreOS machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a Ubuntu container in two different ways:

Run a command in the container and then stop it: 

```
docker run busybox /bin/echo hello world
```

Open a shell prompt inside of the container:

```
docker run -i -t busybox /bin/sh
```

#### More Detailed Information
<a class="btn btn-default" href="http://docs.docker.io/">Read docker Docs</a>

## Process Management with systemd

The third buiding block of CoreOS is **systemd** ([docs][systemd-docs]) and it is installed on each CoreOS machine. You should use systemd to manage the life cycle of your docker containers. The configuration format for systemd is straight forward. In the example below, the Ubuntu container is set up to print text after each reboot:

First, you will need to run all of this as `root` since you are modifying system state:

```
sudo -i
```

Create a file called `/media/state/units/hello.service`

```
[Unit]
Description=My Service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run busybox /bin/sh -c "while true; do echo Hello World; sleep 1; done"

[Install]
WantedBy=local.target
```

Then run `systemctl restart local-enable.service` to restart all services wanted by local.target. This will start your container and log to the systemd journal. You can read the log by running:

```
journalctl -u hello.service -f
```

#### More Detailed Information
<a class="btn btn-default" href="http://www.freedesktop.org/wiki/Software/systemd/">Read systemd Website</a>

#### Chaos Monkey
During our alpha period, Chaos Monkey (i.e. random reboots) is built in and will give you plenty of opportunities to test out systemd. CoreOS machines will automatically reboot after an update is applied.
