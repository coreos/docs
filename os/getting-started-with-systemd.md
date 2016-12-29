# Getting started with systemd

systemd is an init system that provides many powerful features for starting, stopping, and managing processes. Within Container Linux, you will almost exclusively use systemd to manage the lifecycle of your Docker containers.

## Terminology

systemd consists of two main concepts: a unit and a target. A unit is a configuration file that describes the properties of the process that you'd like to run. This is normally a `docker run` command or something similar. A target is a grouping mechanism that allows systemd to start up groups of processes at the same time. This happens at every boot as processes are started at different run levels.

systemd is the first process started on Container Linux and it reads different targets and starts the processes specified which allows the operating system to start. The target that you'll interact with is the `multi-user.target` which holds all of the general use unit files for our containers.

Each target is actually a collection of symlinks to our unit files. This is specified in the unit file by `WantedBy=multi-user.target`. Running `systemctl enable foo.service` creates symlinks to the unit inside `multi-user.target.wants`.

## Unit file

On Container Linux, unit files are located at `/etc/systemd/system`. Let's create a simple unit named `hello.service`:

```ini
[Unit]
Description=MyApp
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill busybox1
ExecStartPre=-/usr/bin/docker rm busybox1
ExecStartPre=/usr/bin/docker pull busybox
ExecStart=/usr/bin/docker run --name busybox1 busybox /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"

[Install]
WantedBy=multi-user.target
```

The `Description` shows up in the systemd log and a few other places. Write something that will help you understand exactly what this does later on.

`After=docker.service` and `Requires=docker.service` means this unit will only start after `docker.service` is active. You can define as many of these as you want.

`ExecStart=` allows you to specify any command that you'd like to run when this unit is started. The pid assigned to this process is what systemd will monitor to determine whether the process has crashed or not. Do not run docker containers with `-d` as this will prevent the container from starting as a child of this pid. systemd will think the process has exited and the unit will be stopped.

`WantedBy=` is the target that this unit is a part of.

To start a new unit, we need to tell systemd to create the symlink and then start the file:

```sh
$ sudo systemctl enable /etc/systemd/system/hello.service
$ sudo systemctl start hello.service
```

To verify the unit started, you can see the list of containers running with `docker ps` and read the unit's output with `journalctl`:

```sh
$ journalctl -f -u hello.service
-- Logs begin at Fri 2014-02-07 00:05:55 UTC. --
Feb 11 17:46:26 localhost docker[23470]: Hello World
Feb 11 17:46:27 localhost docker[23470]: Hello World
Feb 11 17:46:28 localhost docker[23470]: Hello World
...
```

<a class="btn btn-default" href="overview-of-systemctl.md">Overview of systemctl</a>
<a class="btn btn-default" href="reading-the-system-log.md">Reading the System Log</a>

## Advanced unit files

systemd provides a high degree of functionality in your unit files. Here's a curated list of useful features listed in the order they'll occur in the lifecycle of a unit:

| Name    | Description |
|---------|-------------|
| ExecStartPre | Commands that will run before `ExecStart`. |
| ExecStart | Main commands to run for this unit. |
| ExecStartPost | Commands that will run after all `ExecStart` commands have completed. |
| ExecReload | Commands that will run when this unit is reloaded via `systemctl reload foo.service` |
| ExecStop | Commands that will run when this unit is considered failed or if it is stopped via `systemctl stop foo.service` |
| ExecStopPost | Commands that will run after `ExecStop` has completed. |
| RestartSec | The amount of time to sleep before restarting a service. Useful to prevent your failed service from attempting to restart itself every 100ms. |

The full list is located on the [systemd man page](http://www.freedesktop.org/software/systemd/man/systemd.service.html).

Let's put a few of these concepts together to register new units within etcd. Imagine we had another container running that would read these values from etcd and act upon them.

We can use `ExecStartPre` to scrub existing container state. The `docker kill` will force any previous copy of this container to stop, which is useful if we restarted the unit but Docker didn't stop the container for some reason. The `=-` is systemd syntax to ignore errors for this command. We need to do this because Docker will return a non-zero exit code if we try to stop a container that doesn't exist. We don't consider this an error (because we want the container stopped) so we tell systemd to ignore the possible failure.

`docker rm` will remove the container and `docker pull` will pull down the latest version. You can optionally pull down a specific version as a Docker tag: `coreos/apache:1.2.3`

`ExecStart` is where the container is started from the container image that we pulled above.

Since our container will be started in `ExecStart`, it makes sense for our etcd command to run as `ExecStartPost` to ensure that our container is started and functioning.

When the service is told to stop, we need to stop the Docker container using its `--name` from the run command. We also need to clean up our etcd key when the container exits or the unit is failed by using `ExecStopPost`.

```ini
[Unit]
Description=My Advanced Service
After=etcd2.service
After=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill apache1
ExecStartPre=-/usr/bin/docker rm apache1
ExecStartPre=/usr/bin/docker pull coreos/apache
ExecStart=/usr/bin/docker run --name apache1 -p 8081:80 coreos/apache /usr/sbin/apache2ctl -D FOREGROUND
ExecStartPost=/usr/bin/etcdctl set /domains/example.com/10.10.10.123:8081 running
ExecStop=/usr/bin/docker stop apache1
ExecStopPost=/usr/bin/etcdctl rm /domains/example.com/10.10.10.123:8081

[Install]
WantedBy=multi-user.target
```

While it's possible to manage the starting, stopping, and removal of the container in a single `ExecStart` command by using `docker run --rm`, it's a good idea to separate the container's lifecycle into `ExecStartPre`, `ExecStart`, and `ExecStop` options as we've done above. This gives you a chance to inspect the container's state after it stops or fails.

## Unit specifiers

In our last example we had to hardcode our IP address when we announced our container in etcd. That's not scalable and systemd has a few variables built in to help us out. Here's a few of the most useful:

| Variable | Meaning | Description |
|----------|---------|-------------|
| `%n` | Full unit name | Useful if the name of your unit is unique enough to be used as an argument on a command. |
| `%m` | Machine ID | Useful for namespacing etcd keys by machine. Example: `/machines/%m/units` |
| `%b` | BootID | Similar to the machine ID, but this value is random and changes on each boot |
| `%H` | Hostname | Allows you to run the same unit file across many machines. Useful for service discovery. Example: `/domains/example.com/%H:8081` |

A full list of specifiers can be found on the [systemd man page](http://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers).

## Instantiated units

Since systemd is based on symlinks, there are a few interesting tricks you can leverage that are very powerful when used with containers. If you create multiple symlinks to the same unit file, the following variables become available to you:

| Variable | Meaning | Description |
|----------|---------|-------------|
| `%p` | Prefix name | Refers to any string before `@` in your unit name. |
| `%i` | Instance name | Refers to the string between the `@` and the suffix. |

In our earlier example we had to hardcode our IP address when registering within etcd:

```ini
ExecStartPost=/usr/bin/etcdctl set /domains/example.com/10.10.10.123:8081 running
```

We can enhance this by using `%H` and `%i` to dynamically announce the hostname and port. Specify the port after the `@` by using two unit files named `foo@123.service` and `foo@456.service`:

```ini
ExecStartPost=/usr/bin/etcdctl set /domains/example.com/%H:%i running
```

This gives us the flexibility to use a single unit file to announce multiple copies of the same container on a single machine (no port overlap) and on multiple machines (no hostname overlap).

## More information

<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.target.html">systemd.target Docs</a>
