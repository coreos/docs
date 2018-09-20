## Troubleshooting

Torcx generator runs early in the boot, when other system facilities are not yet set up and available for use. In case of errors, troubleshooting and debugging can be performed following the suggestions described here.

### Checking for failures

In case of errors, Torcx stops before sealing the new system state. This means that in order to check for correct execution, it is sufficient to verify that the metadata file exists:

```
$ test -f /run/metadata/torcx || echo 'torcx failed'
```

On failures, the metadata seal file will not exist, and `torcx failed` will be printed. Verify failure at boot time using the `torcx.target` unit:

```
$ sudo systemctl start torcx.target ; sudo systemctl status torcx.target

Assertion failed on job for torcx.target.

* torcx.target - Verify torcx succeeded
   Loaded: loaded (/usr/lib/systemd/system/torcx.target; disabled; vendor preset: disabled)
   Active: inactive (dead) since [...]
   Assert: start assertion failed at [...]
           AssertPathExists=/run/metadata/torcx was not met
```

### Gathering logs

The single most useful piece of information needed when troubleshooting failure is the log from `torcx-generator`. This binary does not run as a typical systemd service, thus log filtering must be done via its syslog identifier.
With systemd-journald, this can be accomplished with the following command:

```
$ journalctl --boot 0 --identifier /usr/lib64/systemd/system-generators/torcx-generator
```

If this doesn't yield results, run as root. There may be instances in which the journal isn't owned by the systemd-journal group, or the current user is not part of that group.

### Validating the configuration

One common cause for Torcx failure is a malformed configuration (such as a mis-assembled profile, or a syntax error). In other cases, the active profile might reference addon images which are no longer available on the system.
