---
layout: docs
slug: ec2
title: Documentation
us-east-1-ami: ami-48f78d21
docker-version: 0.5
systemd-version: 204
---

# Running CoreOS on EC2

CoreOS is currently in heavy development and actively being tested. The following instructions will bring up multiple CoreOS instances all sharing configuration data using [etcd][etcd-docs]. All of these instructions assume `us-east-1` EC2 region.

This will launch three t1.micro instances with `etcd` clustered sharing data between the hosts. To add more instances to the cluster, just launch more with the same `user-data`.

**TL;DR:** launch three instances of [{{ page.us-east-1-ami }}][ec2-us-east-1] in a security group that has open port 22, 4001, and 7001 and the same random token in the "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [docker][docker-docs] to play with.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Creating the security group

You need open port 7001 and 4001 between servers in the `etcd` cluster. Step by step instructions below.

_This step is only needed once_

First we need to create a security group to allow CoreOS instances to communicate with one another. 

1. Go to the [security group][sg] page in the EC2 console.
2. Click "Create Security Group"
    * Name: coreos-testing
    * Description: CoreOS instances 
    * VPC: No VPC
    * Click: "Yes, Create"
3. In the details of the security group, click the `Inbound` tab
4. First, create an open rule for SSH
    * Create a new rule: `SSH`
    * Source: 0.0.0.0/0
    * Click: "Add Rule"
5. Add rule for etcd internal communication
    * Create a new rule: `Custom TCP rule`
    * Port range: 7001, 4001
    * Source: type "coreos-testing" until your security group auto-completes. Should be something like "sg-8d4feabc"
    * Click: "Add Rule"
6. Click "Apply Rule Changes"

[sg]: https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups

## Launching a test cluster

We will be launching three instances, with a shared token (via a gist url) in the User Data, and selecting our security group.

1. Open the quick launch by clicking [here][ec2-us-east-1] (shift+click for new tab)
    * For reference, the current us-east-1 is: [{{ page.us-east-1-ami }}][ec2-us-east-1]
2. On the second page of the wizard, launch 3 servers to test our clustering
    * Number of instances: 3 
    * Click "Continue"
3. Next, we need a secret shared token for user-data. This will be used to bootstrap the cluster. This needs to be a reasonably long secret key. We like using gist for this, since each gist url is public but unique. 
   * Open [gist.github.com](https://gist.github.com)
   * Optional: If you paste in your public ssh key to the gist, it will automatically be added to your `core` users ssh client list. 
   * Click "Create secret gist"
   * Copy the gist url to your clipboard. 
4. Back in the EC2 dashboard, paste this URL verbatim into the "User Data" field. 
   * Paste "https://gist..." link into "User Data"
   * "Continue"
5. Storage Configuration
   * "Continue"
6. Tags
   * "Continue"
7 Create Key Pair
   * Choose a key of your choice, it will be added in addition to the one in the gist.
   * "Continue"
8. Choose one or more of your existing Security Groups
   * "coreos-testing" as above.
9. Launch!

## Using CoreOS

Now that you have a few machines booted it is time to play around. Check out the [Using CoreOS][using-coreos] guide.

[ec2-us-east-1]: https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi={{ page.us-east-1-ami }}
