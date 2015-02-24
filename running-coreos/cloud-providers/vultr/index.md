---
layout: docs
title: Vultr VPS
category: running_coreos
sub_category: cloud_provider
weight: 10
---

# Running CoreOS  on a Vultr VPS

These instructions will walk you through running a single CoreOS node. This guide assumes:

* You have an account at [Vultr.com](https://www.vultr.com).
* You have a public + private key combination generated. Here's a helpful guide if you need to generate these keys: [How to set up SSH keys](https://help.github.com/articles/generating-ssh-keys).

The simplest option to boot up CoreOS is to select the "CoreOS Stable" operating system from Vultr's default offerings. However, most deployments require a custom `cloud-config`, which can only be achieved in Vultr with an iPXE script. The remainder of this article describes this process.

## Cloud-Config

First, you'll need to make two files available at public URL's -- your `cloud-config` file and a shell script which you need to create:

```sh
URL="http://example.com/cloud-config.yaml"

cat << EOF > ./cloud-config-bootstrap.sh\n
#!/bin/bash
curl -o cloud-config.yaml $URL
sudo coreos-install -d /dev/vda -c cloud-config.yaml
sudo reboot
EOF
```

Please be sure to check out [Using Cloud-Config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config).

You must add to your ssh public key to your `cloud-config`'s [ssh authorized keys]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/#ssh_authorized_keys) so you'll be able to log in.

## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.url}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Read the [release notes]({{site.url}}/releases) for specific features and bug fixes.

<div id="vultr-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.data.alpha-channel.rackspace-version}}.</p>
      </div>
      <p>A sample script will look like this:</p>

<pre>#!ipxe

# Location of your shell script.
set cloud-config-url http://example.com/cloud-config-bootstrap.sh

set base-url http://alpha.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=${cloud-config-url}
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.data.beta-channel.rackspace-version}}.</p>
      </div>
      <p>A sample script will look like this:</p>

<pre>#!ipxe

# Location of your shell script.
set cloud-config-url http://example.com/cloud-config-bootstrap.sh

set base-url http://beta.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=${cloud-config-url}
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.data.stable-channel.rackspace-version}}.</p>
      </div>
      <p>A sample script will look like this:</p>

<pre>#!ipxe

# Location of your shell script.
set cloud-config-url http://example.com/cloud-config-bootstrap.sh

set base-url http://stable.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=${cloud-config-url}
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
  </div>
</div>

Go to My Servers > Startup Scripts > Add Startup Script, select type "PXE", and input your script. Be sure to replace the cloud-config-url with that of the shell script you created above.

Additional reading can be found at [Booting CoreOS with iPXE](http://coreos.com/docs/running-coreos/bare-metal/booting-with-ipxe/) and [Embedded scripts for iPXE](http://ipxe.org/embed).

## Create the VPS

Create a new VPS (any server type and location of your choice), and then:

1. For the "Operating System" select "Custom"
2. Select "iPXE Custom Script" and the script you created above.
3. Click "Place Order"

Once you receive the "Subscription Activated" email the VPS will be ready to use.

## Accessing the VPS

You can now log in to CoreOS using the associated private key on your local computer. You may need to specify its location using ```-i LOCATION```. If you need additional details on how to specify the location of your private key file see [here](http://www.cyberciti.biz/faq/force-ssh-client-to-use-given-private-key-identity-file/).

SSH to the IP of your VPS, and specify the "core" user: ```ssh core@IP```

```sh
$ ssh core@IP
The authenticity of host 'IP (2a02:1348:17c:423d:24:19ff:fef1:8f6)' can't be established.
RSA key fingerprint is 99:a5:13:60:07:5d:ac:eb:4b:f2:cb:c9:b2:ab:d7:21.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[IP]' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/user/.ssh/id_rsa':
CoreOS stable (557.2.0)
core@localhost ~ $
```

## Using CoreOS

Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
