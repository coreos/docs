# Running CoreOS Container Linux on libvirt

This guide explains how to run Container Linux with libvirt using the QEMU driver. The libvirt configuration
file can be used (for example) with `virsh` or `virt-manager`. The guide assumes
that you already have a running libvirt setup and `virt-install` tool. If you
don’t have that, other solutions are most likely easier.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Download the CoreOS Container Linux image

In this guide, the example virtual machine we are creating is called container-linux1 and
all files are stored in `/var/lib/libvirt/images/container-linux`. This is not a requirement — feel free
to substitute that path if you use another one.

### Choosing a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

<div id="libvirt-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/container-linux
cd /var/lib/libvirt/images/container-linux
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2{,.sig}
gpg --verify coreos_production_qemu_image.img.bz2.sig
bunzip2 coreos_production_qemu_image.bz2</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/container-linux
cd /var/lib/libvirt/images/container-linux
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2{,.sig}
gpg --verify coreos_production_qemu_image.img.bz2.sig
bunzip2 coreos_production_qemu_image.bz2</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/container-linux
cd /var/lib/libvirt/images/container-linux
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2{,.sig}
gpg --verify coreos_production_qemu_image.img.bz2.sig
bunzip2 coreos_production_qemu_image.bz2</pre>
    </div>
  </div>
</div>

## Virtual machine configuration

Now create a qcow2 image snapshot using the command below:

```sh
cd /var/lib/libvirt/images/container-linux
qemu-img create -f qcow2 -b coreos_production_qemu_image.img container-linux1.qcow2
```

This will create a `container-linux1.qcow2` snapshot image. Any changes to `container-linux1.qcow2` will not be reflected in `coreos_production_qemu_image.img`. Making any changes to a base image (`coreos_production_qemu_image.img` in our example) will corrupt its snapshots.

### Ignition config

The preferred way to configure a Container Linux machine is via Ignition.
Unfortunately, libvirt does not have direct support for Ignition yet, so configuring it involves including qemu-specific xml.

This configuration can be done in the following steps:

#### Create the Igntion config

Typically you won't write Ignition files yourself, rather you will typically use a tool like the [config transpiler](https://coreos.com/os/docs/latest/overview-of-ct.html) to generate them.

However the Ignition file is created, it should be placed in a location which qemu can access. In this example, we'll place it in `/var/lib/libvirt/container-linux/container-linux1/provision.ign`.

```sh
mkdir -p /var/lib/libvirt/container-linux/container-linux1/
echo '{"ignition":{"version":"2.0.0"}}' > /var/lib/libvirt/container-linux/container-linux1/provision.ign
```

If the host uses SELinux, allow the VM access to the config:

```sh
semanage fcontext -a -t virt_content_t "/var/lib/libvirt/container-linux/container-linux1"
restorecon -R "/var/lib/libvirt/container-linux/container-linux1"
```

A simple Container Linux config to add your ssh keys might look like the following:

```yaml container-linux-config
storage:
  files:
  - path: /etc/hostname
    filesystem: "root"
    contents:
      inline: "container-linux1"

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

#### Creating the domain xml

Once the Ignition file exists on disk, the machine can be configured to use it.

Start by creating a libvirt [domain XML](https://libvirt.org/formatdomaincaps.html) document:


```sh
virt-install --connect qemu:///system \
             --import \
             --name container-linux1 \
             --ram 1024 --vcpus 1 \
             --os-type=linux \
             --os-variant=virtio26 \
             --disk path=/var/lib/libvirt/images/container-linux/container-linux1.qcow2,format=qcow2,bus=virtio \
             --vnc --noautoconsole \
             --print-xml > /var/lib/libvirt/container-linux/container-linux1/domain.xml
```

Next, modify the domain xml to reference the qemu-specific configuration needed:

```xml
<?xml version="1.0"?>
<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
  ...
  <qemu:commandline>
    <qemu:arg value="-fw_cfg"/>
    <qemu:arg value="name=opt/com.coreos/config,file=/var/lib/libvirt/container-linux/container-linux1/provision.ign"/>
  </qemu:commandline>
</domain>
```

If you have the `xmlstarlet` utility installed, the above modification can be accomplished easily with the following:

```sh
domain=/var/lib/libvirt/container-linux/container-linux1/domain.xml
ignition_file=/var/lib/libvirt/container-linux/container-linux1/provision.ign

xmlstarlet ed -P -L -i "//domain" -t attr -n "xmlns:qemu" --value "http://libvirt.org/schemas/domain/qemu/1.0" "${domain}"
xmlstarlet ed -P -L -s "//domain" -t elem -n "qemu:commandline" "${domain}"
xmlstarlet ed -P -L -s "//domain/qemu:commandline" -t elem -n "qemu:arg" "${domain}"
xmlstarlet ed -P -L -s "(//domain/qemu:commandline/qemu:arg)[1]" -t attr -n "value" -v "-fw_cfg" "${domain}"
xmlstarlet ed -P -L -s "//domain/qemu:commandline" -t elem -n "qemu:arg" "${domain}"
xmlstarlet ed -P -L -s "(//domain/qemu:commandline/qemu:arg)[2]" -t attr -n "value" -v "name=opt/com.coreos/config,file=${ignition_file}" "${domain}"
```

Alternately, you can accomplish the same modification using sed:

```sh
domain=/var/lib/libvirt/container-linux/container-linux1/domain.xml
ignition_file=/var/lib/libvirt/container-linux/container-linux1/provision.ign

sed -i 's|type="kvm"|type="kvm" xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0"|' "${domain}"
sed -i "/<\/devices>/a <qemu:commandline>\n  <qemu:arg value='-fw_cfg'/>\n  <qemu:arg value='name=opt/com.coreos/config,file=${ignition_file}'/>\n</qemu:commandline>" "${domain}"
```

#### Define and start the machine

Once the XML domain has been edited to include the Ignition file, it can be created and started using the `virsh` tool included with libvirt:

```sh
virsh define /var/lib/libvirt/container-linux/container-linux1/domain.xml
virsh start container-linux1 
```

#### SSH into the machine

By default, libvirt runs its own DHCP server which will provide an IP address to new instances. You can query it for what IP addresses have been assigned to machines:

```sh
$ virsh net-dhcp-leases default
Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
 2017-08-09 16:32:52  52:54:00:13:12:45  ipv4      192.168.122.184/24        container-linux1 ff:32:39:f9:b5:00:02:00:00:ab:11:06:6a:55:ed:5d:0a:73:ee
```


### Network configuration

#### Static IP

By default, Container Linux uses DHCP to get its network configuration. In this example the VM will be attached directly to the local network via a bridge on the host's virbr0 and the local network. To configure a static address add a [networkd unit][systemd-network] to the Container Linux config:

```yaml container-linux-config
passwd:
  users:
  - name: core
    ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......

storage:
  files:
  - path: /etc/hostname
    filesystem: "root"
    contents: 
      inline: container-linux1

networkd:
  units:
  - name: 10-ens3.network
    contents: |
      [Match]
      MACAddress=52:54:00:fe:b3:c0

      [Network]
      Address=192.168.122.2
      Gateway=192.168.122.1
      DNS=8.8.8.8
```

[systemd-network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html

#### Using DHCP with a libvirt network

An alternative to statically configuring an IP at the host level is to do so at the libvirt level. If you're using libvirt's built in DHCP server and a recent libvirt version, it allows configuring what IP address will be provided to a given machine ahead of time.

This can be done using the `net-update` command. The following assumes you're using the `default` libvirt network and have configured the MAC Address to `52:54:00:fe:b3:c0` through the `--network` flag on `virt-install`:

```sh
ip="192.168.122.2"
mac="52:54:00:fe:b3:c0"

virsh net-update --network "default" add-last ip-dhcp-host \
    --xml "<host mac='${mac}' ip='${ip}' />" \
    --live --config
```

By executing these commands before running `virsh start`, we can ensure the libvirt DHCP server will hand out a known IP.


## Virtual machine startup

Now, start this libvirt instance with the RAM, vCPU, and networking configuration defined above:

```sh
ignition_file=/var/lib/libvirt/container-linux/container-linux1/provision.ign

domain=/var/lib/libvirt/container-linux/container-linux1/domain.xml
ip="192.168.122.2"
mac="52:54:00:fe:b3:c0"

mkdir -p "$(dirname "${domain}")"

virsh net-update --network "default" add-last ip-dhcp-host \
    --xml "<host mac='${mac}' ip='${ip}' />" \
    --live --config

virt-install --connect qemu:///system --import \
  --name container-linux1 \
  --ram 1024 --vcpus 1 \
  --os-type=linux \
  --os-variant=virtio26 \
  --disk path=/var/lib/libvirt/images/container-linux/container-linux1.qcow2,format=qcow2,bus=virtio \
  --network bridge=virbr0,mac=52:54:00:fe:b3:c0 \
  --vnc --noautoconsole \
  --print-xml > /var/lib/libvirt/container-linux/container-linux1/domain.xml

sed -ie 's|type="kvm"|type="kvm" xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0"|' "${domain}"
sed -i "/<\/devices>/a <qemu:commandline>\n  <qemu:arg value='-fw_cfg'/>\n  <qemu:arg value='name=opt/com.coreos/config,file=${ignition_file}'/>\n</qemu:commandline>" "${domain}"

virsh define /var/lib/libvirt/container-linux/container-linux1/domain.xml
virsh start container-linux1
```

Once the virtual machine has started you can log in via SSH:

```sh
ssh core@192.168.122.2
```

### SSH Config

To simplify this and avoid potential host key errors in the future add the following to `~/.ssh/config`:

```ini
Host container-linux1
HostName 192.168.122.2
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```sh
ssh container-linux1
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).

[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev
[irc]: irc://irc.freenode.org:6667/#coreos
