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

When configuring the CoreOS pxelinux.cfg there are a few kernel options that may be useful but all are optional:

- **rootfstype=tmpfs**: Use tmpfs for the writable root filesystem. This is the default behavior.
- **rootfstype=btrfs**: Use btrfs in ram for the writable root filesystem. Use this option if you want to use docker without any further configuration. *Experimental*
- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted in advance but may be completely blank, it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **coreos.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=ttyS0 coreos.autologin=ttyS0`. Without any argument it enables access on all consoles. *Experimental*
- **cloud-config-url**: CoreOS will attempt to download a cloud-config document and use it to provision your booted system. See the [coreos-cloudinit-project][cloudinit] for more information.

[cloudinit]: https://github.com/coreos/coreos-cloudinit

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
  append initrd=coreos_production_pxe_image.cpio.gz sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAYQC2PxAKTLdczK9+RNsGGPsz0eC2pBlydBEcrbI7LSfiN7Bo5hQQVjki+Xpnp8EEYKpzu6eakL8MJj3E28wT/vNklT1KyMZrXnVhtsmOtBKKG/++odpaavdW2/AU0l7RZiE= coreos pxe demo"
```

### Download the files

In the config above you can see that a Kernel image and a initramfs file is needed.
Download these two files into your tftp root.
The extra `coreos_production_pxe.DIGESTS.asc` file can be used to [verify the others][verify-notes].

```
cd /var/lib/tftpboot
wget http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_pxe.vmlinuz
wget http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_pxe_image.cpio.gz
wget http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_pxe.DIGESTS.asc
```

PXE booted machines cannot currently update themselves.
To update to the latest version of CoreOS download/verify these files again and reboot.

[verify-notes]: {{site.url}}/docs/sdk-distributors/distributors/notes-for-distributors/#importing-images

## Booting the Box

After setting up the PXE server as outlined above you can start the target machine in PXE boot mode.
The machine should grab the image from the server and boot into CoreOS.
If something goes wrong you can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

```
This is localhost.unknown_domain (Linux x86_64 3.10.10+) 19:53:36
SSH host key: 24:2e:f1:3f:5f:9c:63:e5:8c:17:47:32:f4:09:5d:78 (RSA)
SSH host key: ed:84:4d:05:e3:7d:e3:d0:b9:58:90:58:3b:99:3a:4c (DSA)
ens0: 10.0.2.15 fe80::5054:ff:fe12:3456
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

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

Once booted it is possible to [install CoreOS on a local disk][install-to-disk] or to just use local storage for the writable root filesystem while continuing to boot CoreOS itself via PXE.
If you plan on using Docker we recommend using a local btrfs filesystem but ext4 is also available if supporting Docker is not required.
For example, to setup a btrfs root filesystem on `/dev/sda`:

```
cfdisk -z /dev/sda
touch "/usr.squashfs (deleted)"     # work around a bug in mkfs.btrfs 3.12
mkfs.btrfs -L ROOT /dev/sda1
```

And add `root=/dev/sda1` or `root=LABEL=ROOT` to the kernel options as documented above.

[install-to-disk]: {{site.url}}/docs/running-coreos/bare-metal/installing-to-disk

## Adding a Custom OEM

Similar to the [OEM partition][oem] in CoreOS disk images, PXE images can be customized with a [cloud config][cloud-config] bundled in the initramfs. Simply create a `./usr/share/oem/` directory containing `cloud-config.yml` and append it to the cpio:

```
mkdir -p usr/share/oem
cp cloud-config.yml ./usr/share/oem
gzip -d coreos_production_pxe_image.cpio.gz
find usr | cpio -o -A -H newc -O coreos_production_pxe_image.cpio
gzip coreos_production_pxe_image.cpio
```

Confirm the archive looks correct and has your `run` file inside of it:

```
gzip -dc coreos_production_pxe_image.cpio.gz | cpio -it
./
usr.squashfs
usr
usr/share
usr/share/oem
usr/share/oem/cloud-config.yml
```

[oem]: {{site.url}}/docs/sdk-distributors/distributors/notes-for-distributors/#image-customization
[cloud-config]: {{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
