# Tips and tricks

## Finding all open pull requests and issues

- [CoreOS Issues][issues]
- [CoreOS Pull Requests][pullrequests]

[issues]: https://github.com/issues?user=coreos
[pullrequests]: https://github.com/pulls?user=coreos

## Searching all repo code

Using `repo forall` you can search across all of the Git repos at once:

```sh
repo forall -c  git grep 'CONFIG_EXTRA_FIRMWARE_DIR'
```

Note: this could take some time.

### Base system dependency graph

Get a view into what the base system will contain and why it will contain those things with the emerge tree view:

```sh
emerge-amd64-usr --emptytree -p -v --tree coreos-base/coreos-dev
```

## Add new upstream package

An overview on contributing new packages to Container Linux:

- create a git branch for the work
- fetch the the target package(s) from upstream (Gentoo)
- make any necessary changes for Container Linux
- add the package(s) as a dependency of `coreos-base/coreos`
- build the package(s) and test
- commit changes to git
- push the branch to your GitHub account and create a pull request

See [CONTRIBUTING] for guidelines before you push.  

The following Container Linux repositories are used:

- Packages that will work unmodified are versioned in ```src/third_party/portage-stable```
- Packages with Container-Linux-specific changes are versioned in ```src/third_party/coreos-overlay```

Use `repo start` to create a work branch before making any changes.

```sh
~/trunk/src/scripts $ repo start my_package_update --all 
```

You can use `scripts/update_ebuilds` to fetch unmodified packages into `src/third_party/portage-stable` and add the files to git. The package argument should be in the format of `category/package-name`, e.g.:

```sh
~/trunk/src/scripts $ ./update_ebuilds sys-block/open-iscsi
```

Modified packages must be moved out of `src/third_party/portage-stable` to `src/third_party/coreos-overlay`.

If you know in advance that any files in the upstream package will need to be changed, the package can be fetched from upstream Gentoo directly into `src/third_party/coreos-overlay`. e.g.:

```sh
~/trunk/src/third_party/coreos-overlay $ mkdir -p sys-block/open-iscsi
~/trunk/src/third_party/coreos-overlay $ rsync -av rsync://rsync.gentoo.org/gentoo-portage/sys-block/open-iscsi/ sys-block/open-iscsi/
```

The tailing / prevents rsync from creating the directory for the package so you don't end up with `sys-block/open-iscsi/open-iscsi`. Remember to add any new files to git.

To quickly test your new package(s), use the following commands:

```sh
~/trunk/src/scripts $ # Manually merge a package in the chroot
~/trunk/src/scripts $ emerge-amd64-usr packagename
~/trunk/src/scripts $ # Manually unmerge a package in the chroot
~/trunk/src/scripts $ emerge-amd64-usr --unmerge packagename
~/trunk/src/scripts $ # Remove a binary from the cache
~/trunk/src/scripts $ sudo rm /build/amd64-usr/packages/catagory/packagename-version.tbz2
```

To recreate the chroot prior to a clean rebuild, exit the chroot and run:

```sh
~/coreos $ ./chromite/bin/cros_sdk -r
```

To include the new package as a dependency of Container Linux, add the package to the end of the `RDEPEND` environment variable in `coreos-base/coreos/coreos-0.0.1.ebuild` then increment the revision of Container Linux by renaming the softlink (e.g.):

```sh
~/trunk/src/third_party/coreos-overly $ git mv coreos-base/coreos/coreos-0.0.1-r237.ebuild coreos-base/coreos/coreos-0.0.1-r238.ebuild
```

The new package will now be built and installed as part of the normal build flow when you run `build_packages` again.  

If tests are successful, commit the changes, push to your GitHub fork and create a pull request.

[CONTRIBUTING]: https://github.com/coreos/etcd/blob/master/CONTRIBUTING.md

### Packaging references

References:

- Chromium OS [Portage Build FAQ]
- [Gentoo Development Guide]
- [Package Manager Specification]

[Portage Build FAQ]: http://www.chromium.org/chromium-os/how-tos-and-troubleshooting/portage-build-faq
[Gentoo Development Guide]: http://devmanual.gentoo.org/
[Package Manager Specification]: https://wiki.gentoo.org/wiki/Package_Manager_Specification


## Caching git https passwords

Turn on the credential helper and git will save your password in memory for some time:

```sh
git config --global credential.helper cache
```

Note: You need git 1.7.10 or newer to use the credential helper

Why doesn't Container Linux use SSH in the git remotes?  Because we can't do anonymous clones from GitHub with an SSH URL.  This will be fixed eventually.

## SSH config

You will be booting lots of VMs with on the fly ssh key generation. Add this in your `$HOME/.ssh/config` to stop the annoying fingerprint warnings.

```ini
Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User core
  LogLevel QUIET
```

## Hide loop devices from desktop environments

By default desktop environments will diligently display any mounted devices including loop devices used to construct Container Linux disk images. If the daemon responsible for this happens to be ``udisks`` then you can disable this behavior with the following udev rule:

```sh
echo 'SUBSYSTEM=="block", KERNEL=="ram*|loop*", ENV{UDISKS_PRESENTATION_HIDE}="1", ENV{UDISKS_PRESENTATION_NOPOLICY}="1"' > /etc/udev/rules.d/85-hide-loop.rules
udevadm control --reload
```

## Leaving developer mode

Some daemons act differently in "dev mode". For example update_engine refuses to auto-update or connect to HTTPS URLs. If you need to test something out of dev_mode on a vm you can do the following:

```
mv /root/.dev_mode{,.old}
```

If you want to permanently leave you can run the following:

```
crossystem disable_dev_request=1; reboot
```

## Known issues

### build\_packages fails on coreos-base

Sometimes coreos-dev or coreos builds will fail in `build_packages` with a backtrace pointing to `epoll`. This hasn't been tracked down but running `build_packages` again should fix it. The error looks something like this:

```
Packages failed:
coreos-base/coreos-dev-0.1.0-r63
coreos-base/coreos-0.0.1-r187
```

### Newly added package fails checking for kernel sources

It may be necessary to comment out kernel source checks from the ebuild if the build fails, as Container Linux does not yet provide visibility of the configured kernel source at build time.  Usually this is not a problem, but may lead to warning messages.

### `coreos-kernel` fails to link after previously aborting a build

Emerging `coreos-kernel` (either manually or through `build_packages`) may fail with the error:

```/usr/lib/gcc/x86_64-pc-linux-gnu/4.9.4/../../../../x86_64-pc-linux-gnu/bin/ld: scripts/kconfig/conf.o: relocation R_X86_64_32 against `.rodata.str1.8' can not be used when making a shared object; recompile with -fPIC scripts/kconfig/conf.o: error adding symbols: Bad value```

This indicates the ccache is corrupt. To clear the ccache, run:

```CCACHE_DIR=/var/tmp/ccache ccache -C```

To avoid corrupting the ccache, do not abort builds.

### `build_image` hangs while emerging packages after previously aborting a build

Delete all `*.portage_lockfile`s in `/build/<arch>/`. To avoid stale lockfiles, do not abort builds.

## Constants and IDs

### CoreOS Container Linux app ID

This UUID is used to identify Container Linux to the update service and elsewhere.

```
e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

### GPT UUID types

- CoreOS Root: 5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6
- CoreOS Reserved: c95dc21a-df0e-4340-8d7b-26cbfa9a03e0
- CoreOS Raid Containing Root: be9067b9-ea49-4f15-b4f6-f36f8c9e1818
