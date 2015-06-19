---
layout: docs
slug: ipxe
title: Booting with iPXE
category: running_coreos
sub_category: bare_metal
supported: true
weight: 5
---

# Booting CoreOS via iPXE

CoreOS is currently in heavy development and actively being tested. These instructions will walk you through booting CoreOS via iPXE on real or virtual hardware. By default, this will run CoreOS completely out of RAM. CoreOS can also be [installed to disk]({{site.baseurl}}/docs/running-coreos/bare-metal/installing-to-disk).

## Configuring pxelinux

iPXE can be used on any platform that can boot an ISO image.
This includes many cloud providers and physical hardware.

To illustrate iPXE in action we will qemu-kvm in this guide.

### Choose a Channel

CoreOS is released into alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

### Setting up the Boot Script

<div id="ipxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://alpha.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://beta.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://stable.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
  </div>
</div>

An easy place to host this boot script is on [http://pastie.org](http://pastie.org). Be sure to reference the "raw" version of script, which is accessed by clicking on the clipboard in the top right.

Note: the iPXE environment won't open https links, which means you can't use [https://gist.github.com](https://gist.github.com) to store your script. Bummer, right?


### Booting iPXE

First, download and boot the iPXE image.
We will use `qemu-kvm` in this guide but use whatever process you normally use for booting an ISO on your platform.

```sh
wget http://boot.ipxe.org/ipxe.iso
qemu-kvm -m 1024 ipxe.iso --curses
```

Next press Ctrl+B to get to the iPXE prompt and type in the following commands:

```sh
iPXE> dhcp
iPXE> chain http://${YOUR_BOOT_URL}
```

Immediately iPXE should download your boot script URL and start grabbing the images from the CoreOS storage site:

```sh
${YOUR_BOOT_URL}... ok
http://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz... 98%
```

After a few moments of downloading CoreOS should boot normally.

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

CoreOS can be completely installed on disk or run from RAM but store user data on disk. Read more in our [Installing CoreOS guide]({{site.baseurl}}/docs/running-coreos/bare-metal/booting-with-pxe/#installation).

## Adding a Custom OEM

Similar to the [OEM partition][oem] in CoreOS disk images, iPXE images can be customized with a [cloud config][cloud-config] bundled in the initramfs. You can view the [instructions on the PXE docs]({{site.baseurl}}/docs/running-coreos/bare-metal/booting-with-pxe/#adding-a-custom-oem).

[oem]: {{site.baseurl}}/docs/sdk-distributors/distributors/notes-for-distributors/#image-customization
[cloud-config]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
