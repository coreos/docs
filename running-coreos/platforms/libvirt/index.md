---
layout: docs
title: Libvirt
category: running_coreos
sub_category: platforms
weight: 5
---

# Running CoreOS on libvirt

This guide explains how to run CoreOS with libvirt. The libvirt configuration
file can be used (for example) with virsh or virt-manager. The guide assumes
that you already have a running libvirt setup. If you don’t have that, other
solutions are most likely easier.

You can direct questions to the [IRC channel][irc] or [mailing
list][coreos-dev].

## Download the CoreOS image

In this guide, the example virtual machine we are creating is called dock0 and
all files are stored in /usr/src/dock0. This is not a requirement — feel free
to substitute that path if you use another one.

We start by downloading the most recent disk image:

    mkdir -p /usr/src/dock0
    cd /usr/src/dock0
    wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_qemu_image.img.bz2
    bunzip2 coreos_production_qemu_image.img.bz2

## Virtual machine configuration

Now create /tmp/dock0.xml with the following contents:

    <domain type='kvm'>
      <name>dock0</name>
      <memory unit='KiB'>1048576</memory>
      <currentMemory unit='KiB'>1048576</currentMemory>
      <vcpu placement='static'>1</vcpu>
      <os>
        <type arch='x86_64' machine='pc-0.15'>hvm</type>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <pae/>
      </features>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>
      <devices>
        <emulator>/usr/bin/kvm</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='/usr/src/dock0/coreos_production_qemu_image.img'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <controller type='usb' index='0'>
        </controller>
        <filesystem type='mount' accessmode='squash'>
          <source dir='/usr/src/dock0/metadata/'/>
          <target dir='metadata'/>
          <readonly/>
        </filesystem>
        <interface type='direct'>
          <mac address='52:54:00:fe:b3:c0'/>
          <source dev='eth0' mode='bridge'/>
          <model type='virtio'/>
        </interface>
        <serial type='pty'>
          <target port='0'/>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>
        <input type='tablet' bus='usb'/>
        <input type='mouse' bus='ps2'/>
        <graphics type='vnc' port='-1' autoport='yes'/>
        <sound model='ich6'>
        </sound>
        <video>
          <model type='cirrus' vram='9216' heads='1'/>
        </video>
        <memballoon model='virtio'>
        </memballoon>
      </devices>
    </domain>

You can change any of these parameters later.

Now import the XML as new VM into your libvirt instance:

    virsh create /tmp/dock0.xml

### Network configuration

By default, CoreOS uses DHCP to get its network configuration, but in my
libvirt setup, I connect the VMs with a bridge to eth0.

To make CoreOS use custom networking settings, you can mount the image’s OEM
partition and add a run.sh shell script:

    modprobe nbd max_part=63
    qemu-nbd -c /dev/nbd0 /usr/src/dock0/coreos_production_qemu_image.img
    mkdir /mnt/oem
    mount /dev/nbd0p6 /mnt/oem
    cat > /mnt/oem/run.sh <<'EOT'
    #!/bin/bash
    systemctl disable dhcpcd.service
    systemctl stop dhcpcd.service
    ip -4 address flush dev eth0
    ip -4 address add 203.0.113.2/24 dev eth0
    ip -4 link set dev eth0 up
    ip -4 route add default via 203.0.113.1
    echo nameserver 8.8.8.8 > /etc/resolv.conf
    EOT
    chmod +x /mnt/oem/run.sh
    umount /mnt/oem
    qemu-nbd -d /dev/nbd0

### SSH Keys

Copy your SSH public key to /usr/src/dock0/metadata/authorized_keys:

    mkdir /usr/src/dock0/metadata
    cp ~/.ssh/id_rsa.pub /usr/src/dock0/metadata/authorized_keys

The metadata directory is configured to be mounted and the authorized_keys file
inside will be picked up by CoreOS.

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
