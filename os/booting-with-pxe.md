# Booting CoreOS Container Linux via PXE

These instructions will walk you through booting Container Linux via PXE on real or virtual hardware. By default, this will run Container Linux completely out of RAM. Container Linux can also be [installed to disk](installing-to-disk.md).

A mininum of 2 GB of RAM is required to boot Container Linux via PXE.

## Configuring pxelinux

This guide assumes you already have a working PXE server using [pxelinux][pxelinux]. If you need suggestions on how to set a server up, check out guides for [Debian][debian-pxe], [Fedora][fedora-pxe] or [Ubuntu][ubuntu-pxe].

[debian-pxe]: http://www.debian-administration.org/articles/478
[ubuntu-pxe]: https://help.ubuntu.com/community/DisklessUbuntuHowto
[fedora-pxe]: http://docs.fedoraproject.org/en-US/Fedora/7/html/Installation_Guide/ap-pxe-server.html
[pxelinux]: http://www.syslinux.org/wiki/index.php/PXELINUX

### Setting up pxelinux.cfg

When configuring the Container Linux pxelinux.cfg there are a few kernel options that may be useful but all are optional.

- **rootfstype=tmpfs**: Use tmpfs for the writable root filesystem. This is the default behavior.
- **rootfstype=btrfs**: Use btrfs in RAM for the writable root filesystem. The filesystem will consume more RAM as it grows, up to a max of 50%. The limit isn't currently configurable.
- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted (perhaps using Ignition) but may be completely blank; it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **coreos.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 coreos.autologin=tty1 coreos.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).
- **coreos.first_boot=1**: Download an Ignition config and use it to provision your booted system. Ignition configs are generated from Container Linux Configs. See the [config transpiler documentation][cl-configs] for more information. If a local filesystem is used for the root partition, pass this parameter only on the first boot.
- **coreos.config.url**: Download the Ignition config from the specified URL. `http`, `https`, `s3`, and `tftp` schemes are supported.

This is an example pxelinux.cfg file that assumes Container Linux is the only option. You should be able to copy this verbatim into `/var/lib/tftpboot/pxelinux.cfg/default` after providing an Ignition config URL:

```sh
default coreos
prompt 1
timeout 15

display boot.msg

label coreos
  menu default
  kernel coreos_production_pxe.vmlinuz
  initrd coreos_production_pxe_image.cpio.gz
  append coreos.first_boot=1 coreos.config.url=https://example.com/pxe-config.ign
```

Here's a common config example which should be located at the URL from above:

```yaml container-linux-config
systemd:
  units:
    - name: etcd2.service
      enable: true

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq...
```

### Choose a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

PXE booted machines cannot currently update themselves when new versions are released to a channel. To update to the latest version of Container Linux download/verify these files again and reboot.

<div id="pxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>coreos_production_pxe.vmlinuz.sig</code> and <code>coreos_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="notes-for-distributors.md#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
gpg --verify coreos_production_pxe.vmlinuz.sig
gpg --verify coreos_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>coreos_production_pxe.vmlinuz.sig</code> and <code>coreos_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="notes-for-distributors.md#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
gpg --verify coreos_production_pxe.vmlinuz.sig
gpg --verify coreos_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>coreos_production_pxe.vmlinuz.sig</code> and <code>coreos_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="notes-for-distributors.md#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
gpg --verify coreos_production_pxe.vmlinuz.sig
gpg --verify coreos_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
  </div>
</div>

## Booting the box

After setting up the PXE server as outlined above you can start the target machine in PXE boot mode. The machine should grab the image from the server and boot into Container Linux. If something goes wrong you can direct questions to the [IRC channel][irc] or [mailing list][coreos-user].

```sh
This is localhost.unknown_domain (Linux x86_64 3.10.10+) 19:53:36
SSH host key: 24:2e:f1:3f:5f:9c:63:e5:8c:17:47:32:f4:09:5d:78 (RSA)
SSH host key: ed:84:4d:05:e3:7d:e3:d0:b9:58:90:58:3b:99:3a:4c (DSA)
ens0: 10.0.2.15 fe80::5054:ff:fe12:3456
localhost login:
```

## Logging in

The IP address for the machine should be printed out to the terminal for convenience. If it doesn't show up immediately, press enter a few times and it should show up. Now you can simply SSH in using public key authentication:

```sh
ssh core@10.0.2.15
```

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

Once booted it is possible to [install Container Linux on a local disk][install-to-disk] or to just use local storage for the writable root filesystem while continuing to boot Container Linux itself via PXE.

If you plan on using Docker we recommend using a local ext4 filesystem with overlayfs, however, btrfs is also available to use if needed.

For example, to setup an ext4 root filesystem on `/dev/sda`:

```yaml container-linux-config
storage:
  disks:
  - device: /dev/sda
    wipe_table: true
    partitions:
    - label: ROOT
  filesystems:
  - mount:
      device: /dev/disk/by-partlabel/ROOT
      format: ext4
      wipe_filesystem: true
      label: ROOT
```

And add `root=/dev/sda1` or `root=LABEL=ROOT` to the kernel options as documented above.

Similarly, to setup a btrfs root filesystem on `/dev/sda`:

```yaml container-linux-config
storage:
  disks:
  - device: /dev/sda
    wipe_table: true
    partitions:
    - label: ROOT
  filesystems:
  - mount:
      device: /dev/disk/by-partlabel/ROOT
      format: btrfs
      wipe_filesystem: true
      label: ROOT
```

## Adding a Custom OEM

Similar to the [OEM partition][oem] in Container Linux disk images, PXE images can be customized with an [Ignition config][ignition] bundled in the initramfs. Simply create a `./usr/share/oem/` directory, add a `config.ign` file containing the Ignition config, and add the directory tree as an additional initramfs:

```sh
mkdir -p usr/share/oem
cp example.ign ./usr/share/oem/config.ign
find usr | cpio -o -H newc -O oem.cpio
gzip oem.cpio
```

Confirm the archive looks correct and has your config inside of it:

```sh
gzip --stdout --decompress oem.cpio.gz | cpio -it
./
usr
usr/share
usr/share/oem
usr/share/oem/config.ign
```

Add the `oem.cpio.gz` file to your PXE boot directory, then [append it][append-initrd] to the `initrd` line in your `pxelinux.cfg`:

```
...
initrd coreos_production_pxe_image.cpio.gz,oem.cpio.gz
kernel coreos_production_pxe.vmlinuz coreos.first_boot=1
...
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart][qs] guide or dig into [more specific topics][docs].


[append-initrd]: http://www.syslinux.org/wiki/index.php?title=SYSLINUX#INITRD_initrd_file
[coreos-user]: https://groups.google.com/forum/#!forum/coreos-user
[docs]: https://coreos.com/docs
[ignition]: https://coreos.com/ignition/docs/latest
[install-to-disk]: installing-to-disk.md
[cl-configs]: provisioning.md
[irc]: irc://irc.freenode.org:6667/#coreos
[oem]: notes-for-distributors.md#image-customization
[qs]: quickstart.md
