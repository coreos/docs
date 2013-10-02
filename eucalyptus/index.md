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
$ wget -q http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
$ qemu-img convert -O raw coreos_production_openstack_image.img coreos_production_openstack_image.raw
$ euca-bundle-image -i coreos_production_openstack_image.raw -r x86_64 -d /var/tmp
00% |====================================================================================================|   5.33 GB  59.60 MB/s Time: 0:01:35
Wrote manifest bundle/coreos_production_openstack_image.raw.manifest.xml
$ euca-upload-bundle -m /var/tmp/coreos_production_openstack_image.raw.manifest.xml -b coreos-production
coreos_production_openstack_image.raw.part.0  ( 1/18) 100% |==============================================|  10.00 MB   5.81 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.1  ( 2/18) 100% |==============================================|  10.00 MB   7.53 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.2  ( 3/18) 100% |==============================================|  10.00 MB   7.15 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.3  ( 4/18) 100% |==============================================|  10.00 MB   4.72 MB/s Time: 0:00:02
coreos_production_openstack_image.raw.part.4  ( 5/18) 100% |==============================================|  10.00 MB   6.75 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.5  ( 6/18) 100% |==============================================|  10.00 MB   7.61 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.6  ( 7/18) 100% |==============================================|  10.00 MB   7.74 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.7  ( 8/18) 100% |==============================================|  10.00 MB   7.08 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.8  ( 9/18) 100% |==============================================|  10.00 MB   6.92 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.9  (10/18) 100% |==============================================|  10.00 MB   7.12 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.10 (11/18) 100% |==============================================|  10.00 MB   7.22 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.11 (12/18) 100% |==============================================|  10.00 MB   6.61 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.12 (13/18) 100% |==============================================|  10.00 MB   6.37 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.13 (14/18) 100% |==============================================|  10.00 MB   6.62 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.14 (15/18) 100% |==============================================|  10.00 MB   6.38 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.15 (16/18) 100% |==============================================|  10.00 MB   6.25 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.part.16 (17/18) 100% |==============================================|  10.00 MB   7.17 MB/s Time: 0:00:01
coreos_production_openstack_image.raw.manifest.xml 100% |=================================================|   6.06 kB   4.86 kB/s Time: 0:00:01
Uploaded coreos-production/coreos_production_openstack_image.raw.manifest.xml
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
$ euca-describe-instances | grep coreos
RESERVATION     r-BCF44206      498025213678    group-1380012085
INSTANCE        i-22444094      emi-E4A33D45    euca-10-0-1-61.cloud.home       euca-172-16-0-56.cloud.internal running coreos  0
                m1.small        2013-10-02T05:32:44.096Z        one     eki-05573B4A    eri-EA7436D2            monitoring-enabled      10.0.1.61    172.16.0.56                     instance-store                                  paravirtualized         5046c208-fec1-4a6e-b079-e7cdf6a7db8f_one_1

```

Finally SSH into it, note that the user is `core`:

```
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.1.61
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
