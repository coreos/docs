# Running CoreOS on VMware

These instructions will walk you through running CoreOS on VMware Fusion or
ESXi. If you are familiar with another VMware product you can use these
instructions as a starting point.

## Running the VM

### Choosing a Channel

CoreOS is released into alpha, beta, and stable channels. Releases to each
channel serve as a release-candidate for the next channel. For example, a
bug-free alpha release is promoted bit-for-bit to the beta channel.

The channel is selected based on the URLs below. Simply replace `stable` with
`alpha` or `beta`. Read the [release notes][release notes] for specific
features and bug fixes in each channel.

```sh
curl -LO http://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova
```

[release notes]: {{site.baseurl}}/releases

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

## Cloud-Config

Cloud-config can be specified by attaching a [config-drive][config-drive] with
the filesystem label `config-2`. This is commonly done through whatever
interface allows for attaching CD-ROMs or new drives.

Note that the config-drive standard was originally an OpenStack feature, which
is why you'll see strings containing `openstack`. This filepath needs to be
retained, although CoreOS supports config-drive on all platforms.

For more information on customization that can be done with cloud-config, head
on over to the [cloud-config guide][cloud-config guide].

Note: The `$private_ipv4` and `$public_ipv4` substitution variables referenced
in other documents are *not* supported on VMware.

[config-drive]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-config-drive/
[cloud-config guide]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/

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

[quickstart]: {{site.baseurl}}/docs/quickstart
[docs]: {{site.baseurl}}/docs
