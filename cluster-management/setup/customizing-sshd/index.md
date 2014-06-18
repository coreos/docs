---
layout: docs
title: Adding Users
category: cluster_management
sub_category: setting_up
weight: 7
---

# Customizing the ssh daemon

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

## Further Reading

Read the [full cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide to install users and more.
