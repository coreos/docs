---
layout: docs
slug: qemu
title: QEMU
category: running_coreos
sub_category: platforms
weight: 5
---

# Running CoreOS on QEMU

CoreOS is currently in heavy development and actively being tested.
These instructions will bring up a single CoreOS instance under QEMU,
the small Swiss Army knife of virtual machine and CPU emulators.
If you need to do more such as [configuring networks][qemunet]
differently refer to the [QEMU Wiki][qemuwiki] and [User
Documentation][qemudoc].

You can direct questions to the [IRC channel][irc] or [mailing
list][coreos-dev].

[qemunet]: http://wiki.qemu.org/Documentation/Networking
[qemuwiki]: http://wiki.qemu.org/Manual
[qemudoc]: http://qemu.weilnetz.de/qemu-doc.html


## Install QEMU

In addition to Linux it can be run on Windows and OSX but works best on
Linux. It should be available on just about any distro.

### Debian or Ubuntu

Documentation for [Debian][qemudeb] has more details but to get started
all you need is:

    sudo apt-get install qemu-system-x86 qemu-utils

[qemudeb]: https://wiki.debian.org/QEMU

### Fedora or Red Hat

The Fedora wiki has a [quick howto][qemufed] but the basic install is easy:

    sudo yum install qemu-system-x86 qemu-img

[qemufed]: https://fedoraproject.org/wiki/How_to_use_qemu

### Arch

This is all you need to get started:

    sudo pacman -S qemu

More details can be found on [Arch's QEMU wiki page](https://wiki.archlinux.org/index.php/Qemu).

### Gentoo

As to be expected Gentoo can be a little more complicated but all the
required kernel options and USE flags are covered in the [Gentoo
Wiki][qemugen]. Usually this should be sufficient:

    echo app-emulation/qemu qemu_softmmu_targets_x86_64 virtfs xattr >> /etc/portage/package.use
    emerge -av app-emulation/qemu

[qemugen]: http://wiki.gentoo.org/wiki/QEMU


## Startup CoreOS

Once QEMU is installed you can download and start the latest CoreOS
image. There are two files you need: the disk image (provided in qcow2
format) and the wrapper shell script to start QEMU.

    mkdir coreos; cd coreos
    wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_qemu.sh
    wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img
    chmod +x coreos_production_qemu.sh

Starting is as simple as:

    ./coreos_production_qemu.sh -nographic

### SSH Keys

In order to log in to the virtual machine you will need to use ssh keys.
If you don't already have a ssh key pair you can generate one simply by
running the command `ssh-keygen`. The wrapper script will automatically
look for public keys in ssh-agent if available and at the default
locations `~/.ssh/id_dsa.pub` or `~/.ssh/id_rsa.pub`. If you need to
provide an alternate location use the -a option:

    ./coreos_production_qemu.sh -a ~/.ssh/authorized_keys -- -nographic

Note: Options such as `-a` for the wrapper script must be specified before
any options for QEMU. To make the separation between the two explicit
you can use `--` but that isn't required. See
`./coreos_production_qemu.sh -h` for details.

Once the virtual machine has started you can log in via SSH:

    ssh -l core -p 2222 localhost

### SSH Config

To simplify this and avoid potential host key errors in the future add
the following to `~/.ssh/config`:

    Host coreos
    HostName localhost
    Port 2222
    User core
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Now you can log in to the virtual machine with:

    ssh coreos


## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
