# Running CoreOS Container Linux on VMware

These instructions walk through running Container Linux on VMware Fusion or ESXi. If you are familiar with another VMware product, you can use these instructions as a starting point.

## Running the VM

### Choosing a channel

Container Linux is released into alpha, beta, and stable channels. Releases to each channel serve as a release candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel. Read the [release notes][release notes] for specific features and bug fixes in each channel.

<div id="vmware-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
       </div>
      <pre>curl -LO https://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      </div>
      <pre>curl -LO https://alpha.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      </div>
      <pre>curl -LO https://beta.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
  </div>
</div>

[release notes]: https://coreos.com/releases/

### Booting with VMware ESXi

Use the vSphere Client to deploy the VM as follows:

1. In the menu, click `File` > `Deploy OVF Template...`
2. In the wizard, specify the location of the OVA file downloaded earlier
3. Name your VM
4. Choose "thin provision" for the disk format
5. Choose your network settings
6. Confirm the settings, then click "Finish"

Uncheck `Power on after deployment` in order to edit the VM before booting it the first time.

The last step uploads the files to the ESXi datastore and registers the new VM. You can now tweak VM settings, then power it on.

*NB: These instructions were tested with an ESXi v5.5 host.*

### Booting with VMware Workstation 12 or VMware Fusion

Run VMware Workstation GUI:

1. In the menu, click `File` > `Open...`
2. In the wizard, specify the location of the OVA template downloaded earlier
3. Name your VM, then click `Import`
4. (Press `Retry` *if* VMware Workstation raises an "OVF specification" warning)
5. Edit VM settings if necessary
6. Create a cloud-config image (see below) containing at least one valid SSH key using a [config drive](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/config-drive.md).
    * On Fusion, simply connect and mount this image as the CD, ignoring the instruction below regarding the filesystem label which are not applicable.
7. Start your Container Linux VM

*NB: These instructions were tested with a Fusion 8.1 host.*

## Ignition config

Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Ignition. Head over to the [docs to learn about the supported features][ignition-docs].

You can provide a raw Ignition config to Container Linux via VMware's [Guestinfo interface](#vmware-guestinfo-interface).

As an example, this config will start etcd and add the provided password and SSH key to the user "core":

```container-linux-config
systemd:
  units:
    - name: etcd2.service
      enable: true

passwd:
  users:
    - name: core
      password_hash: $6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm...
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq...
```

[ignition-docs]: https://coreos.com/ignition/docs/latest

## Cloud-config

Cloud-config data can be passed into a VM by attaching a [config-drive][config-drive] with the filesystem label `config-2`. This is done in the same way as attaching CD-ROMs or other new drives.

The config-drive standard was originally an OpenStack feature, which is why you'll see the string `openstack` in a few bits of configuration. This naming convention is retained, although Container Linux supports config-drive on all platforms.

This example will configure Container Linux components: etcd2 and fleetd. `$private_ipv4` and `$public_ipv4` are supported on VMware in Container Linux releases 801.0.0 and greater, and **only** when you explicitly configure interfaces' roles to `private` or `public` in [Guestinfo][guestinfo] for each VMware instance.

```cloud-config
#cloud-config

# include one or more SSH public keys
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

For details on the options available with cloud-config, see the [cloud-config guide][cloud-config guide].

## VMware Guestinfo interface

### Setting Guestinfo options

The VMware guestinfo interface is an alternative to using a config-drive for VM configuration. Guestinfo properties are stored in the VMX file, or in the VMX representation in host memory. These properties are available to the VM at boot time. Within the VMX, the names of these properties are prefixed with `guestinfo.`. Guestinfo settings can be injected into VMs in one of four ways:

* Configure guestinfo in the OVF for deployment. Software like [vcloud director][vcloud director] manipulates OVF descriptors for guest configuration. For details, check out this VMware blog post about [Self-Configuration and the OVF Environment][ovf-selfconfig].

* Set guestinfo keys and values from the Container Linux guest itself, by using a VMware Tools command like:

```sh
/usr/share/oem/bin/vmtoolsd --cmd "info-set guestinfo.<variable> <value>"
```

* Guestinfo keys and values can be set from a VMware Service Console, using the `setguestinfo` subcommand:

```sh
vmware-cmd /vmfs/volumes/[...]/<VMNAME>/<VMNAME>.vmx setguestinfo guestinfo.<property> <value>
```

* You can manually modify the VMX and reload it on the VMware Workstation, ESXi host, or in vCenter.

Guestinfo configuration set via the VMware API or with `vmtoolsd` from within the Container Linux guest itself are stored in VM process memory and are lost on VM shutdown or reboot.

[This blog post][vmware-use-guestinfo] has some useful details about the guestinfo interface, while Robert Labrie's blog provides a practicum specific to [using VMware guestinfo to configure Container Linux VMs][labrie-guestinfo].

### Defining the Ignition config in Guestinfo

If the `guestinfo.coreos.config.data` property is set, Ignition will apply the referenced config on first boot.

The Ignition config is prepared for the guestinfo facility in one of two encoding types, specified in the `guestinfo.coreos.config.data.encoding` variable:

|    Encoding    |                        Command                        |
|:---------------|:------------------------------------------------------|
| &lt;elided&gt; | `sed -e 's/%/%%/g' -e 's/"/%22/g' /path/to/user_data` |
| base64         | `base64 -w0 /path/to/user_data && echo`               |

#### Example

```
guestinfo.coreos.config.data = "ewogICJpZ25pdGlvbiI6IHsgInZlcnNpb24iOiAiMi4wLjAiIH0KfQo="
guestinfo.coreos.config.data.encoding = "base64"
```

This example will be decoded into:

```json
{
  "ignition": { "version": "2.0.0" }
}
```

### Guestinfo example for cloud-config

This example sets the hostname, interface role, static IP address, and several other network interface parameters to the VM ethernet interface matching the `.mac` and `.name` values given in the following VMX snippet:

```
guestinfo.hostname = "coreos"
guestinfo.interface.0.role = "private"
guestinfo.dns.server.0 = "8.8.8.8"
guestinfo.interface.0.route.0.gateway = "192.168.178.1"
guestinfo.interface.0.route.0.destination = "0.0.0.0/0"
guestinfo.interface.0.mac = "00:0c:29:63:92:5c"
guestinfo.interface.0.name = "eno1*"
guestinfo.interface.0.dhcp = "no"
guestinfo.interface.0.ip.0.address = "192.168.178.97/24"
```

The Container Linux OVA image contains the VMware tools, and a OEM cloud-config which executes `coreos-cloudinit` with the `--oem=vmware` option. This option automatically sets the additional `--from-vmware-guestinfo` and `--convert-netconf=vmware` flags. Given the `guestinfo.*` values above and these option flags, `coreos-cloudinit` will generate the following systemd network unit:

```
[Match]
Name=eno1*
MACAddress=00:0c:29:63:92:5c

[Network]
DNS=8.8.8.8

[Address]
Address=192.168.178.97/24

[Route]
Destination=0.0.0.0/0
Gateway=192.168.178.1
```

This unit file will subsequently configure the matching network interface.

### Defining cloud-config in Guestinfo

If either the `guestinfo.coreos.config.data` or `guestinfo.coreos.config.url` property is set, `coreos-cloudinit` will apply the referenced cloud-config. Cloudinit will substitute the `$private_ipv4` and `$public_ipv4` variables if you've configured network interface roles using the `guestinfo.interface.<n>.role` property.

Cloud-config data is prepared for the guestinfo facility in one of two encoding types, specified in the `guestinfo.coreos.config.data.encoding` variable:

|  Encoding   |                      Command                      |
|:------------|:--------------------------------------------------|
| base64      | `base64 -w0 /path/to/user_data && echo`           |
| gzip+base64 | `gzip -c /path/to/user_data | base64 -w0 && echo` |

To avoid having to `base64` or otherwise encode raw data into your VMX, you can retrieve your cloud-config from a URL specified in the `guestinfo.coreos.config.url` variable instead.

#### Example

```
guestinfo.coreos.config.data = "H4sICP9nAVYAA3VzZXJfZGF0YQBTTs7JL03RTc7PS8tM5youzohPLC3JyC/KrEpNic9OrSy24lLQVQCK6xYVJyrkVhaUJgFFuQCe+rhmNwAAAA=="
guestinfo.coreos.config.data.encoding = "gzip+base64"
```

This example will be decoded into:

```cloud-config
#cloud-config
ssh_authorized_keys:
 - ssh-rsa mypubkey
```

Refer to the [VMware guestinfo variables documentation][VMware guestinfo] for a full list of supported properties.

## Logging in

Networking can take some time to start under VMware. Once it does, press enter a few times at the login prompt and you should see an IP address printed on the console:

![VMware IP Address](img/vmware-ip.png)

In this case the IP is `10.0.1.81`.

Now you can login to the host at that IP using your SSH key, or the password set in your cloud-config:

```sh
ssh core@10.0.1.81
```

Alternatively, appending `coreos.autologin` to the kernel parameters at boot causes the console to accept the `core` user's login with no password. This is handy for debugging.

## Using CoreOS Container Linux

Now that you have a machine booted, it's time to explore. Check out the [Container Linux Quickstart][quickstart] guide, or dig into [more specific topics][docs].

[quickstart]: quickstart.md
[docs]: https://github.com/coreos/docs
[config-drive]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/config-drive.md
[cloud-config guide]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit
[VMware guestinfo]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/vmware-guestinfo.md
[vcloud director]: http://blogs.vmware.com/vsphere/2012/06/leveraging-vapp-vm-custom-properties-in-vcloud-director.html
[ovf-selfconfig]: http://blogs.vmware.com/vapp/2009/07/selfconfiguration-and-the-ovf-environment.html
[vmware-use-guestinfo]: http://blog-lrivallain.rhcloud.com/2014/08/15/vmware-use-guestinfo-variables-to-customize-guest-os/
[labrie-guestinfo]: https://robertlabrie.wordpress.com/2015/09/27/coreos-on-vmware-using-vmware-guestinfo-api/
[guestinfo]: #guestinfo-example
