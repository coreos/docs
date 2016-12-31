# Container Linux quick start

If you don't have a Container Linux machine running, check out the guides on [running Container Linux][running-coreos] on most cloud providers ([EC2][ec2-docs], [Rackspace][rackspace-docs], [GCE][gce-docs]), virtualization platforms ([Vagrant][vagrant-docs], [VMware][vmware-docs], [OpenStack][openstack-docs], [QEMU/KVM][qemu-docs]) and bare metal servers ([PXE][pxe-docs], [iPXE][ipxe-docs], [ISO][iso-docs], [Installer][install-docs]). With any of these guides you will have machines up and running in a few minutes.

It's highly recommended that you set up a cluster of at least 3 machines &mdash; it's not as much fun on a single machine. If you don't want to break the bank, [Vagrant][vagrant-docs] allows you to run an entire cluster on your laptop. For a cluster to be properly bootstrapped, you have to provide cloud-config via user-data, which is covered in each platform's guide.

Container Linux gives you three essential tools: service discovery, container management and process management. Let's try each of them out.

First, on the client start your user agent by typing:

```
eval $(ssh-agent)
```

Then, add your private key to the agent by typing:

```
ssh-add
```

Connect to a Container Linux machine via SSH as the user `core`. For example, on Amazon, use:

```sh
$ ssh -A core@an.ip.compute-1.amazonaws.com
CoreOS (beta)
```

The `-A` forwards your ssh-agent to the machine, which is needed for the fleet section of this guide.

If you're using Vagrant, you'll need to connect a bit differently:

```sh
$ ssh-add ~/.vagrant.d/insecure_private_key
Identity added: /Users/core/.vagrant.d/insecure_private_key (/Users/core/.vagrant.d/insecure_private_key)
$ vagrant ssh core-01 -- -A
CoreOS (beta)
```

## Service discovery with etcd

The first building block of Container Linux is service discovery with **etcd** ([docs][etcd-docs]). Data stored in etcd is distributed across all of your machines running Container Linux. For example, each of your app containers can announce itself to a proxy container, which would automatically know which machines should receive traffic. Building service discovery into your application allows you to add more machines and scale your services seamlessly.

If you used an example [cloud-config](https://coreos.com/os/docs/latest/cloud-config.html) from a guide linked in the first paragraph, etcd is automatically started on boot.

A good starting point would be something like:

```cloud-config
#cloud-config

hostname: coreos0
ssh_authorized_keys:
  - ssh-rsa AAAA...
coreos:
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
```

In order to get the discovery token, visit [https://discovery.etcd.io/new](https://discovery.etcd.io/new) and you will receive a URL including your token. Paste the whole thing into your cloud-config file.

`etcdctl` is a command line interface to etcd that is preinstalled on Container Linux. To set and retrieve a key from etcd you can use the following examples:

Set a key `message` with value `Hello world`:

```sh
etcdctl set /message "Hello world"
```

Read the value of `message` back:

```sh
etcdctl get /message
```

You can also use simple `curl`. These examples correspond to previous ones:

Set the value:

```sh
curl -L http://127.0.0.1:2379/v2/keys/message -XPUT -d value="Hello world"
```

Read the value:

```sh
curl -L http://127.0.0.1:2379/v2/keys/message
```

If you followed a guide to set up more than one Container Linux machine, you can SSH into another machine and can retrieve this same value.

### More detailed information

<a class="btn btn-primary" href="https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html" data-category="More Information" data-event="Docs: Getting Started etcd">View Complete Guide</a>
<a class="btn btn-default" href="https://coreos.com/etcd/docs/latest/api.html">Read etcd API Docs</a>

## Container management with Docker

The second building block, **Docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each Container Linux machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a minimal busybox container in two different ways:

Run a command in the container and then stop it:

```sh
docker run busybox /bin/echo hello world
```

Open a shell prompt inside the container:

```sh
docker run -i -t busybox /bin/sh
```

### More detailed information

<a class="btn btn-primary" href="https://coreos.com/os/docs/latest/getting-started-with-docker.html" data-category="More Information" data-event="Docs: Getting Started docker">View Complete Guide</a>
<a class="btn btn-default" href="http://docs.docker.io/">Read Docker Docs</a>

## Process management with fleet

The third building block of Container Linux is **fleet**, a distributed init system for your cluster. You should use fleet to manage the life cycle of your Docker containers.

Fleet works by receiving [systemd unit files][getting-started-systemd] and scheduling them onto machines in the cluster based on declared conflicts and other preferences encoded in the unit file. Using the `fleetctl` tool, you can query the status of a unit, remotely access its logs and more.

First, let's construct a simple systemd unit that runs a Docker container. Save this as `hello.service` in the home directory:

### hello.service

```ini
[Unit]
Description=My Service
After=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill hello
ExecStartPre=-/usr/bin/docker rm hello
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name hello busybox /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"
ExecStop=/usr/bin/docker stop hello
```

The [Getting Started with systemd][getting-started-systemd] guide explains the format of this file in more detail.

Then load and start the unit:

```sh
$ fleetctl load hello.service
Unit hello.service loaded on 8145ebb7.../172.17.8.105
$ fleetctl start hello.service
Unit hello.service launched on 8145ebb7.../172.17.8.105
```

Your container has been started somewhere on the cluster. To verify the status, run:

```sh
$ fleetctl status hello.service
● hello.service - My Service
   Loaded: loaded (/run/fleet/units/hello.service; linked-runtime)
   Active: active (running) since Wed 2014-06-04 19:04:13 UTC; 44s ago
 Main PID: 27503 (bash)
   CGroup: /system.slice/hello.service
           └─27503 /usr/bin/docker run --name hello busybox /bin/sh -c trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done

Jun 04 19:04:57 core-01 bash[27503]: Hello World
..snip...
Jun 04 19:05:06 core-01 bash[27503]: Hello World
```

To stop the container, run:

```sh
fleetctl destroy hello.service
```

Fleet has many more features that you can explore in the guides below.

### More detailed information

<a class="btn btn-primary" href="https://coreos.com/fleet/docs/latest/launching-containers-fleet.html" data-category="More Information" data-event="Docs: Launching Containers Fleet">View Complete Guide</a>
<a class="btn btn-default" href="https://coreos.com/os/docs/latest/getting-started-with-systemd.html" data-category="More Information" data-event="Docs: Getting Started with systemd">View Getting Started with systemd Guide</a>

[getting-started-systemd]: getting-started-with-systemd.md
[docker-docs]: https://docs.docker.io
[etcd-docs]: https://coreos.com/etcd/docs/latest/
[running-coreos]: https://coreos.com/docs/#running-coreos
[ec2-docs]: booting-on-ec2.md
[rackspace-docs]: booting-on-rackspace.md
[gce-docs]: booting-on-google-compute-engine.md
[vagrant-docs]: booting-on-vagrant.md
[vmware-docs]: booting-on-vmware.md
[openstack-docs]: booting-on-openstack.md
[qemu-docs]: booting-with-qemu.md
[pxe-docs]: booting-with-pxe.md
[ipxe-docs]: booting-with-ipxe.md
[iso-docs]: booting-with-iso.md
[install-docs]: installing-to-disk.md
