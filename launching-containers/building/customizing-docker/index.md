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

Create a file called `/etc/systemd/system/docker-tcp.socket` to make docker available on a TCP socket on port 2375.

```ini
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=2375
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
```

Then enable this new socket:

```sh
systemctl enable docker-tcp.socket
systemctl stop docker
systemctl start docker-tcp.socket
systemctl start docker
```

Test that it's working:

```sh
docker -H tcp://127.0.0.1:2375 ps
```

### Cloud-Config

To enable the remote API on every CoreOS machine in a cluster, use [cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config). We need to provide the new socket file and Docker's socket activation support will automatically start using the socket:

```yaml
#cloud-config

coreos:
  units:
    - name: docker-tcp.socket
      command: start
      enable: true
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
```

To keep access to the port local, replace the `ListenStream` configuration above with:

```yaml
        [Socket]
        ListenStream=127.0.0.1:2375
```

## Use Attached Storage for Docker Images

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantageous to use attached storage to expand your capacity for container images. Check out the guide to [mounting storage to your CoreOS machine]({{site.baseurl}}/docs/cluster-management/setup/mounting-storage/#use-attached-storage-for-docker) for an example of how to bind mount storage into `/var/lib/docker`.

## Enabling the docker Debug Flag

First, copy the existing unit from the read-only file system into the read/write file system, so we can edit it:

```sh
cp /usr/lib/systemd/system/docker.service /etc/systemd/system/
```

Edit the `ExecStart` line to add the -D flag:

```ini
ExecStart=/usr/bin/docker -d -s=btrfs -r=false -H fd:// -D
```

Now lets tell systemd about the new unit and restart docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

To test our debugging stream, run a docker command and then read the systemd journal, which should contain the output:

```sh
docker ps
journalctl -u docker
```

### Cloud-Config

If you need to modify a flag across many machines, you can provide the new unit with cloud-config:

```yaml
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

## Use an HTTP Proxy

If you're operating in a locked down networking environment, you can specify an HTTP proxy for docker to use via an environment variable. First, create a directory for drop-in configuration for docker:

```sh
mkdir /etc/systemd/system/docker.service.d
```

Now, create a file called `/etc/systemd/system/docker.service.d/http-proxy.conf` that adds the environment variable:

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
```

To apply the change, reload the unit and restart docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

### Cloud-Config

The easiest way to use this proxy on all of your machines is via cloud-config:

```yaml
#cloud-config

write_files:
    - path: /etc/systemd/system/docker.service.d/http-proxy.conf
      owner: core:core
      permissions: 0644
      content: |
        [Service]
        Environment="HTTP_PROXY=http://proxy.example.com:8080"

coreos:
  units:
    - name: docker.service
      command: restart
```

## Increase ulimits

If you need to increase certain ulimits that are too low for your application by default, like memlock, you will need to modify the docker service to increase the limit. First, create a directory for drop-in configuration for docker:

```sh
mkdir /etc/systemd/system/docker.service.d
```

Now, create a file called `/etc/systemd/system/docker.service.d/increase-ulimit.conf` that adds increased limit:

```ini
[Service]
LimitMEMLOCK=infinity
```

To apply the change, reload the unit and restart docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

### Cloud-Config

The easiest way to use these new ulimits on all of your machines is via cloud-config:

```yaml
#cloud-config

write_files:
    - path: /etc/systemd/system/docker.service.d/increase-ulimit.conf
      owner: core:core
      permissions: 0644
      content: |
        [Service]
        LimitMEMLOCK=infinity

coreos:
  units:
    - name: docker.service
      command: restart
```


## Using a dockercfg File for Authentication

A json file `.dockercfg` can be created in your home directory that holds authentication information for a public or private docker registry.

Read more about [registry authentication]({{site.baseurl}}/docs/launching-containers/building/registry-authentication).