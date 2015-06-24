---
layout: docs
slug: vmware
title: VMware
category: running_coreos
sub_category: platforms
fork_url: https://github.com/coreos/docs/blob/master/running-coreos/platforms/vmware/index.md
weight: 5
---

# Running CoreOS on VMware

CoreOS is currently in heavy development and actively being tested.
These instructions will walk you through running CoreOS on VMware Fusion or ESXi.
If you are familiar with another VMware product you can use these instructions as a starting point.

## Running the VM

These steps will download the VMware image and extract the zip file. After that
you will need to launch the `coreos_developer_vmware_insecure.vmx` file to create a VM.

### Choosing a Channel

CoreOS is released into alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

The channel is selected based on the URL below. Simply replace `alpha` with `beta`. Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes in each channel.

This is a rough sketch that should work on OS X and Linux:

```sh
curl -LO http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vmware_insecure.zip
unzip coreos_production_vmware_insecure.zip -d coreos_production_vmware_insecure
cd coreos_production_vmware_insecure
open coreos_production_vmware_insecure.vmx
```

### To deploy on an ESXi/vSphere host, convert the VM to OVF
* follow the steps above to download and extract the coreos_production_vmware_insecure.zip
* download and run the [OVF Tool installer](https://developercenter.vmware.com/tool/ovf/) Requires VMware account login but the download is free. Available for Linux, OS X & Windows for both 32 & 64 bit architectures.
* convert VM to OVF from the extract dir

```sh
cd coreos_developer_vmware_insecure
mkdir coreos
ovftool coreos_production_vmware_insecure.vmx coreos/coreos.insecure.ovf
```

NOTE: This uses defaults and creates a single core, 1024MB type 4 VM when deployed. To change before deployment, see ovftool --help or manually edit the coreos.insecure.ovf If you do manually edit the OVF file, you will also need to recalculate the SHA1 and update the coreos.insecure.mf accordingly

The above step creates the following files in ../coreos/:

```sh
  coreos.insecure-disk1.vmdk
  coreos.insecure.ovf
  coreos.insecure.mf
```

* use the vSphere Client to deploy the VM as follows:
    * menu "File"..."Deploy OVF Template..."
    * in the wizard, specify the location of the /coresos/ coreos.insecure.ovf created earlier
    * name your VM
    * choose "thin provision" for the disk format
    * choose your network settings
    * confirm the settings then click "Finish"

    NOTE: unselect "Power on after deployment" so you have a chance to edit VM settings before powering it up for the first time.

The last step uploads the files to your ESXi datastore and registers your VM. You can now tweak the VM settings, like memory and virtual cores, then power it on. These instructions were tested to deploy to an ESXi 5.5 host.

## Cloud-Config

Cloud-config can be specified by attaching a [config-drive]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-config-drive/) with the label `config-2`. This is commonly done through whatever interface allows for attaching CD-ROMs or new drives.

Note that the config-drive standard was originally an OpenStack feature, which is why you'll see strings containing `openstack`. This filepath needs to be retained, although CoreOS supports config-drive on all platforms.

For more information on customization that can be done with cloud-config, head on over to the [cloud-config guide]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/).

Note: The `$private_ipv4` and `$public_ipv4` substitution variables referenced in other documents are *not* supported on VMware.

## Logging in

Networking can take a bit of time to come up under VMware and you will need to
know the IP in order to SSH in. Press enter a few times at the login prompt and
you should see an IP address pop up:

![VMware IP Address](vmware-ip.png)

In this case the IP is `10.0.1.81`.

Now you can login using the shared and insecure private SSH key.

```sh
cd coreos_developer_vmware_insecure
ssh -i insecure_ssh_key core@10.0.1.81
```

## Replacing the key

We highly recommend that you disable the original insecure OEM SSH key and
replace it with your own. This is a simple two step process: first, add your
public key, and then remove the original OEM one.

```sh
cat ~/.ssh/id_rsa.pub | ssh core@10.0.1.81 -i insecure_ssh_key update-ssh-keys -a user
ssh core@10.0.1.81 update-ssh-keys -D oem
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
