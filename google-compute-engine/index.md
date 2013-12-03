---
layout: docs
slug: google-compute-engine
title: Documentation - Google Compute Engine
---

# Running CoreOS on Google Compute Engine

CoreOS on Google Compute Engine (GCE) is currently in heavy development and actively being tested. The current disk image is listed below and relies on GCE's recently announced [Advanced OS Support][gce-advanced-os]. Each time a new update is released, your machines will [automatically upgrade themselves]({{ site.url }}/using-coreos/updates).

You will need to [install gcutil][gcutil-documentation] before proceeding.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcutil-documentation]: https://developers.google.com/compute/docs/gcutil/

## Image creation

At the moment CoreOS images are not publicly listed in GCE and must be added to your own account from a raw disk image published in Google Cloud Storage:

<!-- TODO: Update URL to public gs://storage.core-os.net location, make version automatic -->
<!-- FIXME: After launch does the empty preferred_kernel option still need to be set? -->

    gcutil --project=<project-id> addimage --description="CoreOS 153.0.0" coreos-production-v153 gs://storage.core-os.net/coreos/amd64-generic/153.0.0/coreos_production_gce.tar.gz

## Instance creation

New instances can now be created using the image created above:

    gcutil --project=<project-id> addinstance <instance-name> --image=coreos-production-v153 --persistent_boot_disk

## SSH

For now CoreOS only supports logging in as the `core` user which breaks the `gcutil ssh` command. Instead you must log in directly via ssh:

    gcutil getinstance <instance-name>
    ssh -i ~/.ssh/google_compute_engine -l core <external-ip>

## Etcd

Automatic cluster setup is not supported yet, but is under active development.

## Using CoreOS

Now that you have a few machines booted it is time to play around. Check out the [Using CoreOS][using-coreos] guide.
