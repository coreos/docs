---
layout: docs
slug: using-coreos
title: Documentation
docker-version: 0.5
systemd-version: 204
---

# Using CoreOS

If you haven't already got an instance of CoreOS up and running checkout the guides on running CoreOS on [Vagrant][vagrant-guide] or [Amazon EC2][ec2-guide]. With either of these guides you will have a machine up and running in a few minutes.

**NOTE**: the user for ssh is `core`. For example use `ssh core@an.ip.compute-1.amazonaws.com`

CoreOS gives you three essential tools: service discovery, container management and process management. Lets try each of them out.

## Service Discovery with etcd

etcd ([docs][etcd-docs]) can be used for service discovery between nodes. This will make it extremely easy to do things like have your proxy automatically discover which app servers to balance to. etcd's goal is to make it easy to build services where you add more machines and services automatically scale.

The API is easy to use. You can simply use curl to set and retrieve a key from etcd:

```
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello world"
curl -L http://127.0.0.1:4001/v1/keys/message
```

If you followed the [EC2 guide][ec2-guide] you can SSH into another machine in your cluster and can retrieve this same key:

```
curl -L http://127.0.0.1:4001/v1/keys/message
```

etcd is persistent and replicated accross members in the cluster. It can also be used standalone as a way to share configuration between containers on a single host. Read more about the full API on [Github][etcd-docs].

## Container Management with docker

docker {{ page.docker-version }} ([docs][docker-docs]) for package management. Put all your apps into containers, and wire them together with etcd across hosts.

You can quickly try out a Ubuntu container with these commands:

```
docker run ubuntu /bin/echo hello world
docker run -i -t ubuntu /bin/bash
```

docker opens up a lot of possibilities for consistent application deploys. Read more about it at [docker.io][docker-docs].

## Process Management with systemd

The third buiding block of CoreOS is **systemd**. [Version {{ page.systemd-version }}][systemd-docs] is installed on each CoreOS machine. You should use systemd to manage the life cycle of your docker containers. The configuration format for systemd is straight forward. In the example below, the Ubuntu container is set up to print text after each reboot:

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
ExecStart=/usr/bin/docker run ubuntu /bin/sh -c "while true; do echo Hello World; sleep 1; done"

[Install]
WantedBy=local.target
```

Then run `systemctl restart local-enable.service` to restart all services wanted by local.target. This will start your container and log to the systemd journal. You can read the log by running:

```
journalctl -u hello.service -f
```

systemd provides a solid init system and service manager. Read more about it at the [systemd homepage][systemd-docs].

#### Chaos Monkey

Built in Chaos Monkey (i.e. random reboots). During the alpha period, CoreOS will automatically reboot after an update is applied.
