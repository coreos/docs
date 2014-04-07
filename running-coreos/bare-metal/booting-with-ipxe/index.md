---
layout: docs
slug: ipxe
title: Booting with iPXE
category: running_coreos
sub_category: bare_metal
weight: 5
---

# Booting CoreOS via iPXE

CoreOS is currently in heavy development and actively being tested. These instructions will walk you through booting CoreOS via PXE on real or virtual hardware. By default, this will run CoreOS completely out of RAM. CoreOS can also be [installed to disk]({{site.url}}/docs/running-coreos/bare-metal/installing-to-disk).

## Configuring pxelinux

iPXE can be used on any platform that can boot an ISO image.
This includes many cloud providers and physical hardware.

To illustrate iPXE in action we will qemu-kvm in this guide.

### Setting up the Boot Script

iPXE downloads a boot script from a publicly available URL.
You will need to host this URL somewhere public and replace the example SSH key with your own.

```
#!ipxe

set coreos-version dev-channel
set base-url http://storage.core-os.net/coreos/amd64-generic/${coreos-version}
kernel ${base-url}/coreos_production_pxe.vmlinuz root=squashfs: state=tmpfs: sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot
```

An easy place to host this boot script is on https://gist.github.com and then shorten the raw URL with http://git.io.


### Booting iPXE

First, download and boot the iPXE image.
We will use `qemu-kvm` in this guide but use whatever process you normally use for booting an ISO on your platform.

```
wget http://boot.ipxe.org/ipxe.iso
qemu-kvm -m 1024 ipxe.iso --curses
```

Next press Ctrl+B to get to the iPXE prompt and type in the following commands:

```
iPXE> dhcp
iPXE> chain http://${YOUR_BOOT_URL}
```

Immediatly iPXE should download your boot script URL and start grabbing the images from the CoreOS storage site:

```
${YOUR_BOOT_URL}... ok
http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_pxe.vmlinuz... 98%
```

After a few moments of downloading CoreOS should boot normally.

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest verison, assuming that the image served by the PXE server is regularly updated.

## Installation

CoreOS can be completely installed on disk or run from RAM but store user data on disk. Read more in our [Installing CoreOS guide](/docs/running-coreos/bare-metal/installing-to-disk).

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
