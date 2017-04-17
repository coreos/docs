# Installing CoreOS Container Linux to disk

## Install script

There is a simple installer that will destroy everything on the given target disk and install Container Linux. Essentially it downloads an image, verifies it with gpg, and then copies it bit for bit to disk. An installation requires at least 8 GB of usable space on the device.

The script is self-contained and located [on GitHub here][coreos-install] and can be run from any Linux distribution. You cannot normally install Container Linux to the same device that is currently booted. However, the [Container Linux ISO][coreos-iso] or any Linux liveCD will allow Container Linux to install to a non-active device.

If you boot Container Linux via PXE, the install script is already installed. By default the install script will attempt to install the same version and channel that was PXE-booted:

```sh
coreos-install -d /dev/sda
```

If you are using the ISO with VMware, first sudo to root:

```sh
sudo su - root
```

Then install as you would with the PXE booted system, but be sure to include user information, especially an SSH key, in a [cloud-config][cloud-config-section] file, or else you will not be able to log into your Container Linux instance.


```sh
coreos-install -d /dev/sda -c cloud-config.yaml
```

## Choose a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

<div id="install">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <p>If you want to ensure you are installing the latest alpha version, use the <code>-C</code> option:</p>
      <pre>coreos-install -d /dev/sda -C alpha</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <p>If you want to ensure you are installing the latest beta version, use the <code>-C</code> option:</p>
      <pre>coreos-install -d /dev/sda -C beta</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <p>If you want to ensure you are installing the latest stable version, use the <code>-C</code> option:</p>
      <pre>coreos-install -d /dev/sda -C stable</pre>
    </div>
  </div>
</div>

For reference here are the rest of the `coreos-install` options:

```
-d DEVICE   Install Container Linux to the given device.
-V VERSION  Version to install (e.g. current)
-C CHANNEL  Release channel to use (e.g. beta)
-o OEM      OEM type to install (e.g. openstack)
-c CLOUD    Insert a cloud-init config to be executed on boot.
-i IGNITION Insert an Ignition config to be executed on boot.
-t TMPDIR   Temporary location with enough space to download images.
-v          Super verbose, for debugging.
-b BASEURL  URL to the image mirror
```

## Cloud-config

By default there isn't a password or any other way to log into a fresh Container Linux system. The easiest way to configure accounts, add systemd units, and more is via cloud config. Jump over to the [docs to learn about the supported features][cloud-config].

The installation script will process your `cloud-config.yaml` file specified with the `-c` flag and place it onto disk. It will be installed to `/var/lib/coreos-install/user_data` and evaluated on every boot. Cloud-config is not the only supported format for this file &mdash; running a script is also available.

A cloud-config that specifies an SSH key for the `core` user but doesn't use any other parameters looks like:

```cloud-config
#cloud-config

# include one or more SSH public keys
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
```

Note: The `$private_ipv4` and `$public_ipv4` substitution variables referenced in other documents are not supported on libvirt. The convenience of these automatic variables can be emulated by [using nginx to host your cloud-config][nginx].

To start the installation script with a reference to our cloud-config file, run:

```
coreos-install -d /dev/sda -C stable -c ~/cloud-config.yaml
```

### Advanced cloud-config example

This example will configure Container Linux components: etcd2, fleetd and flannel. You have to substitute `<PEER_ADDRESS>` to your host's IP or DNS address.

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
    advertise-client-urls: http://<PEER_ADDRESS>:2379,http://<PEER_ADDRESS>:4001
    initial-advertise-peer-urls: http://<PEER_ADDRESS>:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://<PEER_ADDRESS>:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
    - name: flanneld.service
      command: start
      drop-ins:
      - name: 50-network-config.conf
        content: |
          [Service]
          ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{"Network":"10.1.0.0/16", "Backend": {"Type": "vxlan"}}'
```

## Manual tweaks

If cloud config doesn't handle something you need to do or you just want to take a look at the root filesystem before booting your new install just mount the ninth partition. For example, with an ext4 root filesystem:

```sh
mount /dev/sda9 /mnt/
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart][quickstart] guide or dig into [more specific topics][docs-root].

[nginx]: nginx-host-cloud-config.md
[quickstart]: quickstart.md
[docs-root]: https://github.com/coreos/docs
[coreos-iso]: booting-with-iso.md
[cloud-config-section]: #cloud-config
[cloud-config]: https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md
[coreos-install]: https://raw.github.com/coreos/init/master/bin/coreos-install
