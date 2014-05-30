---
layout: docs
title: Mounting Storage
category: cluster_management
sub_category: setting_up
weight: 7
---

# Mounting Storage

Many platforms provide attached storage, but it must be mounted for you to take advantage of it. You can easily do this via [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config) with a `.mount` unit. Here's an example that mounts an [EC2 ephemeral disk]({{site.url}}/docs/running-coreos/cloud-providers/ec2/#instance-storage):

```yaml
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

## Use Attached Storage for Docker

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantagous to use attached storage to expand your capacity for container images. Be aware that some cloud providers treat certain disks as ephemeral and you will lose all docker images contained on that disk.

We're going to bind mount a btrfs device to `/var/lib/docker`, where docker stores images. We can do this on the fly when the machines starts up with a oneshot unit that formats the drive and another one that runs afterwards to mount it. Be sure to hardcode the correct device or look for a device by label:

```yaml
#cloud-config
coreos:
  units
    - name: format-ephemeral.service
      command: start
      content: |
        [Unit]
        Description=Formats the ephemeral drive
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/sbin/wipefs -f /dev/xvdb
        ExecStart=/usr/sbin/mkfs.btrfs -f /dev/xvdb
    - name: var-lib-docker.mount
      command: start
      content: |
        [Unit]
        Description=Mount ephemeral to /var/lib/docker
        Requires=format-ephemeral.service
        Before=docker.service
        [Mount]
        What=/dev/xvdb
        Where=/var/lib/docker
        Type=btrfs
```

Notice that we're starting all three of these units at the same time and using the power of systemd to work out the dependencies for us. In this case, `docker-storage.service` requires `format-ephemeral.service`, ensuring that our storage will always be formatted before it is bind mounted. Docker will refuse to start otherwise.

## Further Reading

Read the [full docs](http://www.freedesktop.org/software/systemd/man/systemd.mount.html) to learn about the available options. Examples specific to [EC2]({{site.url}}/docs/running-coreos/cloud-providers/ec2/#instance-storage), [Google Compute Engine]({{site.url}}/docs/running-coreos/cloud-providers/google-compute-engine/#additional-storage) and [Rackspace Cloud]({{site.url}}/docs/running-coreos/cloud-providers/rackspace/#mount-data-disk) can be used as a starting point.