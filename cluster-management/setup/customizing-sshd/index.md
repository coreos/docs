---
layout: docs
title: Customizing the SSH Daemon
category: cluster_management
sub_category: setting_up
weight: 7
---

# Customizing the SSH Daemon

CoreOS defaults to running an OpenSSH daemon. In some cases you may want to customize this daemon's authentication methods or other configuration. This guide will show you how to customize using `cloud-config`.

## Customizing sshd with Cloud-Config

In this example we will disable logins for the `root` user, only allow login for the `core` user and disable password based authentication. For more details on what sections can be added to `/etc/ssh/sshd_config` see the [OpenSSH manual][openssh-manual].

[openssh-manual]: http://www.openssh.com/cgi-bin/man.cgi?query=sshd_config

```yaml
#cloud-config

write_files:
  - path: /etc/ssh/sshd_config
    permissions: 0600
    owner: root:root
    content: |
      # Use most defaults for sshd configuration.
      UsePrivilegeSeparation sandbox
      Subsystem sftp internal-sftp

      PermitRootLogin no
      AllowUsers core
      PasswordAuthentication no
      ChallengeResponseAuthentication no
```

## Changing the sshd Port

CoreOS ships with socket-activated SSH by default. The configuration for this can be found at `/usr/lib/systemd/system/sshd.socket`. We're going to override this in the cloud-config provided at boot:

```yaml
#cloud-config

coreos:
  units:
  - name: sshd.socket
    command: restart
    content: |
      [Socket]
      ListenStream=2222
      Accept=yes
```

## Further Reading

Read the [full cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide to install users and more.
