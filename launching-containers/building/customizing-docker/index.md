---
layout: docs
title: Customizing docker
category: launching_containers
sub_category: building
weight: 7
---

# Customizing docker

The docker systemd unit can be customized by overriding the unit that ships with the default CoreOS settings. Common use-cases for doing this are covered below.

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
