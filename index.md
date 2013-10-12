---
layout: docs
slug: index
title: Documentation
---

# Running CoreOS

You need to have at least one CoreOS machine running before you get to play with the fun stuff. You can run it on all of the major platforms. Click each logo for a specific guide. If you're not sure, Vagrant is easy and quick.

We're working on more platforms over time &mdash; if you'd like something specific let us know on IRC in [Freenode #coreos](irc://irc.freenode.org:6667/#coreos) or on the [mailing list](https://groups.google.com/forum/#!forum/coreos-dev).

<div class="row" id="platforms">
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/vagrant/" data-category="Platform Logo" data-event="Vagrant Logo"><img src="../assets/images/media/vagrant.png" /></a>
  </div>
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/ec2/" data-category="Platform Logo" data-event="EC2 Logo"><img src="../assets/images/media/aws.png" /></a>
  </div>
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/qemu/" data-category="Platform Logo" data-event="KVM Logo"><img src="../assets/images/media/kvm.png" /></a>
  </div>
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/vmware/" data-category="Platform Logo" data-event="VMware Logo"><img src="../assets/images/media/vmware.png" /></a>
  </div>
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/openstack/" data-category="Platform Logo" data-event="OpenStack Logo"><img src="../assets/images/media/openstack.png" /></a>
  </div>
  <div class="col-lg-4 col-md-4 col-sm-4 col-xs-6 platform">
    <a href="{{ site.url }}/docs/pxe/" data-category="Platform Logo" data-event="PXE Logo"><img src="../assets/images/media/pxe.png" /></a>
  </div>
</div>

## Getting Started Guides

### Quick Start

If you are in a hurry, try out our quick start guide. It will give you a brief overview of the CoreOS features and technologies without going too in depth.

<a href="{{ site.url }}/docs/guides/" class="btn btn-primary" data-category="Docs Homepage" data-event="Docs: Using CoreOS">Quick Start Guide</a>

### docker

After you've got a machine up and running, try your hand at launching a few docker containers. If you've got an application that you're familiar with, it's easy to start with that. Try installing it into a docker container and running a few copies of it.

<a href="{{ site.url }}/docs/guides/docker/" class="btn btn-primary" data-category="Docs Homepage" data-event="Docs: Getting Started docker">Getting Started with docker</a>
<a href="{{ site.url }}/using-coreos/docker/" class="btn btn-default" data-category="Docs Homepage" data-event="Using CoreOS: docker">Learn more about docker + CoreOS</a>

### etcd

If you feel like you've started to understand docker, move on to playing with etcd, our shared configuration service. You can access etcd with from within your containers to share all kinds of data.

<a href="{{ site.url }}/docs/guides/etcd/" class="btn btn-primary" data-category="Docs Homepage" data-event="Docs: Getting Started etcd">Getting Started with etcd</a>
<a href="{{ site.url }}/using-coreos/etcd/" class="btn btn-default" data-category="Docs Homepage" data-event="Using CoreOS: etcd">Learn more about etcd + CoreOS</a>

## Developer SDK

Most users don't have to build CoreOS from source, but our developer SDK can guide you through this process if required. If you are interested in adding functionality to your hosts but are frustrated by the read-only filesystem, this is your answer. Contact us on IRC in [Freenode #coreos](irc://irc.freenode.org:6667/#coreos) with your requirements before you commit a large amount of time to this. We are constantly re-evaluating the tools we have installed by default to provide the right balance of minimalism and useful functionality.

<a href="{{ site.url }}/docs/sdk/" class="btn btn-primary" data-category="Docs Homepage" data-event="Docs: SDK">Developer SDK</a>