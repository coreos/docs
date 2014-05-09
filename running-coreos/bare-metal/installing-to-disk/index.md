---
layout: docs
slug: pxe
title: Installing to Disk
category: running_coreos
sub_category: bare_metal
weight: 7
---

# Installing CoreOS to Disk

## Install Script

There is a simple installer that will destroy everything on the given target disk and install CoreOS.
Essentially it downloads an image, verifies it with gpg and then copies it bit for bit to disk.

The script is self-contained and located [on Github here](https://raw.github.com/coreos/init/master/bin/coreos-install "coreos-install") and can be run from any Linux distribution.

If you have already booting CoreOS via PXE, the install script is already installed. By default the install script will attempt to install the same version and channel that was PXE-booted:

```
coreos-install -d /dev/sda
```

## Choose a Channel

CoreOS is released into alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

<div id="install">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      <p>If you want to ensure you are installing the latest alpha version, use the <code>-V</code> option:</p>
      <pre>coreos-install -d /dev/sda -V alpha</pre>
    </div>
    <div class="tab-pane active" id="beta-create">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      <p>If you want to ensure you are installing the latest beta version, use the <code>-V</code> option:</p>
      <pre>coreos-install -d /dev/sda -V beta</pre>
    </div>
  </div>
</div>

For reference here are the rest of the `coreos-install` options:

    -d DEVICE   Install CoreOS to the given device.
    -V VERSION  Version to install (e.g. alpha)
    -o OEM      OEM type to install (e.g. openstack)
    -c CLOUD    Insert a cloud-init config to be executed on boot.
    -t TMPDIR   Temporary location with enough space to download images.

## Cloud Config

By default there isn't a password or any other way to log into a fresh CoreOS system.
The easiest way to configure accounts, add systemd units, and more is via cloud config.
Jump over to the [docs to learn about the supported features][cloud-config].
As an example this will install a ssh key for the default `core` user:

```
#cloud-config

ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h...
```

Pass this file to `coreos-install` via the `-c` option.
It will be installed to `/var/lib/coreos-install/user_data` and evaluated on every boot.

```
coreos-install -d /dev/sda -c ~/config
```

[cloud-config]: {{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config

## Manual Tweaks

If cloud config doesn't handle something you need to do or you just want to take a look at the root btrfs filesystem before booting your new install just mount the ninth partition:

```
mount -o subvol=root /dev/sda9 /mnt/
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
