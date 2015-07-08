---
layout: docs
title: Verify CoreOS Images with GPG
category: cluster_management
sub_category: setting_up
fork_url: https://github.com/coreos/docs/blob/master/cluster-management/setup/verify-images/index.md
weight: 7
---

# Verify CoreOS Images with GPG

CoreOS publishes new images for each release across a variety of platforms and hosting providers. Each channel has it's own set of images ([stable], [beta], [alpha]) that are posted to our storage site. Along with each image, a signature is generated from the [CoreOS Image Signing Key][signing-key] and posted.

[signing-key]: {{site.baseurl}}/security/image-signing-key
[stable]: http://stable.release.core-os.net/amd64-usr/current/
[beta]: http://beta.release.core-os.net/amd64-usr/current/
[alpha]: http://alpha.release.core-os.net/amd64-usr/current/

After downloading your image, you should verify it with `gpg` tool. First, download the image signing key:

```sh
curl -O https://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.asc
```

Next, import the public key and verify that the ID matches the website: {{site.baseurl}}/security/image-signing-key

```sh
gpg --import --keyid-format LONG CoreOS_Image_Signing_Key.asc
gpg: key 50E0885593D2DCB4: public key "CoreOS Buildbot (Offical Builds) <buildbot@coreos.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1  (RSA: 1)
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
```

Now we're ready to download an image and it's signature, ending in .sig. We're using the QEMU image in this example:

```sh
curl -O http://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
curl -O http://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2.sig
```

Verify image with `gpg` tool:

```sh
gpg --verify coreos_production_qemu_image.img.bz2.sig
gpg: Signature made Tue Jun 23 09:39:04 2015 CEST using RSA key ID E5676EFC
gpg: Good signature from "CoreOS Buildbot (Offical Builds) <buildbot@coreos.com>"
```

The `Good signature` message indicates that the file signature is valid. Go launch some machines now that we've successfully verified that this CoreOS image isn't corrupt, that it was authored by CoreOS, and wasn't tampered with in transit.
