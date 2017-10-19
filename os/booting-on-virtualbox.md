# Running CoreOS Container Linux on VirtualBox

These instructions will walk you through running Container Linux on Oracle VM VirtualBox.

## Building the virtual disk

There is a script that simplify the VDI building. It downloads a bare-metal image, verifies it with GPG, and converts the image to VirtualBox format.

The script is located on [GitHub](https://github.com/coreos/scripts/blob/master/contrib/create-coreos-vdi). The running host must support VirtualBox tools.

As first step, download the script using either `wget` or `curl`.

```sh
wget https://raw.githubusercontent.com/coreos/scripts/master/contrib/create-coreos-vdi
# OR
curl https://raw.githubusercontent.com/coreos/scripts/master/contrib/create-coreos-vdi > create-coreos-vdi
```

Then make it executable.

```sh
chmod +x create-coreos-vdi
```

To run the script you can specify a destination location and the Container Linux version.

```sh
./create-coreos-vdi -d /data/VirtualBox/Templates
```

## Choose a channel

Choose a channel to base your disk image on. Specific versions of Container Linux can also be referenced by version number.

<div id="virtualbox-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <p>Create a disk image from this channel by running:</p>
<pre>
./create-coreos-vdi -V alpha
</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <p>Create a disk image from this channel by running:</p>
<pre>
./create-coreos-vdi -V beta
</pre>
    </div>
  <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <p>Create a disk image from this channel by running:</p>
<pre>
./create-coreos-vdi -V stable
</pre>
    </div>
  </div>
</div>

After the script is finished successfully, will be available at the specified destination location the Container Linux image or at current location. The file name will be something like:

```
coreos_production_stable.vdi
```

## Creating a config-drive

Cloud-config can be specified by attaching a [config-drive](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/config-drive.md) with the label `config-2`. This is commonly done through whatever interface allows for attaching CD-ROMs or new drives.

Note that the config-drive standard was originally an OpenStack feature, which is why you'll see strings containing `openstack`. This filepath needs to be retained, although Container Linux supports config-drive on all platforms.

For more information on customization that can be done with cloud-config, head on over to the [cloud-config guide](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md).

You need a config-drive to configure at least one SSH key to access the virtual machine. If you are in hurry you can create a basic config-drive with following steps.

```sh
wget https://raw.github.com/coreos/scripts/master/contrib/create-basic-configdrive
chmod +x create-basic-configdrive
./create-basic-configdrive -H my_vm01 -S ~/.ssh/id_rsa.pub
```

Will be created an ISO file named `my_vm01.iso` that will configure a virtual machine to accept your SSH key and set its name to my_vm01.

## Deploying a new virtual machine on VirtualBox

I recommend using the built image as base image. Therefore you should clone the image for each new virtual machine and set it to desired size.

```sh
VBoxManage clonehd coreos_production_stable.vdi my_vm01.vdi
# Resize virtual disk to 10 GB
VBoxManage modifyhd my_vm01.vdi --resize 10240
```

At boot time the Container Linux will detect that the volume size changed and will resize the filesystem according.

Open VirtualBox Manager and go to menu Machine > New. Type the desired machine name and choose 'Linux' type and 'Linux 2.6 / 3.x (64 bit)' version.

Next, choose the desired memory size. I recommend 1 GB for smooth experience.

Next, choose 'Use an existing virtual hard drive file' and find the new cloned image.

Click on 'Create' button to create the virtual machine.

Next, go to settings from the created virtual machine. Then click on Storage tab and load the created config-drive into CD/DVD drive.

Click on 'OK' button and the virtual machine will be ready to be started.

## Logging in

Networking can take a bit of time to come up under VirtualBox and you will need to know the IP in order to connect to it. Press enter a few times at the login prompt to see an IP address pop up. If you see VirtualBox NAT IP 10.0.2.15, go to virtual machine settings and click the Network tab, then Port Forwarding. Add the rule "Host Port: 2222; Guest Port 22", then connect using the command ssh `core@localhost -p2222`.

Now you can login using your private SSH key.

```sh
ssh core@192.168.56.101
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).
