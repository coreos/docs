# Tips and other settings

## Loading kernel modules

Most Linux kernel modules get automatically loaded as-needed but there are a some situations where this doesn't work. Problems can arise if there is boot-time dependencies are sensitive to exactly when the module gets loaded. Module auto-loading can be broken all-together if the operation requiring the module happens inside of a container. `iptables` and other netfilter features can easily encounter both of these issues. To force a module to be loaded early during boot simply list them in a file under `/etc/modules-load.d`. The file name must end in `.conf`.

```sh
echo nf_conntrack > /etc/modules-load.d/nf.conf
```

Or, using a Container Linux Config:

```yaml container-linux-config
storage:
  files:
    - path: /etc/modules-load.d/nf.conf
      filesystem: root
      mode: 0644
      contents:
        inline: nf_conntrack
```

### Loading kernel modules with options

The following section demonstrates how to provide module options when loading. After these configs are processed, the dummy module is loaded into the kernel, and five dummy interfaces are added to the network stack.

Further details can be found in the systemd man pages:
[modules-load.d(5)](http://www.freedesktop.org/software/systemd/man/modules-load.d.html)
[systemd-modules-load.service(8)](http://www.freedesktop.org/software/systemd/man/systemd-modules-load.service.html)
[modprobe.d(5)](http://linux.die.net/man/5/modprobe.d)

This example Container Linux Config loads the `dummy` network interface module with an option specifying the number of interfaces the module should create when loaded (`numdummies=5`):

```yaml container-linux-config
storage:
  files:
    - path: /etc/modprobe.d/dummy.conf
      filesystem: root
      mode: 0644
      contents:
        inline: options dummy numdummies=5
    - path: /etc/modules-load.d/dummy.conf
      filesystem: root
      mode: 0644
      contents:
        inline: dummy
```

## Tuning sysctl parameters

The Linux kernel offers a plethora of knobs under `/proc/sys` to control the availability of different features and tune performance parameters. For one-shot changes values can be written directly to the files under `/proc/sys` but persistent settings must be written to `/etc/sysctl.d`:

```sh
echo net.netfilter.nf_conntrack_max=131072 > /etc/sysctl.d/nf.conf
sysctl --system
```

Some parameters, such as the conntrack one above, are only available after the module they control has been loaded. To ensure any modules are loaded in advance use `modules-load.d` as described above. A complete Container Linux Config using both would look like:

```yaml container-linux-config
storage:
  files:
    - path: /etc/modules-load.d/nf.conf
      filesystem: root
      mode: 0644
      contents:
        inline: |
          nf_conntrack
    - path: /etc/sysctl.d/nf.conf
      filesystem: root
      mode: 0644
      contents:
        inline: |
          net.netfilter.nf_conntrack_max=131072
```

Further details can be found in the systemd man pages:
[sysctl.d(5)](http://www.freedesktop.org/software/systemd/man/sysctl.d.html)
[systemd-sysctl.service(8)](http://www.freedesktop.org/software/systemd/man/systemd-sysctl.service.html)

## Adding custom kernel boot options

The Container Linux bootloader parses the configuration file `/usr/share/oem/grub.cfg`, where custom kernel boot options may be set.

The `/usr/share/oem/grub.cfg` file can be configured with Ignition. Note that Ignition runs after GRUB. Therefore, the GRUB configuration won't take effect until the next reboot of the node. 

Here's an example configuration:

```yaml container-linux-config
storage:
  filesystems:
    - name: "OEM"
      mount:
        device: "/dev/disk/by-label/OEM"
        format: "ext4"
  files:
    - filesystem: "OEM"
      path: "/grub.cfg"
      mode: 0644
      append: true
      contents:
        inline: |
          set linux_append="$linux_append coreos.autologin=tty1"
```

### Enable CoreOS Container Linux autologin

To login without a password on every boot, edit `/usr/share/oem/grub.cfg` to add the line:

```
set linux_append="coreos.autologin=tty1"
```

### Enable systemd debug logging

Edit `/usr/share/oem/grub.cfg` to add the following line, enabling systemd's most verbose `debug`-level logging:

```
set linux_append="systemd.log_level=debug"
```

### Mask a systemd unit

Completely disable the `systemd-networkd.service` unit by adding this line to `/usr/share/oem/grub.cfg`:

```
set linux_append="systemd.mask=systemd-networkd.service"
```

## Adding custom messages to MOTD

When logging in interactively, a brief message (the "Message of the Day (MOTD)") reports the Container Linux release channel, version, and a list of any services or systemd units that have failed. Additional text can be added by dropping text files into `/etc/motd.d`. The directory may need to be created first, and the drop-in file name must end in `.conf`. Container Linux versions 555.0.0 and greater support customization of the MOTD.

```sh
mkdir -p /etc/motd.d
echo "This machine is dedicated to computing Pi" > /etc/motd.d/pi.conf
```

Or via a Container Linux Config:

```yaml container-linux-config
storage:
  files:
    - path: /etc/motd.d/pi.conf
      filesystem: root
      mode: 0644
      contents:
        inline: This machine is dedicated to computing Pi
```

## Prevent login prompts from clearing the console

The system boot messages that are printed to the console will be cleared when systemd starts a login prompt. In order to preserve these messages, the `getty` services will need to have their `TTYVTDisallocate` setting disabled. This can be achieved with a drop-in for the template unit, `getty@.service`. Note that the console will still scroll so the login prompt is at the top of the screen, but the boot messages will be available by scrolling.

```sh
mkdir -p '/etc/systemd/system/getty@.service.d'
echo -e '[Service]\nTTYVTDisallocate=no' > '/etc/systemd/system/getty@.service.d/no-disallocate.conf'
```

Or via a Container Linux Config:

```yaml container-linux-config
systemd:
  units:
    - name: getty@.service
      dropins:
        - name: no-disallocate.conf
          contents: |
            [Service]
            TTYVTDisallocate=no
```

When the `TTYVTDisallocate` setting is disabled, the console scrollback is not cleared on logout, not even by the `clear` command in the default `.bash_logout` file. Scrollback must be cleared explicitly, e.g. by running `echo -en '\033[3J' > /dev/console` as the root user.
