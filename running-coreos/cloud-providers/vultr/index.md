---
layout: docs
title: Vultr VPS Provider
category: running_coreos
sub_category: cloud_provider
weight: 10
---

# Running CoreOS {{site.brightbox-version}} on a Vultr VPS

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through running a single CoreOS node. This guide assumes you have an account at [Vultr.com](http://vultr.com).


## List Images

You can find it by listing all images and grepping for CoreOS:

```
$ brightbox images list | grep CoreOS

 id         owner      type      created_on  status   size   name
 ---------------------------------------------------------------------------------------------------------
 {{site.brightbox-id}}  brightbox  official  2013-12-15  public   5442   CoreOS {{site.brightbox-version}} (x86_64)
 ```

## Building Servers

Before building the cluster, we need to generate a unique identifier for it, which is used by CoreOS to discover and identify nodes.

You can use any random string so we’ll use the `uuid` tool here to generate one:

```
$ TOKEN=`uuid`

$ echo $TOKEN
53cf11d4-3726-11e3-958f-939d4f7f9688
```

Then build three servers using the image, in the server group we created and specifying the token as the user data:


## Accessing the Cluster

Those servers should take just a minute to build and boot. They automatically install your Brightbox Cloud ssh key on bootup, so you can ssh in straight away as the `core` user.

If you’ve got ipv6 locally, you can ssh in directly:

```
$ ssh core@ipv6.srv-n8uak.gb1.brightbox.com
The authenticity of host 'ipv6.srv-n8uak.gb1.brightbox.com (2a02:1348:17c:423d:24:19ff:fef1:8f6)' can't be established.
RSA key fingerprint is 99:a5:13:60:07:5d:ac:eb:4b:f2:cb:c9:b2:ab:d7:21.
Are you sure you want to continue connecting (yes/no)? yes

Last login: Thu Oct 17 11:42:04 UTC 2013 from srv-4mhaz.gb1.brightbox.com on pts/0
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/
core@srv-n8uak ~ $
```

If you don’t have ipv6, you’ll need to [create and map a Cloud IP](http://brightbox.com/docs/guides/cli/cloud-ips/) first.

## Using CoreOS

Now that you have a cluster bootstrapped it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
