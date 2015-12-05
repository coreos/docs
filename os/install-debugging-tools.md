# Install Debugging Tools

You can use common debugging tools like tcpdump or strace with Toolbox. Using the filesystem of a specified Docker container Toolbox will launch a container with full system privileges including access to system PIDs, network interfaces and other global information. Inside of the toolbox, the machine's filesystem is mounted to `/var/lib/toolbox/core-fedora-latest`.

## Quick Debugging

By default, Toolbox uses the stock Fedora Docker container. To start using it, simply run:

```sh
/usr/bin/toolbox
```

You're now in the namespace of Fedora and can install any software you'd like via `yum`. For example, if you'd like to use `tcpdump`:

```sh
[root@srv-3qy0p ~]# yum install tcpdump
[root@srv-3qy0p ~]# tcpdump -i ens3
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens3, link-type EN10MB (Ethernet), capture size 65535 bytes
```

### Specify a Custom Docker Image

Create a `.toolboxrc` in the user's home folder to use a specific Docker image:

```sh
$ cat .toolboxrc
TOOLBOX_DOCKER_IMAGE=index.example.com/debug
TOOLBOX_USER=root
$ /usr/bin/toolbox
Pulling repository index.example.com/debug
...
```

You can also specify this in cloud-config:

```
#cloud-config
write_files:
  - path: /home/core/.toolboxrc
    owner: core
    content: |
      TOOLBOX_DOCKER_IMAGE=index.example.com/debug
      TOOLBOX_DOCKER_TAG=v1
      TOOLBOX_USER=root
```

## SSH Directly Into A Toolbox

Advanced users can SSH directly into a toolbox by setting up an `/etc/passwd` entry:

```sh
useradd bob -m -p '*' -s /usr/bin/toolbox -U -G sudo,docker
```

To test, SSH as bob:

```sh
ssh bob@hostname.example.com

   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/
[root@srv-3qy0p ~]# yum install emacs
[root@srv-3qy0p ~]# emacs /media/root/etc/systemd/system/docker.service
```
