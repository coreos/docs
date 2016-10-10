# Running CoreOS on libvirt

This guide explains how to run CoreOS with libvirt. The libvirt configuration
file can be used (for example) with `virsh` or `virt-manager`. The guide assumes
that you already have a running libvirt setup and `virt-install` tool. If you
don’t have that, other solutions are most likely easier.

You can direct questions to the [IRC channel][irc] or [mailing
list][coreos-dev].

## Download the CoreOS image

In this guide, the example virtual machine we are creating is called coreos1 and
all files are stored in `/var/lib/libvirt/images/coreos`. This is not a requirement — feel free
to substitute that path if you use another one.

### Choosing a channel

CoreOS is released into alpha, beta, and stable channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

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
mkdir -p /var/lib/libvirt/images/coreos
cd /var/lib/libvirt/images/coreos
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/coreos
cd /var/lib/libvirt/images/coreos
wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/coreos
cd /var/lib/libvirt/images/coreos
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2 -O - | bzcat > coreos_production_qemu_image.img</pre>
    </div>
  </div>
</div>

## Virtual machine configuration

Now create a qcow2 image snapshot using the command below:

```sh
cd /var/lib/libvirt/images/coreos
qemu-img create -f qcow2 -b coreos_production_qemu_image.img coreos1.qcow2
```

It will create `coreos1.qcow2` snapshot image. Any changes to `coreos1.qcow2` will not be reflected in `coreos_production_qemu_image.img`. Making any changes to a base image (`coreos_production_qemu_image.img` in our example) will corrupt its snapshots.

### Config drive

Now create a config drive file system to configure CoreOS itself:

```sh
mkdir -p /var/lib/libvirt/images/coreos/coreos1/openstack/latest
touch /var/lib/libvirt/images/coreos/coreos1/openstack/latest/user_data
```

If the host uses SELinux, allow the VM access to the config:

```sh
semanage fcontext -a -t virt_content_t "/var/lib/libvirt/images/coreos0/configdrive(/.*)?"
restorecon -R "/var/lib/libvirt/images/coreos0/configdrive"
```

The `user_data` file declares machine configuration in the [cloud config](https://coreos.com/os/docs/latest/cloud-config.html) format. We recommend using ssh keys to log into the VM, and since those keys are stored in `user_data,` at minimum that file should contain something like this:

```yaml
#cloud-config

ssh_authorized_keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
```

Note: The `$private_ipv4` and `$public_ipv4` cloud-config substitution variables referenced in other documents are not supported on libvirt. The convenience of these automatic variables can be emulated by [using nginx to host your cloud-config](nginx-host-cloud-config.md).

### Network configuration

By default, CoreOS uses DHCP to get its network configuration. In this example the VM will be attached directly to the local network via a bridge on the host's virbr0 and the local network. To configure a static address add a [networkd unit][systemd-network] to `user_data`:

```yaml
#cloud-config

ssh_authorized_keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......

hostname: coreos1

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

Now start new libvirt instance with 1024Mb of RAM and 1 CPU:

```sh
virt-install --connect qemu:///system --import --name coreos1 --ram 1024 --vcpus 1 --os-type=linux --os-variant=virtio26 --disk path=/var/lib/libvirt/images/coreos/coreos1.qcow2,format=qcow2,bus=virtio --filesystem /var/lib/libvirt/images/coreos/coreos1/,config-2,type=mount,mode=squash --network bridge=virbr0,mac=52:54:00:fe:b3:c0,type=bridge --vnc --noautoconsole
```

Once the virtual machine has started you can log in via SSH:

```sh
ssh core@203.0.113.2
```

### SSH Config

To simplify this and avoid potential host key errors in the future add the following to `~/.ssh/config`:

```ini
Host coreos1
HostName 203.0.113.2
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```sh
ssh coreos1
```

## Running a CoreOS cluster demo on libvirt

This guide explains how to run three-nodes demo CoreOS cluster with libvirt.

### Bash Script

Save following `deploy_coreos_libvirt.sh` script into your host filesystem:

```sh
wget https://raw.githubusercontent.com/coreos/docs/master/os/deploy_coreos_libvirt.sh
chmod +x deploy_coreos_libvirt.sh
```

Each libvirt instance will have 1024Mb of RAM and 1 CPU (RAM and CPUs variables).
You can change these parameters to meet your needs.

### Cloud config template

Save the following template into `/var/lib/libvirt/images/coreos/user_data`:

```yaml
#cloud-config
ssh_authorized_keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
hostname: %HOSTNAME%
coreos:
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
    - name:  systemd-networkd.service
      command: restart
    - name: flanneld.service
      drop-ins:
        - name: 50-network-config.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
      command: start
  etcd2:
    advertise-client-urls: http://%HOSTNAME%:2379
    initial-advertise-peer-urls: http://%HOSTNAME%:2380
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://0.0.0.0:2380
    discovery: %DISCOVERY%
  fleet:
    public-ip: %HOSTNAME%
```

### Virtual machines startup

Run the script:

```sh
./deploy_coreos_libvirt.sh 3
```

Script will deploy three-nodes CoreOS cluster (`coreos{1..3}` hostnames) with
ready-to-use etcd2, fleet and flannel.

If your host configuration uses libvirt's dnsmasq as a resolver, you can
simply log in into your new CoreOS instance:

```sh
ssh core@coreos1
```

Otherwise you can get IP addresses from leases file (for "default" libvirt
network):

```sh
cat /var/lib/libvirt/dnsmasq/default.leases
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).

[coreos-dev]: https://groups.google.com/forum/#!forum/coreos-dev
[irc]: irc://irc.freenode.org:6667/#coreos
