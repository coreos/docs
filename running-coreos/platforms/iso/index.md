---
layout: docs
title: ISO
category: running_coreos
sub_category: platforms
supported: true
weight: 10
---

# Booting CoreOS from an ISO

The latest CoreOS ISOs can be downloaded from the image storage site:

<div id="iso-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      </div>
      <a href="http://alpha.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso" class="btn btn-primary">Download Alpha ISO</a>
      <a href="http://alpha.release.core-os.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      </div>
      <a href="http://beta.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso" class="btn btn-primary">Download Beta ISO</a>
      <a href="http://beta.release.core-os.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
      </div>
      <a href="http://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso" class="btn btn-primary">Download Stable ISO</a>
      <a href="http://stable.release.core-os.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
  </div>
</div>

## Known Limitations

1. Docker will not work out of the box
2. The best strategy for providing [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config) is via [config-drive](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/config-drive.md).

## Install to Disk

The most common use-case for this ISO is to install CoreOS to disk. You can [find those instructions here]({{site.url}}/docs/running-coreos/bare-metal/installing-to-disk).

## Bypass Authentication

If you need to bypass authentication in order to install, the kernel option `coreos.autologin` allows you to drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution.

For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 coreos.autologin=tty1 coreos.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).