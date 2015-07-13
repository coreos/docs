# Booting CoreOS via iPXE

CoreOS is currently in heavy development and actively being tested. These instructions will walk you through booting CoreOS via iPXE on real or virtual hardware. By default, this will run CoreOS completely out of RAM. CoreOS can also be [installed to disk]({{site.baseurl}}/docs/running-coreos/bare-metal/installing-to-disk).

## Configuring iPXE

iPXE can be used on any platform that can boot an ISO image.
This includes many cloud providers and physical hardware.

To illustrate iPXE in action we will use qemu-kvm in this guide.

### Setting up iPXE boot script

When configuring the CoreOS iPXE boot script there are a few kernel options that may be useful but all are optional.

- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted in advance but may be completely blank, it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **coreos.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 coreos.autologin=tty1 coreos.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).
- **cloud-config-url**: CoreOS will attempt to download a cloud-config document and use it to provision your booted system. See the [coreos-cloudinit-project][cloudinit] for more information.

[cloudinit]: https://github.com/coreos/coreos-cloudinit

### Choose a Channel

CoreOS is released into stable, alpha and beta channels. Releases to each channel serve as a release-candidate for the next channel. For example, a bug-free alpha release is promoted bit-for-bit to the beta channel.

### Setting up the Boot Script

<div id="ipxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://alpha.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=http://example.com/pxe-cloud-config.yml
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://beta.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=http://example.com/pxe-cloud-config.yml
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://stable.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz cloud-config-url=http://example.com/pxe-cloud-config.yml
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot</pre>
    </div>
  </div>
</div>

An easy place to host this boot script is on [http://pastie.org](http://pastie.org). Be sure to reference the "raw" version of script, which is accessed by clicking on the clipboard in the top right.

Note: the iPXE environment won't open https links, which means you can't use [https://gist.github.com](https://gist.github.com) to store your script. Bummer, right?


### Booting iPXE

First, download and boot the iPXE image.
We will use `qemu-kvm` in this guide but use whatever process you normally use for booting an ISO on your platform.

```sh
wget http://boot.ipxe.org/ipxe.iso
qemu-kvm -m 1024 ipxe.iso --curses
```

Next press Ctrl+B to get to the iPXE prompt and type in the following commands:

```sh
iPXE> dhcp
iPXE> chain http://${YOUR_BOOT_URL}
```

Immediately iPXE should download your boot script URL and start grabbing the images from the CoreOS storage site:

```sh
${YOUR_BOOT_URL}... ok
http://alpha.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz... 98%
```

After a few moments of downloading CoreOS should boot normally.

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

CoreOS can be completely installed on disk or run from RAM but store user data on disk. Read more in our [Installing CoreOS guide]({{site.baseurl}}/docs/running-coreos/bare-metal/booting-with-pxe/#installation).

## Adding a Custom OEM

Similar to the [OEM partition][oem] in CoreOS disk images, iPXE images can be customized with a [cloud config][cloud-config] bundled in the initramfs. You can view the [instructions on the PXE docs]({{site.baseurl}}/docs/running-coreos/bare-metal/booting-with-pxe/#adding-a-custom-oem).

[oem]: {{site.baseurl}}/docs/sdk-distributors/distributors/notes-for-distributors/#image-customization
[cloud-config]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/

## Hosting `cloud-config`

One of the ways to host your `cloud-config` files is to use [nginx][nginx]. You can also use [http_sub_module][http_sub_module] which will allow you to use `$private_ipv4` and `$public_ipv4` substitution variables referenced in other documents. By default this module is enabled in official nginx packages and in most Linux distributions.

Here is an example nginx configuration which will substitute `$public_ipv4` and `$private_ipv4` (depends on your nginx server location and NAT configuration) variables:

```
location ~ ^/user_data {
  root /path/to/cloud/config/files;
  sub_filter $public_ipv4 '$remote_addr';
# sub_filter $private_ipv4 '$http_x_forwarded_for';
# sub_filter $private_ipv4 '$http_x_real_ip';
  sub_filter_once off;
  sub_filter_types '*';
}
```

This example configuration is valid for all `/user_data*` URIs (i.e. `/user_data_host1`, `/user_data_host2`, etc.). `$private_ipv4` substitution will work only if your local hosts use a transparent http proxy which adds `HTTP_X_FORWARDED_FOR` or `HTTP_X_REAL_IP` HTTP request headers and your nginx server is hosted remotely.

[nginx]: http://nginx.org/en/
[http_sub_module]: http://nginx.org/en/docs/http/ngx_http_sub_module.html

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
