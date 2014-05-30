---
layout: docs
slug: vagrant
title: Vagrant
category: running_coreos
sub_category: platforms
weight: 5
---

# Running CoreOS on Vagrant

CoreOS is currently in heavy development and actively being tested. These instructions will bring up a single CoreOS instance under Vagrant.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Install Vagrant and Virtualbox

Vagrant is a simple-to-use command line virtual machine manager. There are
install packages available for Windows, Linux and OSX. Find the latest
installer on the [Vagrant downloads page][vagrant]. Be sure to get
version 1.6.3 or greater.

[vagrant]: http://www.vagrantup.com/downloads.html

Vagrant can use either the free Virtualbox provider or the commerical VMware provider. Instructions for both are below. For the Virtualbox provider, version 4.3.10 or greater is required.

## Clone Vagrant Repo

Now that you have Vagrant installed you can bring up a CoreOS instance.

The following commands will clone a repository that contains the CoreOS Vagrantfile. This file tells
Vagrant where it can find the latest disk image of CoreOS. Vagrant will download the image the first time you attempt to start the VM.

```sh
git clone https://github.com/coreos/coreos-vagrant.git
cd coreos-vagrant
```

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. You can provide cloud-config data to your CoreOS Vagrant VM by editing the `user-data` file inside of the cloned directory.

The most common cloud-config for Vagrant looks like:

```yaml
#cloud-config

coreos:
  etcd:
      #generate a new token for each unique cluster from https://discovery.etcd.io/new
      #discovery: https://discovery.etcd.io/<token>
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

With Vagrant, you can start a single machine or an entire cluster. Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
Make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

### Using Vagrant's default VirtualBox Provider

Start the machine(s):

```sh
vagrant up
```

List the status of the running machines:

```sh
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

```sh
vagrant ssh core-01
```

### Using Vagrant's VMware Provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```sh
vagrant up --provider vmware_fusion
vagrant ssh core-01
```

## Shared Folder Setup

Optionally, you can share a folder from your laptop into the virtual machine. This is useful for easily getting code and Dockerfiles into CoreOS.

```ini
config.vm.network "private_network", ip: "172.12.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
Simply remove the old box file and Vagrant will download the latest one the next time you `vagrant up`.

```sh
vagrant box remove coreos-alpha vmware_fusion
vagrant box remove coreos-alpha virtualbox
```

If you'd like to download the box separately, you can download the URL contained in the Vagrantfile and add it manually:

```sh
vagrant box add coreos-alpha <path-to-box-file>
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
