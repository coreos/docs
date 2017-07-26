# Container Linux quick start

If you don't have a Container Linux machine running, check out the guides on [running Container Linux][running-coreos] on most cloud providers ([EC2][ec2-docs], [Rackspace][rackspace-docs], [GCE][gce-docs]), virtualization platforms ([Vagrant][vagrant-docs], [VMware][vmware-docs], [OpenStack][openstack-docs], [QEMU/KVM][qemu-docs]) and bare metal servers ([PXE][pxe-docs], [iPXE][ipxe-docs], [ISO][iso-docs], [Installer][install-docs]). With any of these guides you will have machines up and running in a few minutes.

It's highly recommended that you set up a cluster of at least 3 machines &mdash; it's not as much fun on a single machine. If you don't want to break the bank, [Vagrant][vagrant-docs] allows you to run an entire cluster on your laptop. For a cluster to be properly bootstrapped, you have to provide ideally an [Ignition config][ignition] (generated from a [Container Linux Config][cl-configs]), or possibly a cloud-config, via user-data, which is covered in each platform's guide.

Container Linux gives you three essential tools: declarative provisioning, container management, and process management. Let's try each of them out.
Together, these tools make it easy to provision a cluster of machines and use an container orchestration system, such as Kubernetes, on top of them.

## Provisioning a Container Linux machine

* Walkthrough for using CT to set a ssh key
* Mention that some platforms, like ec2 or vagrant, will set an ssh key for you
* Walkthrough ssh-ing in and looking at systemctl status to see the basic running services
* Briefly mention automatic updates


## Container management with Docker

The second building block, **Docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each Container Linux machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a minimal busybox container in two different ways:

Run a command in the container and then stop it:

```sh
docker run busybox /bin/echo hello world
```

Open a shell prompt inside the container:

```sh
docker run --interactive --tty busybox /bin/sh
```

## Process management with systemd

Once you're comfortable with running containers and processes on Container Linux manually, the next step is 
Container Linux provides a recent version of [systemd][systemd-homepage] for process management.

* Examples of configuring docker
* Example of running something on every boot
* Example of the prometheus node exporter

## Clustering Container Linux

Now that you have some Container Linux machines running and understand the
tools each machine provides, let's see how we can use those machines in a
cluster.

### Service discovery with etcd

A shorter section about using etcd as a building block to a Container Linux cluster.

### Container Orchestration with Kubernetes

A final section that talks a little bit about kubernetes and tectonic and running them on CL.

Container orchestration allows you to run applications across a cluster of
Container Linux machines. It abstracts away the individual nodes in order to
allow your cluster to be resilient to the failure of individual nodes and to
more efficiently use the available compute resources.

We recommend using [Kubernetes][coreos-kubernetes] to orchestrate containers
across your Container Linux cluster.

### More detailed information

<a class="btn btn-primary" href="https://coreos.com/tectonic/" data-category="More Information" data-event="Tectonic by CoreOS">Learn about Tectonic</a>

[getting-started-systemd]: getting-started-with-systemd.md
[systemd-homepage]: https://www.freedesktop.org/wiki/Software/systemd/
[docker-docs]: https://docs.docker.com/
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
[ignition]: https://coreos.com/blog/introducing-ignition.html
[cl-configs]: provisioning.md
[tectonic]: https://coreos.com/tectonic/
[coreos-kubernetes]: https://coreos.com/kubernetes/docs/latest/
