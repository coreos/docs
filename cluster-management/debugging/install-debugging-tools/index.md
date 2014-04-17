---
layout: docs
slug: guides
title: Install Debugging Tools
category: cluster_management
sub_category: debugging
weight: 7
---

# Install Debugging Tools

You can use common debugging tools like tcpdump or strace with Toolbox. Using the filesystem of a specified docker container Toolbox will launch a container with full system privileges including access to system PIDs, network interfaces and other global information. Inside of the toolbox, the machine's filesystem is mounted to `/media/root`.

## Quick Debugging

By default, Toolbox uses the stock Fedora docker container. To start using it, simply run:

```
/usr/bin/toolbox
```

You're now in the namespace of Fedora and can install any software you'd like via `yum`. For example, if you'd like to use `tcpdump`:

```
[root@srv-3qy0p ~]# yum install tcpdump
[root@srv-3qy0p ~]# tcpdump -i ens3
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens3, link-type EN10MB (Ethernet), capture size 65535 bytes
```

### Specify a Custom Docker Image

Create a `.toolboxrc` in the user's home folder to use a specific docker image:

```
$ cat .toolboxrc
TOOLBOX_DOCKER_IMAGE=index.example.com/debug
TOOLBOX_USER=root
$ /usr/bin/toolbox
Pulling repository index.example.com/debug
...
```

## SSH Directly Into A Toolbox

Advanced users can SSH directly into a toolbox by setting up an `/etc/passwd` entry:

```
useradd bob -m -p '*' -s /usr/bin/toolbox
```

To test, SSH as bob:

```
ssh bob@hostname.example.com

   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/
[root@srv-3qy0p ~]# yum install emacs
[root@srv-3qy0p ~]# emacs /media/root/etc/systemd/system/docker.service
```
