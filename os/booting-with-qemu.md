# Running CoreOS on QEMU

These instructions will bring up a single CoreOS instance under QEMU, the small Swiss Army knife of virtual machine and CPU emulators. If you need to do more such as [configuring networks][qemunet] differently refer to the [QEMU Wiki][qemuwiki] and [User Documentation][qemudoc].

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

[qemunet]: http://wiki.qemu.org/Documentation/Networking
[qemuwiki]: http://wiki.qemu.org/Manual
[qemudoc]: http://qemu.weilnetz.de/qemu-doc.html


## Install QEMU

In addition to Linux it can be run on Windows and OS X but works best on Linux. It should be available on just about any distro.

### Debian or Ubuntu

Documentation for [Debian][qemudeb] has more details but to get started all you need is:

```sh
sudo apt-get install qemu-system-x86 qemu-utils
```

[qemudeb]: https://wiki.debian.org/QEMU

### Fedora or RedHat

The Fedora wiki has a [quick howto][qemufed] but the basic install is easy:

```sh
sudo yum install qemu-system-x86 qemu-img
```

[qemufed]: https://fedoraproject.org/wiki/How_to_use_qemu

### Arch

This is all you need to get started:

```sh
sudo pacman -S qemu
```

More details can be found on [Arch's QEMU wiki page](https://wiki.archlinux.org/index.php/Qemu).

### Gentoo

As to be expected, Gentoo can be a little more complicated but all the required kernel options and USE flags are covered in the [Gentoo Wiki][qemugen]. Usually this should be sufficient:

```sh
echo app-emulation/qemu qemu_softmmu_targets_x86_64 virtfs xattr >> /etc/portage/package.use
emerge -av app-emulation/qemu
```

[qemugen]: http://wiki.gentoo.org/wiki/QEMU


## Startup CoreOS

Once QEMU is installed you can download and start the latest CoreOS image.

### Choosing a channel

CoreOS is released into alpha, beta, and stable channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes in each channel.

<div id="qemu-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
       </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir coreos; cd coreos
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh.sig
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2.sig
gpg --verify coreos_production_qemu.sh.sig
gpg --verify coreos_production_qemu_image.img.bz2.sig
bzip2 -d coreos_production_qemu_image.img.bz2
chmod +x coreos_production_qemu.sh</pre>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. Current version is CoreOS {{site.alpha-channel}}.</p>
      </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir coreos; cd coreos
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh.sig
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2.sig
gpg --verify coreos_production_qemu.sh.sig
gpg --verify coreos_production_qemu_image.img.bz2.sig
bzip2 -d coreos_production_qemu_image.img.bz2
chmod +x coreos_production_qemu.sh</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir coreos; cd coreos
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu.sh.sig
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2.sig
gpg --verify coreos_production_qemu.sh.sig
gpg --verify coreos_production_qemu_image.img.bz2.sig
bzip2 -d coreos_production_qemu_image.img.bz2
chmod +x coreos_production_qemu.sh</pre>
    </div>
  </div>
</div>

Starting is as simple as:

```sh
./coreos_production_qemu.sh -nographic
```

### SSH keys

In order to log in to the virtual machine you will need to use ssh keys. If you don't already have a ssh key pair you can generate one simply by running the command `ssh-keygen`. The wrapper script will automatically look for public keys in ssh-agent if available and at the default locations `~/.ssh/id_dsa.pub` or `~/.ssh/id_rsa.pub`. If you need to provide an alternate location use the -a option:

```sh
./coreos_production_qemu.sh -a ~/.ssh/authorized_keys -- -nographic
```

Note: Options such as `-a` for the wrapper script must be specified before any options for QEMU. To make the separation between the two explicit you can use `--` but that isn't required. See `./coreos_production_qemu.sh -h` for details.

Once the virtual machine has started you can log in via SSH:

```sh
ssh -l core -p 2222 localhost
```

### SSH config

To simplify this and avoid potential host key errors in the future add the following to `~/.ssh/config`:

```sh
Host coreos
HostName localhost
Port 2222
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```sh
ssh coreos
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the [CoreOS Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).


[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev
[irc]: irc://irc.freenode.org:6667/#coreos
