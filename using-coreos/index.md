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

The first building block of CoreOS is service discovery with **etcd** ([docs][etcd-docs]). Data stored in etcd is distributed across all of your machines running CoreOS. For example, each of your app servers can announce itself to your proxy, which would automatically know which machines should receive traffic. Building service discovery into your application allows you to add more machines and scale your services seamlessly.

The API is easy to use. You can simply use curl to set and retrieve a key from etcd:

Set a key `message` with value `Hello world`:

```
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello world"
```

Read the value of `message` back:

```
curl -L http://127.0.0.1:4001/v1/keys/message
```

If you followed a guide to set up more than one CoreOS machine, you can SSH into another machine and can retrieve this same value.

etcd is persistent and replicated accross members in the cluster. It can also be used standalone as a way to share configuration between containers on a single host. Read more about the full API on [Github][etcd-docs].

## Container Management with docker

The second building block, **docker** ([docs][docker-docs]), is where your applications and code run. Version {{ page.docker-version }} is installed on each CoreOS machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a Ubuntu container in two different ways:

Run a command in the container and then stop it: 

```
docker run ubuntu /bin/echo hello world
```

Open a bash prompt inside of the container:

```
docker run -i -t ubuntu /bin/bash
```

docker opens up a lot of possibilities for consistent application deploys. Read more about it at [docker.io][docker-docs].

## Process Management with systemd

The third buiding block of CoreOS is **systemd** ([docs][systemd-docs]). Version {{ page.systemd-version }} is installed on each CoreOS machine. You should use systemd to manage the life cycle of your docker containers. The configuration format for systemd is straight forward. In the example below, the Ubuntu container is set up to print text after each reboot:

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
