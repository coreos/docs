---
layout: docs
slug: vagrant
title: Vagrant
category: running_coreos
sub_category: platforms
weight: 5
---

<div class="coreos-docs-banner">
<span class="glyphicon glyphicon-info-sign"></span>This image is now easier to use! Read about our <a href="{{site.url}}/blog/new-filesystem-btrfs-cloud-config/">new file system layout and cloud-config support</a>.
</div>

# Running CoreOS on Vagrant

CoreOS is currently in heavy development and actively being tested. These instructions will bring up a single CoreOS instance under Vagrant.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Download and Install Vagrant

Vagrant is a simple-to-use command line virtual machine manager. There are
install packages available for Windows, Linux and OSX. Find the latest
installer on the [Vagrant downloads page][vagrant]. Be sure to get
version 1.3.1 or greater.

[vagrant]: http://www.vagrantup.com/downloads.html

## Clone Vagrant Repo

Now that you have Vagrant installed you can bring up a CoreOS instance.

The following commands will clone a repository that contains the CoreOS Vagrantfile. This file tells
Vagrant where it can find the latest disk image of CoreOS. Vagrant will download the image the first time you attempt to start the VM.

```
git clone https://github.com/coreos/coreos-vagrant.git
cd coreos-vagrant
```

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. You can provide cloud-config data to your CoreOS Vagrant VM by editing the `user-data` file inside of the cloned directory.

The most common cloud-config for Vagrant looks like:

```
#cloud-config

coreos:
  etcd:
      #discovery: <DISCOVERY>
      addr: $public_ipv4:4001
      peer-addr: $public_ipv4:7001
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
      runtime: no
      content: |
        [Unit]
        Description=fleet

        [Service]
        Environment=FLEET_PUBLIC_IP=$public_ipv4
        ExecStart=/usr/bin/fleet

```

[cloud-config-docs]: {{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config

## Startup CoreOS

With Vagrant, you can start a single machine or an entire cluster. To start a cluster, edit `NUM_INSTANCES` in the Vagrantfile to three or more. The cluster will be automatically configured if you provided a discovery URL in the cloud-config.

### Using Vagrant's default VirtualBox Provider

Start the machine(s):

```
vagrant up
```

List the status of the running machines:

```
$ vagrant status
Current machine states:

core-01                   running (virtualbox)
core-02                   running (virtualbox)
core-03                   running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

Connect to one of the machines:

```
vagrant ssh core-01
```

### Using Vagrant's VMware Provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```
vagrant up --provider vmware_fusion
vagrant ssh core-01
```

## Shared Folder Setup

Optionally, you can share a folder from your laptop into the virtual machine. This is useful for easily getting code and Dockerfiles into CoreOS.

```
config.vm.network "private_network", ip: "172.12.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
Simply remove the old box file and Vagrant will download the latest one the next time you `vagrant up`.

```
vagrant box remove coreos-alpha vmware_fusion
vagrant box remove coreos-alpha virtualbox
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
