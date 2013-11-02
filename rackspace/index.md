---
layout: docs
slug: rackspace
title: Documentation - Rackspace
---

# Running CoreOS on Rackspace

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through running CoreOS on the Rackspace Openstack cloud, which differs slightly from the generic Openstack instructions. We're going to install `rackspace-novaclient`, upload a keypair and boot the image id `430d35e0-1468-4007-b063-52ee1921b356`.

## Install Rackspace CLI

If you don't have `pip` installed, install it by running `sudo easy_install pip`. Now let's use `pip` to install the Rackspace fork of the Nova CLI. This fork supports Rackspace's custom authentication method.

`pip install rackspace-novaclient`

## Edit Bash Profile

Edit your bash profile (`~/.bash_profile`) to store your username, API key and some other settings:

```
OS_USERNAME=username
OS_TENANT_NAME=username
OS_AUTH_SYSTEM=rackspace
OS_PASSWORD=api_token
OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
OS_REGION_NAME=IAD
OS_NO_CACHE=1
export OS_USERNAME OS_TENANT_NAME OS_AUTH_SYSTEM OS_PASSWORD OS_AUTH_URL OS_REGION_NAME OS_NO_CACHE
```

After saving your profile, load the settings so `rackspace-novaclient` can read them:

```
source .bash_profile
```

We're ready to create a keypair then boot a server with it.

## Create Keypair

For this guide, I'm assuming you already have a public key you use for your CoreOS servers. Note that only RSA keypairs are supported. Load the public key to Rackspace:

```
nova keypair-add --pub-key ~/.ssh/coreos.pub coreos-key
```

Check you make sure the key is in your list by running `nova keypair-list`

```
+------------+-------------------------------------------------+
| Name       | Fingerprint                                     |
+------------+-------------------------------------------------+
| coreos-key | d0:6b:d8:3a:3e:6a:52:43:32:bc:01:ea:c2:0f:49:59 |
+------------+-------------------------------------------------+
```

## Boot a Server

Boot a new server with our new keypair:

```
nova boot --image 430d35e0-1468-4007-b063-52ee1921b356 --flavor 2 My_CoreOS_Server --key-name coreos-key
```

You should now see the details of your new server in your terminal and it should also show up in the control panel:

```
+------------------------+--------------------------------------+
| Property               | Value                                |
+------------------------+--------------------------------------+
| status                 | BUILD                                |
| updated                | 2013-11-02T19:43:45Z                 |
| hostId                 |                                      |
| key_name               | coreos-key                           |
| image                  | CoreOS                               |
| OS-EXT-STS:task_state  | scheduling                           |
| OS-EXT-STS:vm_state    | building                             |
| flavor                 | 512MB Standard Instance              |
| id                     | 82dbe66d-0762-4cba-a286-8c1af8431e47 |
| user_id                | 3c55bca772ba4a4bb6a4eb5b25754738     |
| name                   | My_CoreOS_Server	                    |
| adminPass              | mgNqEx7I9pQA                         |
| tenant_id              | 833111                               |
| created                | 2013-11-02T19:43:44Z                 |
| OS-DCF:diskConfig      | MANUAL                               |
| accessIPv4             |                                      |
| accessIPv6             |                                      |
| progress               | 0                                    |
| OS-EXT-STS:power_state | 0                                    |
| metadata               | {}                                   |
+------------------------+--------------------------------------+
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out
the [Using CoreOS][using-coreos] guide.
