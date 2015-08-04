# Using systemd and udev Rules 

In our example we will use libvirt VM. First of all we have to create systemd unit file `/etc/systemd/system/test.service`:

```
[Service]
Type=oneshot
ExecStart=/usr/bin/echo 'device has been attached'
```

Then we have to start `udevadm monitor --environment` to monitor kernel events.

Once you've attached virtio libvirt device (i.e. `virsh attach-disk coreos /dev/VG/test vdc`) you'll see similar udev output:

```
UDEV  [545.954641] add      /devices/pci0000:00/0000:00:18.0/virtio4/block/vdb (block)
.ID_FS_TYPE_NEW=
ACTION=add
DEVNAME=/dev/vdb
DEVPATH=/devices/pci0000:00/0000:00:18.0/virtio4/block/vdb
DEVTYPE=disk
ID_FS_TYPE=
MAJOR=254
MINOR=16
SEQNUM=1327
SUBSYSTEM=block
SYSTEMD_WANTS=test.service
TAGS=:systemd:
USEC_INITIALIZED=545954447
```

Accoring to text beyond udev rule should look this way:

```
ACTION=="add", SUBSYSTEM=="block", TAG+="systemd", ENV{SYSTEMD_WANTS}="test.service"
```

Now when we use this command `virsh attach-disk coreos /dev/VG/test vdc` on host machine, we should see `device has been attached` message inside CoreOS node.

## Cloud-Config example

Cloud-Config example should look this way:

```yaml
#cloud-config
write_files:
  - path: /etc/udev/rules.d/01-block.rules
    permissions: 0644
    owner: root
    content: |
      ACTION=="add", SUBSYSTEM=="block", TAG+="systemd", ENV{SYSTEMD_WANTS}="test.service"
coreos:
  units:
    - name: test.service
      content: |
        [Unit]
        Description=Notify about attached device

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/echo 'device has been attached'
```

## Another Examples

For another real examples, check out these documents:

[Customizing Docker]({{site.baseurl}}/os/docs/latest/customizing-docker.html#using-a-dockercfg-file-for-authentication)
[Customizing the SSH Daemon]({{site.baseurl}}/os/docs/latest/customizing-sshd.html#changing-the-sshd-port)

## More Information
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.target.html">systemd.target Docs</a>
