# Tuning CoreOS Container Linux power management

## CPU governor

By default, Container Linux uses the "performance" CPU governor meaning that the CPU operates at the maximum frequency regardless of load. This is reasonable for a system that is under constant load or cannot tolerate increased latency. On the other hand, if the system is idle much of the time and latency is not a concern, power savings may be desired.

Several governors are available:

| Governor       | Description                                                           |
|----------------|-----------------------------------------------------------------------|
| `performance`  | Default. Operate at the maximum frequency                             |
| `ondemand`     | Dynamically scale frequency at 75% cpu load                           |
| `conservative` | Dynamically scale frequency at 95% cpu load                           |
| `powersave`    | Operate at the minimum frequency                                      |
| `userspace`    | Controlled by a userspace application via the `scaling_setspeed` file |

The "conservative" governor can be used instead using the following shell commands:

```sh
modprobe cpufreq_conservative
echo "conservative" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
```

This can be configured with [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md/#coreos) as well:

```yaml
coreos:
  units:
    - name: cpu-governor.service
      command: start
      runtime: true
      content: |
        [Unit]
        Description=Enable CPU power saving

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/sbin/modprobe cpufreq_conservative
        ExecStart=/usr/bin/sh -c '/usr/bin/echo "conservative" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
```

More information on further tuning each governor is available in the [Kernel Documentation](https://www.kernel.org/doc/Documentation/cpu-freq/governors.txt)

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/power-management.md?pixel)]() <!-- END ANALYTICS -->