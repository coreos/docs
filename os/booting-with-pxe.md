# Booting CoreOS Container Linux via PXE

These instructions will walk you through booting Container Linux via PXE on real or virtual hardware. By default, this will run Container Linux completely out of RAM. Container Linux can also be [installed to disk](installing-to-disk.md).

A mininum of 1024M of RAM is required to boot Container Linux via PXE.

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
- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted in advance but may be completely blank, it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **coreos.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 coreos.autologin=tty1 coreos.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).
- **coreos.config.url**: Container Linux will attempt to download an Ignition config and use it to provision your booted system. Ignition configs are generated from Container Linux Configs. See the [config transpiler documentation][cl-configs] for more information.

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
  append coreos.config.url=https://example.com/pxe-config.ign
```

Here's a common config example which should be located at the URL from above:

```container-linux-config
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

Container Linux is released into alpha, beta, and stable channels. Releases to each channel serve as a release candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

PXE booted machines cannot currently update themselves when new versions are released to a channel. To update to the latest version of Container Linux download/verify these files again and reboot.

<div id="pxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
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

For example, to setup an ext4 root filesystem on '/dev/sda':

```sh
cfdisk -z /dev/sda
mkfs.ext4 -L ROOT /dev/sda1
```

And add `root=/dev/sda1` or `root=LABEL=ROOT` to the kernel options as documented above.

Similarly, to setup a btrfs root filesystem on `/dev/sda`:

```sh
cfdisk -z /dev/sda
mkfs.btrfs -L ROOT /dev/sda1
```

## Adding a Custom OEM

Similar to the [OEM partition][oem] in Container Linux disk images, PXE images can be customized with an [Ignition config][ignition] bundled in the initramfs. Simply create a `./usr/share/oem/` directory containing the Ignition config (e.g. `example.ign`), add it as an additional initramfs, and boot it specifying the path to the config using `coreos.config.url`:

```sh
mkdir -p usr/share/oem
cp example.ign ./usr/share/oem
find usr | cpio -o -A -H newc -O oem.cpio
gzip oem.cpio
```

Confirm the archive looks correct and has your config inside of it:

```sh
gzip --stdout --decompress oem.cpio.gz | cpio -it
./
usr
usr/share
usr/share/oem
usr/share/oem/example.ign
```

Add the `oem.cpio.gz` file to your PXE boot directory, then [append it][append-initrd] to the `initrd` line in your `pxelinux.cfg`. Finally, specify the URL of the config in the `kernel` line:

```
...
initrd coreos_production_pxe_image.cpio.gz,oem.cpio.gz
kernel coreos_production_pxe.vmlinuz coreos.config.url=oem:///example.ign
...
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart][qs] guide or dig into [more specific topics][docs].


[append-initrd]: http://www.syslinux.org/wiki/index.php?title=SYSLINUX#INITRD_initrd_file
[coreos-user]: https://groups.google.com/forum/#!forum/coreos-user
[docs]: https://coreos.com/docs
[install-to-disk]: installing-to-disk.md
[cl-configs]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/getting-started.md
[irc]: irc://irc.freenode.org:6667/#coreos
[oem]: notes-for-distributors.md#image-customization
[qs]: quickstart.md
