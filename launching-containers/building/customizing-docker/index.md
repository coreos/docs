---
layout: docs
title: Customizing docker
category: launching_containers
sub_category: building
weight: 7
---

# Customizing docker

The docker systemd unit can be customized by overriding the unit that ships with the default CoreOS settings. Common use-cases for doing this are covered below.

## Enable the Remote API on a New Socket

Create a file called `/etc/systemd/system/docker-tcp.socket` to make docker available on a tcp socket on port 4243.

```
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=4243
Service=docker.service
BindIPv6Only=both

[Install]
WantedBy=sockets.target
```

Then enable this new socket:

```
systemctl enable docker-tcp.socket
systemctl stop docker
systemctl start docker-tcp.socket
systemctl start docker
docker -H tcp://127.0.0.1:4243 ps
```

### Cloud-Config

To enable the remote API on every CoreOS machine in a cluster, use [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config). We need to provide the new socket file and docker's socket activation support will automatically start using the socket:

```
#cloud-config

coreos:
  units:
    - name: docker-tcp.socket
      command: start
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=4243
        Service=docker.service
        BindIPv6Only=both

        [Install]
        WantedBy=sockets.target
    - name: enable-docker-tcp.service
      command: start
      content: |
        [Unit]
        Description=Enable the Docker Socket for the API

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl enable docker-tcp.socket
```

To keep access to the port local, replace the `ListenStream` configuration above with:

```
        ListenStream=127.0.0.1:4243
```

## Use Attached Storage for Docker Images

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantagous to use attached storage to expand your capacity for container images. Check out the guide to [mounting storage to your CoreOS machine]({{site.url}}/docs/cluster-management/setup/mounting-storage/#use-attached-storage-for-docker) for an example of how to bind mount storage into `/var/lib/docker`.

## Enabling the docker Debug Flag

First, copy the existing unit from the read-only file system into the read/write file system, so we can edit it:

```
cp /usr/lib/systemd/system/docker.service /etc/systemd/system/
```

Edit the `ExecStart` line to add the -D flag:

```
ExecStart=/usr/bin/docker -d -s=btrfs -r=false -H fd:// -D
```

Now lets tell systemd about the new unit and restart docker:

```
systemctl daemon-reload
systemctl restart docker
```

To test our debugging stream, run a docker command and then read the systemd journal, which should contain the output:

```
docker ps
journalctl -u docker
```

### Cloud-Config

If you need to modify a flag across many machines, you can provide the new unit with cloud-config:

```
#cloud-config

coreos:
  units:
    - name: docker.service
      command: restart
      content: |
        [Unit]
        Description=Docker Application Container Engine 
        Documentation=http://docs.docker.io
        After=network.target
        [Service]
        ExecStartPre=/bin/mount --make-rprivate /
        # Run docker but don't have docker automatically restart
        # containers. This is a job for systemd and unit files.
        ExecStart=/usr/bin/docker -d -s=btrfs -r=false -H fd:// -D

        [Install]
        WantedBy=multi-user.target
```
