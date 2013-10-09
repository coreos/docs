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

systemd {{ page.systemd-version }} ([docs][systemd-docs]). We particularly think socket activation is useful for widely deployed services.

The configuration file format for systemd is straight forward. Lets create a simple service to run out of our ubuntu container that will start on reboots.:

First, you will need to run all of this as `root` since you are modifying system state:

```
sudo su
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

Then run `systemctl restart local-enable.service`

This will start your daemon and log to the systemd journal. You can
watch all of the useful work it is doing by running:

```
journalctl -u hello.service -f
```

systemd provides a solid init system and service manager. Read more about it at the [systemd homepage][systemd-docs].

## Adding disk space

Most writable paths such as `/home`, `/var`, and `/usr/local` are stored
in a special STATE partition mounted at `/media/state`. The default size
of this partition depends on the platform a new CoreOS but it is usually
between 3GB and 16GB. If more space is required simply extend the
virtual machine's disk image and CoreOS will fix the partition table and
resize the STATE partition to fill the disk on the next boot.

### qemu-img

Even if you are not using Qemu itself the qemu-img tool is the easiest
to use. It will work on raw, qcow2, vmdk, and most other formats. The
command accepts either an absolute size or a relative size by
by adding `+` prefix. Unit suffixes such as `G` or `M` are also supported.

```
# Increase the disk size by 5GB
qemu-img resize coreos_production_qemu_image.img +5G
```

### VMware

The interface available for resizing disks in VMware varies depending on
the product. See this [Knowledge Base article][vmkb1004047] for details.
Most products include a tool called `vmware-vdiskmanager`. The size must
be the absolute disk size, relative sizes are not supported so be
careful to only increase the size, not shrink it. The unit
suffixes `Gb` and `Mb` are supported.

```
# Set the disk size to 20GB
vmware-vdiskmanager -x 20Gb coreos_developer_vmware_insecure.vmx
```

[vmkb1004047]: http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1004047

### VirtualBox

Use qemu-img or vmware-vdiskmanager as described above. VirtualBox does
not support resizing VMDK disk images, only VDI and VHD disks. Meanwhile
VirtualBox only supports using VMDK disk images with the OVF config file
format used for importing/exporting virtual machines.

If you have have no other options you can try converting the VMDK disk
image to a VDI image and configuring a new virtual machine with it:

```
VBoxManage clonehd old.vmdk new.vdi --format VDI
VBoxManage modifyhd new.vdi --resize 20480
```

### Amazon EC2

Amazon doesn't support directly resizing volumes, you must take a
snapshot and create a new volume based on that snapshot. Refer to
the AWS EC2 documentation on [expanding EBS volumes][ebs-expand-volume]
for detailed instructions.

[ebs-expand-volume]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-expand-volume.html


#### Chaos Monkey

Built in Chaos Monkey (i.e. random reboots). During the alpha period, CoreOS will automatically reboot after an update is applied.
