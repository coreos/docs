# Torcx metadata and systemd target

In many cases, it is desirable to inspect the state of a system booted with Torcx and to verify the details of the configuration that has been applied.
For this purpose, Torcx comes with additional facilities to integrate with systemd-based workflows: a custom target and a metadata file containing environment flags.

## Metadata entries and environment flags

In order to signal a successful run, Torcx writes a metadata file at most once per boot. The format of this file is suitable for consumption by the systemd `EnvironmentFile=` [directive][systemd-exec] and can be used to introspect the booted configuration at runtime.

The metadata file is written to `/run/metadata/torcx` and contains a list of key-value pairs:

```
$ cat /run/metadata/torcx

TORCX_LOWER_PROFILES="vendor"
TORCX_UPPER_PROFILE="custom-demo"
TORCX_PROFILE_PATH="/run/torcx/profile.json"
TORCX_BINDIR="/run/torcx/bin"
TORCX_UNPACKDIR="/run/torcx/unpack"
```

These values can be used to detect where assets have been unpacked and propagated (shown above as "unpack" and "bin" entries), which profiles have been sourced (both vendor- and user-provided), and what is the resulting profile that has been applied.

Finally, the runtime profile can be inspected to detect which addons (and versions) are currently applied:

```
$ cat /run/torcx/profile.json

{
  "kind": "profile-manifest-v0",
  "value": {
    "images": []
  }
}
```

## Torcx target unit

System services may depend on successful execution of Torcx generator. As such, `torcx.target` is provided as a target unit which is only reachable if the generator successfully ran and sealed the system.

This target is not enabled by default, but can be referenced as a dependency by other units who want to introspect system status:

```
$ sudo systemctl cat torcx-echo.service

[Unit]
Description=Sample unit relying on torcx run
After=torcx.target
Requires=torcx.target

[Service]
EnvironmentFile=/run/metadata/torcx
Type=oneshot
ExecStart=/usr/bin/echo "torcx: applied ${TORCX_UPPER_PROFILE}"

[Install]
WantedBy=multi-user.target
```

```
$ sudo systemctl status torcx.target

● torcx.target - Verify torcx succeeded
   Loaded: loaded (/usr/lib/systemd/system/torcx.target; disabled; vendor preset: disabled)
   Active: active since [...]
```

```
$ sudo journalctl -u torcx-echo.service

localhost systemd[1]: Starting Sample unit relying on torcx run...
localhost echo[756]: torcx: applied custom-demo
localhost systemd[1]: Started Sample unit relying on torcx run.
```

[systemd-exec]: https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=
