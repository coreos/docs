---
layout: docs
slug: google-compute-engine
title: Documentation - Google Compute Engine
---

# Running CoreOS {{ site.version-string }} on Google Compute Engine

CoreOS on Google Compute Engine (GCE) is currently in heavy development and actively being tested. The current disk image is listed below and relies on GCE's recently announced [Advanced OS Support][gce-advanced-os]. Each time a new update is released, your machines will [automatically upgrade themselves]({{ site.url }}/using-coreos/updates).

You will need to [install gcutil][gcutil-documentation] before proceeding.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcutil-documentation]: https://developers.google.com/compute/docs/gcutil/

## Image creation

At the moment CoreOS images are not publicly listed in GCE and must be added to your own account from a raw disk image published in Google Cloud Storage:

    gcutil --project=<project-id> addimage --description="CoreOS {{ site.version-string }}" coreos-production-v{{ site.gce-version-id }} gs://storage.core-os.net/coreos/amd64-generic/{{ site.version-string }}/coreos_production_gce.tar.gz

## Instance creation

New instances can now be created using the image created above:

    gcutil --project=<project-id> addinstance <instance-name> --image=coreos-production-v{{ site.gce-version-id }} --persistent_boot_disk

## SSH

You can log in your CoreOS instance using:

    gcutil --project=<project-id> ssh --ssh_user=core <instance-name>

## Etcd

Automatic cluster setup is not supported yet, but is under active development.

## Using CoreOS

Now that you have a few machines booted it is time to play around. Check out the [Using CoreOS][using-coreos] guide.
