---
layout: docs
title: SDK Tips and Tricks
category: sdk_distributors
sub_category: sdk
---

# Tips and Tricks

## Finding all open pull requests and issues

- [CoreOS Issues][issues]
- [CoreOS Pull Requests][pullrequests]

[issues]: https://github.com/organizations/coreos/dashboard/issues/
[pullrequests]: https://github.com/organizations/coreos/dashboard/pulls/

## Searching all repo code

Using `repo forall` you can search across all of the git repos at once:

```
repo forall -c  git grep 'CONFIG_EXTRA_FIRMWARE_DIR'
```

## Caching git https passwords

Note: You need git 1.7.10 or newer to use the credential helper

Turn on the credential helper and git will save your password in memory
for some time:

```
git config --global credential.helper cache
```

Why doesn't CoreOS use SSH in the git remotes? Because, we can't do
anonymous clones from github with a ssh URL. In the future we will fix
this.

### Base system dependency graph

Get a view into what the base system will contain and why it will contain those
things with the emerge tree view:

```
emerge-amd64-generic  --emptytree  -p -v --tree  coreos-base/coreos-dev
```

## SSH Config

You will be booting lots of VMs with on the fly ssh key generation. Add
this in your `$HOME/.ssh/config` to stop the annoying fingerprint warnings.

```
Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User core
  LogLevel QUIET
```

## Hide loop devices from desktop environments

By default desktop environments will diligently display any mounted devices
including loop devices used to contruct CoreOS disk images. If the daemon
responsible for this happens to be ``udisks`` then you can disable this
behavior with the following udev rule:

```
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
