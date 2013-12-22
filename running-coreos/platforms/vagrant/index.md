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

## Download and Install Vagrant

Vagrant is a simple to use command line virtual machine manager. There are
install packages available for Windows, Linux and OSX. Find the latest
installer on the [Vagrant downloads page][vagrant]. Be sure to get
version 1.2.3 or greater.

[vagrant]: http://downloads.vagrantup.com/

## Startup CoreOS

Now that you have vagrant installed you can bring up a CoreOS instance.

The following commands will first grab a Vagrantfile which file tells
Vagrant where it can find the latest disk image of CoreOS. Then Vagrant
will download the image and start it for you.

If you want to use the VMware provider see the next [section][vmware].

[vmware]: #using-vmware

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
vagrant up
vagrant ssh
```

## Using VMware

The following commands will setup CoreOS under the VMware Vagrant provider. After
you run `vagrant up` you will see a scary message but you can safely ignore it.
It will be fixed in version 1.2.8 of Vagrant.

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant/vmware
vagrant up --provider vmware_fusion
vagrant ssh
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
