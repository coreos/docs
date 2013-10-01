---
layout: docs
slug: eucalyptus
title: Documentation - Eucalyptus
---

# Running CoreOS on Eucalyptus 3.4

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through downloading CoreOS, bundling the image, and running an instance from it.

## Import the Image

These steps will download the CoreOS image, uncompress it, convert it from qcow->raw, and then import it
into Eucalyptus. In order to convert the image you will need to install ```qemu-img``` with your favorite package manager.

```
$ wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
$ qemu-img convert -O raw coreos_production_openstack_image.img coreos_production_openstack_image.raw
$ euca-bundle-image -i coreos_production_openstack_image.raw -r x86_64 -d /var/tmp
$ euca-upload-bundle -m /var/tmp/coreos_production_openstack_image.raw.manifest.xml -b coreos-production
$ euca-register coreos-production/coreos_production_openstack_image.raw.manifest.xml --virtualization-type hvm --name "CoreOS-Production"
emi-E4A33D45
```

## Boot it up

Now generate the ssh key that will be injected into the image for the `core`
user and boot it up!

```
$ euca-create-keypair coreos > core.pem
$ euca-run-instances emi-E4A33D45 -k coreos -t m1.medium -g default
...
```

Your first CoreOS instance should now be running. The only thing left to do is
find the IP and SSH in.

```
$ euca-describe-instances
```

Finally SSH into it, note that the user is `core`:

```
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.0.3
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/

core@10-0-0-3 ~ $
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out
the [Using CoreOS][using-coreos] guide.
