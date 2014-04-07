---
layout: docs
slug: pxe
title: Booting with PXE
category: running_coreos
sub_category: bare_metal
weight: 5
---

# Booting CoreOS via PXE

CoreOS is currently in heavy development and actively being tested. These instructions will walk you through booting CoreOS via PXE on real or virtual hardware. By default, this will run CoreOS completely out of RAM. CoreOS can also be [installed to disk]({{site.url}}/docs/running-coreos/bare-metal/installing-to-disk).

## Configuring pxelinux

This guide assumes you already have a working PXE server using [pxelinux][pxelinux].
If you need suggestions on how to set a server up, check out guides for [Debian][debian-pxe], [Fedora][fedora-pxe] or [Ubuntu][ubuntu-pxe].

[debian-pxe]: http://www.debian-administration.org/articles/478
[ubuntu-pxe]: https://help.ubuntu.com/community/DisklessUbuntuHowto
[fedora-pxe]: http://docs.fedoraproject.org/en-US/Fedora/7/html/Installation_Guide/ap-pxe-server.html
[pxelinux]: http://www.syslinux.org/wiki/index.php/PXELINUX

### Setting up pxelinux.cfg

When configuring the CoreOS pxelinux.cfg entry there are are three important kernel parameters:

- **root=squashfs:**: tells CoreOS to run out of the squashfs root provided in the PXE initrd
- **state=tmpfs:**: tells CoreOS to put all state into a tmpfs filesystem instead of searching for a disk labeled "STATE"
- **sshkey**: the given SSH public key will be added to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)

This is an example pxelinux.cfg file that assumes CoreOS is the only option.
You should be able to copy this verbatim into `/var/lib/tftpboot/pxelinux.cfg/default` after putting in your own SSH key.

```
default coreos
prompt 1
timeout 15

display boot.msg

label coreos
  menu default
  kernel coreos_production_pxe.vmlinuz
  append initrd=coreos_production_pxe_image.cpio.gz root=squashfs: state=tmpfs: sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
```

**Other Arguments**

- **console**: If you need a login prompt to show up on another tty besides the default append a list of console arguments e.g. `console=tty0 console=ttyS0`

### Download the files

In the config above you can see that a Kernel image and a initramfs file is needed.
Download these two files into your tftp root:

```
cd /var/lib/tftpboot
wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_pxe.vmlinuz
wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_pxe_image.cpio.gz
```

PXE booted machines cannot currently update themselves.
To update to the latest version of CoreOS download these two files again and reboot.

## Booting the Box

After setting up the PXE server as outlined above you can start the target machine in PXE boot mode.
The machine should grab the image from the server and boot into CoreOS.
If something goes wrong you can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

```
This is localhost.unknown_domain (Linux x86_64 3.10.10+) 19:53:36
SSH host key: 24:2e:f1:3f:5f:9c:63:e5:8c:17:47:32:f4:09:5d:78 (RSA)
SSH host key: ed:84:4d:05:e3:7d:e3:d0:b9:58:90:58:3b:99:3a:4c (DSA)
docker0: 172.17.42.1 fe80::e89f:b5ff:fece:979f
lo: 127.0.0.1 ::1
eth0: 10.0.2.15 fe80::5054:ff:fe12:3456
localhost login:
```

## Logging in

The IP address for the machine should be printed out to the terminal for convenience.
If it doesn't show up immediately, press enter a few times and it should show up.
Now you can simply SSH in using public key authentication:

```
ssh core@10.0.2.15
```

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest verison, assuming that the image served by the PXE server is regularly updated.

## Installation

CoreOS can be completely installed on disk or run from RAM but store user data on disk. Read more in our [Installing CoreOS guide](/docs/running-coreos/bare-metal/installing-to-disk).

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
