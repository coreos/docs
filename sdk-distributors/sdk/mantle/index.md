---
layout: docs
title: "Mantle: Gluing CoreOS together"
category: sdk_distributors
sub_category: sdk
weight: 10 
---

# Mantle: Gluing CoreOS together

Mantle is a collection of utilities for the CoreOS SDK.

## plume index

Generate and upload index.html objects to turn a Google Cloud Storage
bucket into a publicly browsable file tree. Useful if you want something
like Apache's directory index for your software download repository.

## plume gce cluster launching

Related commands to launch instances on Google Compute Engine(gce) with
the latest SDK image. SSH keys should be added to the gce project
metadata before launching a cluster. All commands have flags that can
overwrite the default project, bucket, and other settings.  `plume help
<command>` can be used to discover all the switches.

### plume upload

Upload latest SDK image to Google Storage and then create a gce image.
Assumes an image packaged with the flag `--format=gce` is present.
Common usage for CoreOS devs using the default bucket and project is:

`plume upload`

### plume list-images

Print out gce images from a project. Common usage:

`plume list-images`

### plume create-instances

Launch instances on gce. SSH keys should be added to the metadata
section of the gce developers console. Common usage:

`plume create-instances -n=3 -image=<gce image name> -config=<cloud config file>`

### plume list-instances

List running gce instances. Common usage:

`plume list-instances`

### plume destroy-instances

Destroy instances on gce based by prefix or name. Images created with
`create-instances` use a common basename as a prefix that can also be
used to tear down the cluster. Common usage:

`plume destroy-instances -prefix=$USER`

## kola

Test framework for CoreOS integration testing. Launch groups of related
tests using the latest SDK image on specified platforms (qemu, gce ...)
