---
layout: docs
title: Vultr VPS Provider
category: running_coreos
sub_category: cloud_provider
weight: 10
---

# Running CoreOS  on a Vultr VPS

CoreOS is currently in heavy development and actively being tested.  These instructions will walk you through running a single CoreOS node. This guide assumes:

* You have an account at [Vultr.com](http://vultr.com). 
* The location of your iPXE script (referenced later in the guide) is located at ```http://example.com/script.txt```
* You have a public + private key combination generated. Here's a helpful guide if you need to generate these keys: [How to set up SSH keys](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2). 

## Create the VPS

Create a new VPS (any server type and location of your choice), and then for the "Operating System" select  "Custom". Click "Place Order". 

![Any location, any size, custom OS, place order](https://s3.amazonaws.com/f.cl.ly/items/0H0l1w3u0f1F2n203d0I/Screen%20Shot%202014-04-17%20at%202.52.27%20PM.png)

Once you receive the welcome email the VPS will be ready to use (typically less than 2-3 minutes).

## Create the script

The simplest option to boot up CoreOS is to load a script that contains the series of commands you'd otherwise need to manually type at the command line. This script needs to be publicly accessible (host this file on your own server). Save this script as a text file (.txt extension).

A sample script will look like this :

```
#!ipxe
set coreos-version dev-channel
set base-url http://storage.core-os.net/coreos/amd64-generic/${coreos-version}
kernel ${base-url}/coreos_production_pxe.vmlinuz root=squashfs: state=tmpfs: sshkey="YOUR_PUBLIC_KEY_HERE"
initrd ${base-url}/coreos_production_pxe_image.cpio.gz
boot
```
Make sure to replace `YOUR_PUBLIC_KEY_HERE` with your actual public key, it will begin with "ssh-rsa...".

Additional reading can be found at [Booting CoreOS with iPXE](http://coreos.com/docs/running-coreos/bare-metal/booting-with-ipxe/) and [Embedded scripts for iPXE](http://ipxe.org/embed).

## Getting CoreOS running

Once you have received the email indicating the VPS is ready, click "Manage" for that VPS in your Vultr account area. Under "Server Actions" Click on "View Console" which will open a new window, and show the iPXE command prompt.

Type the following commands:

```
iPXE> dhcp
```
The output should end with "OK".

then type:

```
iPXE> chain http://example.com/script.txt
```

You'll see several lines scroll past on the console as the kernel is loaded, and then the initrd is loaded. CoreOS will automatically then boot up, and you'll end up at a login prompt. 

## Accessing the VPS

You can now login to CoreOS, assuming the associated private key is in place on your local computer you'll immediately be logged in. You may need to specify the specific location using ```-i LOCATION```. If you need additional details on how to specify the location of your private key file see [here](http://www.cyberciti.biz/faq/force-ssh-client-to-use-given-private-key-identity-file/).

SSH to the IP of your VPS, and specify the "core" user specifically: ```ssh core@IP_HERE```


```
$ ssh core@IP_HERE
The authenticity of host 'IP_HERE (2a02:1348:17c:423d:24:19ff:fef1:8f6)' can't be established.
RSA key fingerprint is 99:a5:13:60:07:5d:ac:eb:4b:f2:cb:c9:b2:ab:d7:21.
Are you sure you want to continue connecting (yes/no)? yes

Last login: Thu Oct 17 11:42:04 UTC 2013 from YOUR_IP on pts/0
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/
core@srv-n8uak ~ $
```


## Using CoreOS

Now that you have a cluster bootstrapped it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
