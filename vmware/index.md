---
layout: docs
slug: vmware
title: Documentation
---

# Running CoreOS on VMware

CoreOS is currently in heavy development and actively being tested.
These instructions will walk you through running CoreOS on VMware Fusion.
If you are familiar with another VMware product you can use these instructions as a starting point.

## Running the VM

These steps will download the VMware image and extract the zip file. After that
you will need to launch the `coreos_developer_vmware_insecure.vmx` file.

This is a rough sketch that should work on OSX and Linux:

```
wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_vmware_insecure.zip
unzip coreos_developer_vmware_insecure.zip
cd coreos_developer_vmware_insecure
open coreos_developer_vmware_insecure.vmx
```

## Logging in

Networking can take a bit of time to come up under VMware and you will need to
know the IP in order to ssh in. Press enter a few times at the login prompt and
you should see an IP address pop up:

![VMware IP Address](vmware-ip.png)

In this case the IP is `10.0.1.81`.

Now you can login using the shared and insecure private ssh key.

```
cd coreos_developer_vmware_insecure
ssh -i insecure_ssh_key core@10.0.1.81
```

## Replacing the key

We highly recommend that you disable the original insecure OEM ssh key and
replace it with your own. This is a simple two step process, first add your
public key and then remove the original OEM one.

```
cat ~/.ssh/id_rsa.pub | ssh core@10.0.1.81 -i insecure_ssh_key update-ssh-keys -a user
ssh core@10.0.1.81 update-ssh-keys -D oem
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out
the [Using CoreOS][using-coreos] guide.
