# Running CoreOS on VMware

These instructions will walk you through running CoreOS on VMware Fusion or
ESXi. If you are familiar with another VMware product you can use these
instructions as a starting point.

## Running the VM

### Choosing a Channel

CoreOS is released into stable, alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel. Read the [release notes][release notes] for specific features and bug fixes in each channel.

<div id="vmware-images">
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
      <pre>curl -LO http://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently.  Current version is CoreOS {{site.alpha-channel}}.</p>
      </div>
      <pre>curl -LO http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      </div>
      <pre>curl -LO http://beta.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova</pre>
    </div>
  </div>
</div>

[release notes]: https://coreos.com/releases/

### Booting with VMware Fusion

After downloading the proper VMware image, you will need to launch the
`coreos_production_vmware_ova.ova` file to create a VM.

### Booting with VMware ESXi

Use the vSphere Client to deploy the VM as follows:

1. in the menu, click "File > Deploy OVF Template..."
2. in the wizard, specify the location of the OVA downloaded earlier
3. name your VM
4. choose "thin provision" for the disk format
5. choose your network settings
6. confirm the settings then click "Finish"

NOTE: Unselect "Power on after deployment" so you have a chance to edit VM
settings before powering it up for the first time.

The last step uploads the files to your ESXi datastore and registers your VM.
You can now tweak the VM settings, like memory and virtual cores, then power it
on. These instructions were tested to deploy to an ESXi 5.5 host.

### Booting with VMware Workstation 12

Run VMware Workstation GUI:

1. in the menu, click "File > Open..."
2. in the wizard, specify the location of the OVA downloaded earlier
3. name your VM and then click "Import"
4. press "Retry" if VMware Workstation has raised "OVF specification" warning
5. edit VM settings if necessary
6. start up your CoreOS VM

## Cloud-Config

Cloud-config can be specified by attaching a [config-drive][config-drive] with the filesystem label `config-2`. This is commonly done through whatever interface allows for attaching CD-ROMs or new drives. Alternatively in CoreOS 801.0.0 and greater you can use [VMware GuestInfo](#vmware-backdoor).

Note that the config-drive standard was originally an OpenStack feature, which
is why you'll see strings containing `openstack`. This filepath needs to be
retained, although CoreOS supports config-drive on all platforms.

For more information on customization that can be done with cloud-config, head
on over to the [cloud-config guide][cloud-config guide].

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on VMware but only in CoreOS release 801.0.0 and greater. These releases has updated [coreos-cloudinit][coreos-cloudinit] v1.6.0 which allows you to configure network using [VMware GuestInfo options][vmware backdoor] and define `public` and `private` roles for ethernet interfaces.

## VMware Backdoor

### Setting GuestInfo Options

Guestinfo settings are values stored in the VMX of virtual machine or in the VMX representation in host memory. The criteria for being able to read it from guest OS is to use the prefix: `guestinfo.`.

These settings can be set in five main ways:

* You can configure them in the OVF you want to deploy. Some middlewares will help you to customize it during the deploy of the virtual machines based on this OVF (like [vcloud director][vcloud director]). For more information, you can have a look on the following post: [Self-Configuration and the OVF Environment][ovf-selfconfig]

* You can set guestinfo keys and values from the CoreOS guest itself by using preinstalled vmwaretools command like:

```sh
/usr/share/oem/bin/vmtoolsd --cmd "info-set guestinfo.<variable> <value>"
```

* You can also set guestinfo keys and values from a Service Console:

```sh
vmware-cmd /vmfs/volumes/xxxxxxxx.../VMNAME/VMNAME.vmx setguestinfo <variable> <value>
```

* You can manually modify the VMX and reload it on the VMware Workstation, ESXi host or the vCenter.

* If you change or set GuestInfo settings by using VMware API or CoreOS guest itself, values are only stored in VM process memory. In case of reboot or shutdown, values will be loosed.

You can read more about GuestInfo in [this][vmware-use-guestinfo] blog post.

### GuestInfo Example

Example below provides hostname, DNS address, interface role, and static `192.168.178.97` IP address with `255.255.255.0` netmask on the Ethernet interface which matches `eno1*` interface name and `00:0c:29:63:92:5c` interface mac address (you can simply provide only one match option: `name` or `mac`):

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

The CoreOS OVA image contains VMware tools and OEM Cloud-Config which executes `coreos-cloudinit` with `--oem=vmware` option. This option automatically sets the `-from-vmware-backdoor` and `-convert-netconf=vmware` flags. Using values above and these flags `coreos-cloudinit` will generate following systemd network unit:

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

This unit file will configure the matching network interface. If you have set `guestinfo.coreos.config.data` or `guestinfo.coreos.config.url` variables, `coreos-cloudinit` will try to apply these Cloud Configs on VM and substitute `$private_ipv4` and `$public_ipv4` variables if you've configured network interfaces' roles using `interface.<n>.role` guest variable.

### Defining Cloud-Config in GuestInfo

There are two supported encoding types, which can be configured with the `guestinfo.coreos.config.data.encoding` variable:

|  Encoding   |                      Command                      |
|:------------|:--------------------------------------------------|
| base64      | `base64 -w0 /path/to/user_data && echo`           |
| gzip+base64 | `gzip -c /path/to/user_data | base64 -w0 && echo` |

To avoid having to `base64`, you can retrieve your Cloud-Config from a URL with the `guestinfo.coreos.config.url` variable.

#### Example

```
guestinfo.coreos.config.data = "H4sICP9nAVYAA3VzZXJfZGF0YQBTTs7JL03RTc7PS8tM5youzohPLC3JyC/KrEpNic9OrSy24lLQVQCK6xYVJyrkVhaUJgFFuQCe+rhmNwAAAA=="
guestinfo.coreos.config.data.encoding = "gzip+base64"
```

This example will be decoded into:

```yaml
#cloud-config
ssh_authorized_keys:
 - ssh-rsa mypubkey
```

Please refer to [vmware backdoor][vmware backdoor] for full options list.

## Logging in

Networking can take a bit of time to come up under VMware and you will need to
know the IP in order to SSH in. Press enter a few times at the login prompt and
you should see an IP address pop up:

![VMware IP Address](img/vmware-ip.png)

In this case the IP is `10.0.1.81`.

Now you can login using your SSH key or password set in your cloud-config.

```sh
ssh core@10.0.1.81
```

Alternatively, if you append `coreos.autologin` to the kernel parameters on
boot, the console won't prompt for a password. This is handy for debugging.

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the
[CoreOS Quickstart][quickstart] guide or dig into [more specific topics][docs].

[quickstart]: quickstart.md
[docs]: https://github.com/coreos/docs
[config-drive]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/config-drive.md
[cloud-config guide]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit
[vmware backdoor]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/vmware-guestinfo.md
[vcloud director]: http://blogs.vmware.com/vsphere/2012/06/leveraging-vapp-vm-custom-properties-in-vcloud-director.html
[ovf-selfconfig]: http://blogs.vmware.com/vapp/2009/07/selfconfiguration-and-the-ovf-environment.html
[vmware-use-guestinfo]: http://blog-lrivallain.rhcloud.com/2014/08/15/vmware-use-guestinfo-variables-to-customize-guest-os/
