---
layout: docs
title: Mounting Storage
category: cluster_management
sub_category: setting_up
weight: 7
---

# Mounting Storage

Many platforms provide attached storage, but it must be mounted for you to take advantage of it. You can easily do this via [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config) with a `.mount` unit. Here's an example that mounts an [EC2 ephemeral disk]({{site.url}}/docs/running-coreos/cloud-providers/ec2/#instance-storage):

```
#cloud-config

coreos:
  units:
    - name: media-ephemeral.mount
      command: start
      content: |
        [Mount]
        What=/dev/xvdb
        Where=/media/ephemeral
        Type=ext3
```

As you can see, it's pretty simple. You specify the attached device and where you want it mounted. Optionally, you can provide a file system type.

It's important to note that [systemd requires](http://www.freedesktop.org/software/systemd/man/systemd.mount.html) mount units to be named after the "mount point directories they control". In our example above, we want our device mounted at `/media/ephemeral` so it must be named `media-ephemeral.mount`.

## Further Reading

Read the [full docs](http://www.freedesktop.org/software/systemd/man/systemd.mount.html) to learn about the available options. Examples specific to [EC2](http://localhost:9001/docs/running-coreos/cloud-providers/ec2/#instance-storage), [Google Compute Engine](http://localhost:9001/docs/running-coreos/cloud-providers/google-compute-engine/#additional-storage) and [Rackspace Cloud](http://localhost:9001/docs/running-coreos/cloud-providers/rackspace/#mount-data-disk) can be used as a starting point.