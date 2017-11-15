# Up and Running with Container Linux

Container Linux gives you three essential tools: declarative provisioning, container management, and process management. Let's try each of them out.

Together, these tools make it easy to provision a cluster of machines and use a container orchestration system, such as Kubernetes, on top of them.

## Provisioning a Container Linux machine

For this example, let's provision a single Container Linux machine:

The first step of provisioning a Container Linux machine is to write a [Container Linux Config][cl-configs].

At a bare minimum, a Container Linux Config will typically include an ssh public key to access the machine later, as shown below:

```yaml container-linux-config
passwd:
  users:
  - name: core
    ssh_authorized_keys:
    - ssh-rsa AAAA...
```

On some platforms, such as Amazon EC2 and Google Compute Engine, the provider will offer an alternative mechanism to supply an ssh key. In those cases, both the ssh keys configured by the provider and those specified in the Container Linux Config will be configured.

### Converting the Container Linux Config

Before being used to launch a machine, a Container Linux Config should be converted with the [Container Linux Config Transpiler][config-transpiler].
This process can be done with the Config Transpiler tool, `ct`, from its [Release Page][download-ct].

After writing the above Container Linux Config to a `quickstart-config.yaml`, run `ct < quickstart-config.yaml > quickstart-config.ign` to create an Ignition file to be used as user-data to launch a Container Linux machine.

### Launching the Container Linux machine

The exact process to launch a Container Linux machine varies by platform. There is documentation available for [running Container Linux][running-coreos] on most cloud providers ([EC2][ec2-docs], [Rackspace][rackspace-docs], [GCE][gce-docs]), virtualization platforms ([Vagrant][vagrant-docs], [VMware][vmware-docs], [OpenStack][openstack-docs], [QEMU/KVM][qemu-docs]) and bare metal servers ([PXE][pxe-docs], [iPXE][ipxe-docs], [ISO][iso-docs], [Installer][install-docs]). Each of those guides explains the process for provisioning a machine and providing user-data.
Going forwards, this guide will provide instructions for the Vagrant and EC2 platforms, but other platforms should work similarly.

<div id="launch-machine">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#vagrant-launch" data-toggle="tab">Vagrant></li>
    <li class="active"><a href="#ec2-launch" data-toggle="tab">EC2></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="vagrant-launch">
      <pre>
      $ git clone https://github.com/coreos/coreos-vagrant.git
      $ cd coreos-vagrant
      $ ct -platform vagrant-virtualbox < /path/to/container-linux-config.yaml > config.ign
      $ vagrant --provider virtualbox up
      Bringing machine 'core-01' up with 'virtualbox' provider...
      ...
          core-01: SSH address: 127.0.0.1:2222

      $ ssh -p 2222 core@127.0.0.1
      </pre>
    </div>
    <!-- TODO ec2 -->
  </div>
</div>

### Running Software

Container Linux is lightweight &emdash; the system only includes a minimum set of components to configure and update the machine, and to run containers or container orchestration software.

Container Linux doesn't include a package manager, so any software not included in the base image must be run in a container.
For example, to run the colorful "htop" utility to see what processes are running on the machine, you could use a docker image you've built or trust:

```shell
$ docker run -it --pid=host jess/htop
# press 'q' to quit
```

<!-- Toolbox mention? I'd personally prefer people use purpose-built containers vs the toolbox though - euank -->

### Updates




Container Linux, at its core, is a lightweight operating system
Container Linux by default is a minimal Linux distribution



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
[config-transpiler]: provisioning.md#config-transpiler
[tectonic]: https://coreos.com/tectonic/
[coreos-kubernetes]: https://coreos.com/kubernetes/docs/latest/
[download-ct]: https://github.com/coreos/container-linux-config-transpiler/releases
