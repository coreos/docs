---
layout: docs
title: Libvirt
category: running_coreos
sub_category: platforms
fork_url: https://github.com/coreos/docs/blob/master/running-coreos/platforms/libvirt/index.md
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

In this guide, the example virtual machine we are creating is called coreos0 and
all files are stored in /var/lib/libvirt/images/coreos0. This is not a requirement — feel free
to substitute that path if you use another one.

### Choosing a Channel

CoreOS is released into alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes in each channel.

<div id="libvirt-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/coreos0
cd /var/lib/libvirt/images/coreos0
wget http://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/coreos0
cd /var/lib/libvirt/images/coreos0
wget http://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/coreos0
cd /var/lib/libvirt/images/coreos0
wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
  </div>
</div>

## Virtual machine configuration

Now create /tmp/coreos0.xml with the following contents:

```xml
<domain type='kvm'>
  <name>coreos0</name>
  <memory unit='KiB'>1048576</memory>
  <currentMemory unit='KiB'>1048576</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
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
    <emulator>/usr/bin/qemu-kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/coreos0/coreos_production_qemu_image.img'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='usb' index='0'>
    </controller>
    <filesystem type='mount' accessmode='squash'>
      <source dir='/var/lib/libvirt/images/coreos0/configdrive/'/>
      <target dir='config-2'/>
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
```

You can change any of these parameters later.

### Config drive

Now create a config drive file system to configure CoreOS itself:

```sh
mkdir -p /var/lib/libvirt/images/coreos0/configdrive/openstack/latest
touch /var/lib/libvirt/images/coreos0/configdrive/openstack/latest/user_data
```

The `user_data` file may contain a script for a [cloud config][cloud-config]
file. We recommend using ssh keys to log into the VM so at a minimum the
contents of `user_data` should look something like this:

```yaml
#cloud-config

ssh_authorized_keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
 ```

Note: The `$private_ipv4` and `$public_ipv4` substitution variables referenced in other documents are *not* supported on libvirt.

[cloud-config]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

### Network configuration

By default, CoreOS uses DHCP to get its network configuration. In this
example the VM will be attached directly to the local network via a bridge
on the host's eth0 and the local network. To configure a static address
add a [networkd unit][systemd-network] to `user_data`:

```yaml
#cloud-config

ssh_authorized_keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......

coreos:
    units:
      - name: 10-ens3.network
        content: |
          [Match]
          MACAddress=52:54:00:fe:b3:c0

          [Network]
          Address=203.0.113.2/24
          Gateway=203.0.113.1
          DNS=8.8.8.8
```

[systemd-network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html


## Virtual machine startup

Now import the XML as new VM into your libvirt instance and start it:

```sh
virsh create /tmp/coreos0.xml
```

Once the virtual machine has started you can log in via SSH:

```sh
ssh core@203.0.113.2
```

### SSH Config

To simplify this and avoid potential host key errors in the future add
the following to `~/.ssh/config`:

```ini
Host coreos0
HostName 203.0.113.2
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```sh
ssh coreos0
```


## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
