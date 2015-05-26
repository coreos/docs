---
layout: docs
title: SDK Tips and Tricks
category: sdk_distributors
sub_category: sdk
weight: 7
---

# Tips and Tricks

## Finding all open pull requests and issues

- [CoreOS Issues][issues]
- [CoreOS Pull Requests][pullrequests]

[issues]: https://github.com/organizations/coreos/dashboard/issues/
[pullrequests]: https://github.com/organizations/coreos/dashboard/pulls/

## Searching all repo code

Using `repo forall` you can search across all of the Git repos at once:

```sh
repo forall -c  git grep 'CONFIG_EXTRA_FIRMWARE_DIR'
```

## Add new upstream package

Before making modifications use `repo start` to create a new branch for the changes.

To add a new package fetch the Gentoo package from upstream and add the package as a dependency of coreos-base/coreos

If any files in the upstream package will be changed the package can be fetched from upstream Gentoo directly into `src/third_party/coreos-overlay` it may be necessary to create any missing directories in the path too.

e.g.

```sh
~/trunk/src/third_party/coreos-overlay $ mkdir -p sys-block/open-iscsi && rsync -av rsync://rsync.gentoo.org/gentoo-portage/sys-block/open-iscsi/ sys-block/open-iscsi/
```

The tailing / prevents rsync from creating the directory for the package so you don't end up with `sys-block/open-iscsi/open-iscsi`
Remember to add the new files to git.

If the new package does not need to be modified the package should be placed in `src/third_party/portage-stable`

You can use `scripts/update_ebuilds` to fetch packages into `src/third_party/portage-stable` and add the files to git.
You should specify the category and the packagename.
e.g.
`./update_ebuilds sys-block/open-iscsi`

If the package needs to be modified it must be moved out of `src/third_party/portage-stable` to `src/third_party/coreos-overlay`

To include the new package as a dependency of coreos add the package to the end of the RDEPEND environment variable in `coreos-base/coreos/coreos-0.0.1.ebuild` then increment the revision of coreos by renaming the softlink `git mv coreos-base/coreos/coreos-0.0.1-r237.ebuild coreos-base/coreos/coreos-0.0.1-r238.ebuild`

The new package will now be built and installed as part of the normal build flow.

Add and commit the changes to git using AngularJS format. See [CONTRIBUTING.md]
[CONTRIBUTING.md]: https://github.com/coreos/etcd/blob/master/CONTRIBUTING.md

Push the changes to your GitHub fork and create a pull request.

### Ebuild Tips

- Manually merge a package to the chroot to test build `emerge-amd64-usr packagename`
- Manually unmerge a package `emerge-amd64-usr --unmerge packagename`
- Remove a binary package from the cache `sudo rm /build/amd64-usr/packages/catagory/packagename-version.tbz2`
- recreate the chroot prior to a clean rebuild `./chromite/bin/cros_sdk -r`
- it may be necessary to comment out kernel source checks from the ebuild if the build fails -- as coreos does not  yet provide visibility of the configured kernel source at build time -- usually this is not a problem but may lead to warning messages
- Chromium OS [Portage Build FAQ]
- [Gentoo Development Guide]


[Portage Build FAQ]: http://www.chromium.org/chromium-os/how-tos-and-troubleshooting/portage-build-faq
[Gentoo Development Guide]: http://devmanual.gentoo.org/

## Caching git https passwords

Note: You need git 1.7.10 or newer to use the credential helper

Turn on the credential helper and git will save your password in memory
for some time:

```sh
git config --global credential.helper cache
```

Why doesn't CoreOS use SSH in the git remotes? Because, we can't do
anonymous clones from GitHub with an SSH URL. In the future we will fix
this.

### Base system dependency graph

Get a view into what the base system will contain and why it will contain those
things with the emerge tree view:

```sh
emerge-amd64-usr  --emptytree  -p -v --tree  coreos-base/coreos-dev
```

## SSH Config

You will be booting lots of VMs with on the fly ssh key generation. Add
this in your `$HOME/.ssh/config` to stop the annoying fingerprint warnings.

```ini
Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User core
  LogLevel QUIET
```

## Hide loop devices from desktop environments

By default desktop environments will diligently display any mounted devices
including loop devices used to construct CoreOS disk images. If the daemon
responsible for this happens to be ``udisks`` then you can disable this
behavior with the following udev rule:

```sh
echo 'SUBSYSTEM=="block", KERNEL=="ram*|loop*", ENV{UDISKS_PRESENTATION_HIDE}="1", ENV{UDISKS_PRESENTATION_NOPOLICY}="1"' > /etc/udev/rules.d/85-hide-loop.rules
udevadm control --reload
```

## Leaving developer mode

Some daemons act differently in "dev mode". For example update_engine refuses
to auto-update or connect to HTTPS URLs. If you need to test something out of
dev_mode on a vm you can do the following:

```
mv /root/.dev_mode{,.old}
```

If you want to permanently leave you can run the following:

```
crossystem disable_dev_request=1; reboot
```

## Known Issues

### build\_packages fails on coreos-base

Sometimes coreos-dev or coreos builds will fail in `build_packages` with a
backtrace pointing to `epoll`. This hasn't been tracked down but running
`build_packages` again should fix it. The error looks something like this:

```
Packages failed:
coreos-base/coreos-dev-0.1.0-r63
coreos-base/coreos-0.0.1-r187
```

## Constants and IDs

### CoreOS App ID

This UUID is used to identify CoreOS to the update service and elsewhere.

```
e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

### GPT UUID Types

- CoreOS Root: 5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6
- CoreOS Reserved: c95dc21a-df0e-4340-8d7b-26cbfa9a03e0
