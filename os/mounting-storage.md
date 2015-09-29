# Mounting Storage

Many platforms provide attached storage, but it must be mounted for you to take advantage of it. You can easily do this via [cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config) with a `.mount` unit. Here's an example that mounts an [EC2 ephemeral disk]({{site.baseurl}}/docs/running-coreos/cloud-providers/ec2/#instance-storage):

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

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantageous to use attached storage to expand your capacity for container images. Be aware that some cloud providers treat certain disks as ephemeral and you will lose all Docker images contained on that disk.

We're going to mount a btrfs device to `/var/lib/docker`, where Docker stores images. We can do this on the fly when the machines starts up with a oneshot unit that formats the drive and another one that runs afterwards to mount it. Be sure to hardcode the correct device or look for a device by label:

```yaml
#cloud-config
coreos:
  units:
    - name: format-ephemeral.service
      command: start
      content: |
        [Unit]
        Description=Formats the ephemeral drive
        After=dev-xvdb.device
        Requires=dev-xvdb.device
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
        After=format-ephemeral.service
        Before=docker.service
        [Mount]
        What=/dev/xvdb
        Where=/var/lib/docker
        Type=btrfs
```

Notice that we're starting both units at the same time and using the power of systemd to work out the dependencies for us. In this case, `var-lib-docker.mount` requires `format-ephemeral.service`, ensuring that our storage will always be formatted before it is mounted. Docker will refuse to start otherwise.

## Creating and Mounting a btrfs Volume File

CoreOS [561.0.0](https://coreos.com/releases/#561.0.0) and later are installed with ext4 + overlayfs to provide a layered filesystem for the root partition.
Installations from prior to this, are using btrfs for this functionality.
If you'd like to continue using btrfs on newer CoreOS machines, you can do so with two systemd units: one that creates and formats a btrfs volume file and another that mounts it.

In this example, we are going to mount a new 25GB btrfs volume file to `/var/lib/docker`, and one can verify that Docker is using the btrfs storage driver once the Docker service has started by executing `sudo docker info`.
We recommend allocating **no more than 85%** of the available disk space for a btrfs filesystem as journald will also require space on the host filesystem.

```yaml
#cloud-config
coreos:
  units:
    - name: format-var-lib-docker.service
      command: start
      content: |
        [Unit]
        Before=docker.service var-lib-docker.mount
        ConditionPathExists=!/var/lib/docker.btrfs
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/truncate --size=25G /var/lib/docker.btrfs
        ExecStart=/usr/sbin/mkfs.btrfs /var/lib/docker.btrfs
    - name: var-lib-docker.mount
      enable: true
      content: |
        [Unit]
        Before=docker.service
        After=format-var-lib-docker.service
        Requires=format-var-lib-docker.service
        [Install]
        RequiredBy=docker.service
        [Mount]
        What=/var/lib/docker.btrfs
        Where=/var/lib/docker
        Type=btrfs
        Options=loop,discard
```

Note the declaration of `ConditionPathExists=!/var/lib/docker.btrfs`. Without this line, systemd would reformat the btrfs filesystem every time the machine starts.

## Mounting NFS Exports

This cloud-config excerpt enables the NFS host monitor [`rpc.statd(8)`](http://linux.die.net/man/8/rpc.statd), then mounts an NFS export onto the CoreOS system's `/var/www`. Mount unit names match the target mount point, with interior slashes replaced by dashes. A unit mounting onto `/var/www` is thus named `var-www.mount`.

```yaml
#cloud-config
coreos:
  units:
    - name: rpc-statd.service
      command: start
      enable: true
    - name: var-www.mount
      command: start
      content: |
        [Mount]
        What=nfs.example.com:/var/www
        Where=/var/www
        Type=nfs
```

To declare that another service depends on this mount, name the mount unit in the dependent unit's `After` and `Requires` properties:

```yaml
[Unit]
After=var-www.mount
Requires=var-www.mount
```

If the mount fails, dependent units will not start.

## Further Reading

Check the [`systemd mount` docs](http://www.freedesktop.org/software/systemd/man/systemd.mount.html) to learn about the available options. Examples specific to [EC2]({{site.baseurl}}/docs/running-coreos/cloud-providers/ec2/#instance-storage), [Google Compute Engine]({{site.baseurl}}/docs/running-coreos/cloud-providers/google-compute-engine/#additional-storage) and [Rackspace Cloud]({{site.baseurl}}/docs/running-coreos/cloud-providers/rackspace/#mount-data-disk) can be used as a starting point.
