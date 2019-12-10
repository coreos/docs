# Disabling SMT on CoreOS Container Linux

Recent Intel CPU vulnerabilities ([L1TF] and [MDS]) cannot be fully mitigated in software without disabling Simultaneous Multi-Threading. This can have a substantial performance impact and is only necessary for certain workloads, so for compatibility reasons, SMT is enabled by default.

In addition, the Intel [TAA] vulnerability cannot be fully mitigated without disabling either of SMT or the Transactional Synchronization Extensions (TSX). Disabling TSX generally has less performance impact, so is the preferred approach on systems that don't otherwise need to disable SMT. For compatibility reasons, TSX is enabled by default.

SMT and TSX should be disabled on affected Intel processors under the following circumstances:
1. A bare-metal host runs untrusted virtual machines, and [other arrangements][l1tf-mitigation] have not been made for mitigation.
2. A bare-metal host runs untrusted code outside a virtual machine.

SMT can be conditionally disabled by passing `mitigations=auto,nosmt` on the kernel command line. This will disable SMT only if required for mitigating a vulnerability. This approach has two caveats:
1. It does not protect against unknown vulnerabilities in SMT.
2. It allows future Container Linux updates to disable SMT if needed to mitigate new vulnerabilities.

Alternatively, SMT can be unconditionally disabled by passing `nosmt` on the kernel command line. This provides the most protection and avoids possible behavior changes on upgrades, at the cost of a potentially unnecessary reduction in performance.

TSX can be conditionally disabled on vulnerable CPUs by passing `tsx=auto` on the kernel command line, or unconditionally disabled by passing `tsx=off`. However, neither setting takes effect on systems affected by MDS, since MDS mitigation automatically protects against TAA as well.

For typical use cases, we recommend enabling the `mitigations=auto,nosmt` and `tsx=auto` command-line options.

[L1TF]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/l1tf.html
[l1tf-mitigation]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/l1tf.html#mitigation-selection-guide
[MDS]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/mds.html
[TAA]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/tsx_async_abort.html

## Configuring new machines

The following Container Linux Config performs two tasks:

1. Adds `mitigations=auto,nosmt tsx=auto` to the kernel command line. This affects the second and subsequent boots of the machine, but not the first boot.
2. On the first boot, disables SMT at runtime if the system has an Intel processor. This is sufficient to protect against currently-known SMT vulnerabilities until the system is rebooted. After reboot, SMT will be re-enabled if the processor is not actually vulnerable.

```yaml container-linux-config
# Add kernel command-line arguments to automatically disable SMT or TSX
# on CPUs where they are vulnerable.  This will affect the second and
# subsequent boots of the machine, but not the first boot.
storage:
  filesystems:
    - name: OEM
      mount:
        device: /dev/disk/by-label/OEM
        format: ext4
  files:
    - filesystem: OEM
      path: /grub.cfg
      append: true
      mode: 0644
      contents:
        inline: |
          # Disable SMT on CPUs affected by MDS or similar vulnerabilities.
          # Disable TSX on CPUs affected by TAA but not by MDS.
          set linux_append="$linux_append mitigations=auto,nosmt tsx=auto"

# On the first boot only, disable SMT at runtime if it is enabled and
# the system has an Intel CPU.  L1TF, MDS, and TAA vulnerabilities are
# limited to Intel CPUs.
systemd:
  units:
    - name: disable-smt-firstboot.service
      enabled: true
      contents: |
        [Unit]
        Description=Disable SMT on first boot on Intel CPUs to mitigate MDS
        DefaultDependencies=no
        Before=sysinit.target shutdown.target
        Conflicts=shutdown.target
        ConditionFirstBoot=true

        [Service]
        Type=oneshot
        ExecStart=/bin/bash -c 'active="$(cat /sys/devices/system/cpu/smt/active)" && if [[ "$active" != 0 ]] && grep -q "vendor_id.*GenuineIntel" /proc/cpuinfo; then echo "Disabling SMT." && echo off > /sys/devices/system/cpu/smt/control; fi'

        [Install]
        WantedBy=sysinit.target
```

## Configuring existing machines

To add `mitigations=auto,nosmt tsx=auto` to the kernel command line on an existing system, add the following line to `/usr/share/oem/grub.cfg`:

```
set linux_append="$linux_append mitigations=auto,nosmt tsx=auto"
```

For example, using SSH:

```sh
ssh core@node01 'sudo sh -c "echo \"set linux_append=\\\"\\\$linux_append mitigations=auto,nosmt tsx=auto\\\"\" >> /usr/share/oem/grub.cfg && systemctl reboot"'
```

If you use locksmith for reboot coordination, replace `systemctl reboot` with `locksmithctl send-need-reboot`.
