# Scheduling tasks with systemd timers

Container Linux uses systemd timers (`cron` replacement) to schedule tasks. Here we will show you how you can schedule a periodic job.

Let's create an alternative for this `crontab` job:

```
*/10 * * * * /usr/bin/date >> /tmp/date
```

Timers work directly with services' units. So we have to create `/etc/systemd/system/date.service` first:

```
[Unit]
Description=Prints date into /tmp/date file

[Service]
Type=oneshot
ExecStart=/usr/bin/sh -c '/usr/bin/date >> /tmp/date'
```

Then we have to create timer unit with the same name but with `*.timer` suffix `/etc/systemd/system/date.timer`:

```
[Unit]
Description=Run date.service every 10 minutes

[Timer]
OnCalendar=*:0/10
```



This config will run `date.service` every 10 minutes. You can also list all timers enabled in your system using `systemctl list-timers` command or `systemctl list-timers --all` to list all timers. Run `systemctl start date.timer` to enable timer.

You can also create timer with different name, i.e. `task.timer`. In this case you have specify service unit name:

```
Unit=date.service
```

## Container Linux Config

Here you'll find an example Container Linux Config demonstrating how to install systemd timers:

```yaml container-linux-config
systemd:
  units:
    - name: date.service
      contents: |
        [Unit]
        Description=Prints date into /tmp/date file

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/sh -c '/usr/bin/date >> /tmp/date'
    - name: date.timer
      enable: true
      contents: |
        [Unit]
        Description=Run date.service every 10 minutes

        [Timer]
        OnCalendar=*:0/10

        [Install]
        WantedBy=multi-user.target
```

## Further reading

If you're interested in more general systemd timers feature, check out the [full documentation](http://www.freedesktop.org/software/systemd/man/systemd.timer.html).
