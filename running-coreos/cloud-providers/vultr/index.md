---
layout: docs
title: Vultr VPS
category: running_coreos
sub_category: cloud_provider
weight: 10
---

# Running CoreOS  on a Vultr VPS

CoreOS is currently in heavy development and actively being tested.  These instructions will walk you through running a single CoreOS node. This guide assumes:

* You have an account at [Vultr.com](http://vultr.com). 
* The location of your iPXE script (referenced later in the guide) is located at ```http://example.com/script.txt```
* You have a public + private key combination generated. Here's a helpful guide if you need to generate these keys: [How to set up SSH keys](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2). 

## Create the script

The simplest option to boot up CoreOS is to load a script that contains the series of commands you'd otherwise need to manually type at the command line. This script needs to be publicly accessible (host this file on your own server). Save this script as a text file (.txt extension).

A sample script will look like this :

```
#!ipxe

set base-url http://alpha.release.core-os.net/amd64-usr/current
kernel ${base-url}/coreos_production_pxe.vmlinuz sshkey="YOUR_PUBLIC_KEY_HERE"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot
```
Make sure to replace `YOUR_PUBLIC_KEY_HERE` with your actual public key, it will begin with "ssh-rsa...".

Additional reading can be found at [Booting CoreOS with iPXE](http://coreos.com/docs/running-coreos/bare-metal/booting-with-ipxe/) and [Embedded scripts for iPXE](http://ipxe.org/embed).

## Create the VPS

Create a new VPS (any server type and location of your choice), and then:

1. For the "Operating System" select "Custom"
2. Select iPXE boot
3. Set the chain URL to the URL of your script (http://example.com/script.txt)
4. Click "Place Order"

![Any location, any size, custom OS, iPXE boot, set chain URL, place order](http://s18.postimg.org/5ra9lioeh/vultr.png)

Once you receive the welcome email the VPS will be ready to use (typically less than 2-3 minutes).

## Accessing the VPS

You can now log in to CoreOS using the associated private key on your local computer. You may need to specify its location using ```-i LOCATION```. If you need additional details on how to specify the location of your private key file see [here](http://www.cyberciti.biz/faq/force-ssh-client-to-use-given-private-key-identity-file/).

SSH to the IP of your VPS, and specify the "core" user: ```ssh core@IP```


```
$ ssh core@IP
The authenticity of host 'IP (2a02:1348:17c:423d:24:19ff:fef1:8f6)' can't be established.
RSA key fingerprint is 99:a5:13:60:07:5d:ac:eb:4b:f2:cb:c9:b2:ab:d7:21.
Are you sure you want to continue connecting (yes/no)? yes

Last login: Thu Oct 17 11:42:04 UTC 2013 from 127.0.0.1 on pts/0
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/
core@srv-n8uak ~ $
```

## Using CoreOS

Now that you have a cluster bootstrapped it is time to play around.

CoreOS is currently running from RAM, based on the loaded image. You may want to [install it on the disk]({{site.url}}/docs/running-coreos/bare-metal/installing-to-disk). Note that when following these instructions on Vultr, the device name should be `/dev/vda` rather than `/dev/sda`.

Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
