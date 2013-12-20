---
layout: docs
slug: pxe
title: Installing to Disk
category: running_coreos
sub_category: bare_metal
weight: 7
---

# Installing CoreOS to Disk

There are two options for installation on bare metal:

- Use the installer and put a full CoreOS installation on disk
- Set up a STATE partition and only store user data on disk and run CoreOS from RAM

### Full Installation

There is a simple installer that will destroy everything on the given target disk.
Essentially it downloads an image, verifies it with gpg and then copies it bit for bit to disk.

```
coreos-install -d /dev/sda
```

You most likely will want to take your ssh authorized key files over to this new install too.

```
mount /dev/sda9 /mnt/
cp -Ra ~core/.ssh /mnt/overlays/home/core/
```

### STATE Only Installation

If you want to run CoreOS out of RAM but keep your containers and state on disk you will need to setup a STATE partition.
For now this is a manual process.

First, add a single partition to your disk:

```
parted -a optimal /dev/sda
mklabel gpt
mkpart primary 1 100%
```

Next, format the disk and set the label:

```
mkfs.ext4 /dev/sda1
e2label /dev/sda1 STATE
```

Now you can remove the `state=tmpfs:` line from the PXE parameters and the next time you start the machine it will search for the disk and use it.

## Hardware Support

We are still working on the full set of hardware that we will be supporting.
We have most of the common hardware working.
If you run into issues ping on us #coreos or email [Carly][carly-email].

[carly-email]: mailto:carly.stoughton+pxehardware@coreos.com

## Adding a Custom OEM

CoreOS has an [OEM partition][oem] that is used to setup networking, SSH keys, etc on boot.
If you have site specific customizations you need to make the PXE image this is the perfect place to make it.
Simply create a `./usr/share/oem/` directory as described on the [OEM page][oem] and append it to the CPIO:

```
gzip -d coreos_production_pxe_image.cpio.gz
find usr | cpio -o -A -H newc -O coreos_production_pxe_image.cpio
gzip coreos_production_pxe_image.cpio
```

Confirm the archive looks correct and has your `run` file inside of it:

```
gzip -dc coreos_production_pxe_image.cpio.gz | cpio -it
./
newroot.squashfs
usr
usr/share
usr/share/oem
usr/share/oem/run
```

[oem]: {{site.url}}/docs/oem/

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
