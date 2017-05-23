# Building custom kernel modules

## Create a writable overlay

The kernel modules directory `/lib/modules` is read-only on Container Linux. A writable overlay can be mounted over it to allow installing new modules.

```sh
modules=/opt/modules  # Adjust this writable storage location as needed.
sudo mkdir -p "$modules" "$modules.wd"
sudo mount \
    -o "lowerdir=/lib/modules,upperdir=$modules,workdir=$modules.wd" \
    -t overlay overlay /lib/modules
```

The following systemd unit can be written to `/etc/systemd/system/lib-modules.mount`.

```ini
[Unit]
Description=Custom Kernel Modules
Before=local-fs.target
ConditionPathExists=/opt/modules

[Mount]
Type=overlay
What=overlay
Where=/lib/modules
Options=lowerdir=/lib/modules,upperdir=/opt/modules,workdir=/opt/modules.wd

[Install]
WantedBy=local-fs.target
```

Enable the unit so this overlay is mounted automatically on boot.

```sh
sudo systemctl enable lib-modules.mount
```

## Prepare a CoreOS Container Linux development container

Read system configuration files to determine the URL of the development container that corresponds to the current Container Linux version.

```sh
. /usr/share/coreos/release
. /usr/share/coreos/update.conf
. /etc/coreos/update.conf  # This might not exist.
url="https://${GROUP:-stable}.release.core-os.net/$COREOS_RELEASE_BOARD/$COREOS_RELEASE_VERSION/coreos_developer_container.bin.bz2"
```

Download, decompress, and verify the development container image.

```sh
gpg2 --recv-keys 04127D0BFABEC8871FFB2CCE50E0885593D2DCB4  # Fetch the buildbot key if neccesary.
curl -L "$url" |
    tee >(bzip2 -d > coreos_developer_container.bin) |
    gpg2 --verify <(curl -Ls "$url.sig") -
```

Start the development container with the host's writable modules directory mounted into place.

```sh
sudo systemd-nspawn \
    --bind=/lib/modules \
    --image=coreos_developer_container.bin
```

Now, inside the container, fetch the Container Linux packages and check out the current version. The `git checkout` command might fail on the latest alpha, before its version is branched from `master`, so staying on the `master` branch is correct in that case.

```sh
emerge-gitclone
. /usr/share/coreos/release
git -C /var/lib/portage/coreos-overlay checkout build-${COREOS_RELEASE_VERSION%%.*}
```

Still inside the container, download and prepare the Linux kernel source for building external modules.

```sh
emerge -gKv coreos-sources
gzip -cd /proc/config.gz > /usr/src/linux/.config
make -C /usr/src/linux modules_prepare
```

## Build and install kernel modules

At this point, upstream projects' instructions for building their out-of-tree modules should work in the Container Linux development container. New kernel modules should be installed into `/lib/modules`, which is bind-mounted from the host, so they will be available on future boots without using the container again.

In case the installation step didn't update the module dependency files automatically, running the following command will ensure commands like `modprobe` function correctly with the new modules.

```sh
sudo depmod
```
