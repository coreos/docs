# Using the client

`updateservicectl` lets you control and test the CoreOS update service. Subcommands let you manage applications, users, groups, packages and write a very simple client that gets its state via environment variables.

## Administrative flags

There are a few flags that you must provide to the administrative commands below.

- `--user` is your username, usually this is an email address or `admin`
- `--key` is your API key
- `--server` is the URL to your update service instance

The commands below will all have a prefix like this:

```
updateservicectl
	--user=admin \
	--key=d3b07384d113edec49eaa6238ad5ff00 \
	--server=https://example.update.core-os.net
```

If you do not wish to specify these every time, they
can also be exported as environment variables like this:

```
export UPDATECTL_USER=admin
export UPDATECTL_KEY=d3b07384d113edec49eaa6238ad5ff00
export UPDATECTL_SERVER=http://localhost:8000
```

## Update clients

There are two tools to test out the update service: `instance fake` and `watch`. `instance fake` simulates a number of clients from a single command. `watch` is used to quickly implement a simple update client with a minimal amount of code.

### Fake instances

This example will start 132 fake instances pinging the update service every 1 to 50 seconds against the CoreOS application's UUID and put them in the beta group starting at version 1.0.0.

```
updateservicectl instance fake \
	--clients-per-app=132 \
	--min-sleep=1 \
	--max-sleep=50 \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--group-id=beta \
	--version=1.0.0
```

### Update watcher

Real clients should implement the Omaha protocol but if you want a fast way to create your own client you can use `watch`. This will exec a program of your choosing every time a new update is available.

First, create a simple application that dumps the environment variables that the watcher will pass in. Call the script `updater.sh`.

```
#!/bin/sh
env | grep UPDATE_SERVICE
```

Next we will generate a random client UUID and start watching for changes to the given app:

```
updateservicectl watch \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--group-id=beta \
	./updater.sh
```

If you change the version of the beta group's channel then your script will be re-executed and you will see the UPDATE_SERVICE environment variables change.

## Application management

Applications have three pieces of data: a universal unique identifier (UUID), a label and a description. During a request to the update service, the UUID is submitted in order to retrieve the details of the currently available version.

### Add an application

Create an application called CoreOS using its UUID along with a nice description.

```
updateservicectl app create \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--label="CoreOS" \
	--description="Linux for Servers"
```

### List applications

```
updateservicectl app list
```

## Package management

Packages represent an individual version of an application and the URL associated with it.

### Add an application version

This will create a new package with version 1.0.5 from the file `update.gz`.

```
updateservicectl package create \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--version=1.0.5 \
	--file=update.gz \
	--url="http://my-s3-bucket-or-fileserver.com/my-app/0.0.1/update.gz"
```

The `--meta` option allows you to specify a cryptographic signature and file size for verification purposes. It should look like this:

```
{"metadata_size":"1024", "metadata_signature_rsa":"<insert hash here>"}
```

### List application versions

```
updateservicectl package list \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

## Channel management

A channel gives a nice symbolic name to packages. A group tracks a specific channel. Think of channels as a DNS name for a package.

### Update a channel

A channel has a version of individual applications. To change the version of an application specify the app id, channel and the version that channel should present. Additionally you can publish a channel by setting the `--publish` flag, if not specified publish will always be set to `false`.

```
updateservicectl channel update \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--channel=master \
	--version=1.0.1 \
	--publish=true
```

## Group management

Instances get their updates by giving the service a combination of their group and application id. Groups are usually some division of data centers, environments or customers.

### Creating a group

Create a group for the CoreOS application pointing at the master channel called testing. This group might be used in your test environment.

```
updateservicectl group create \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--channel=master \
	--group-id=testing \
	--label="Testing Group"
```

### Pausing updates on a group

```
updateservicectl group pause \
	--app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57 \
	--group-id=testing
```

### List groups

```
updateservicectl group list
Label           Token                                   UpdatesPaused
Default Group   default                                 false
```

## Instance management

The service keeps track of instances and gives you a number of tools to see their state. Most of these endpoints are more nicely consumed via the control panel but you can use them from `updateservicectl` too.

### List instances

This will list all instances that have been seen since the given timestamp.

```
updateservicectl instance list-updates \
	--start=1392401442
```

This will list the instances grouped by AppId and Version

```
updateservicectl instance list-app-versions \
	--start=1392401442
```

## User management

### Create a new user

```bash
updateservicectl admin-user create user@coreos.net
```

### List users

```bash
updateservicectl admin-user list
```

### Delete a user

```bash
updateservicectl admin-user delete user@coreos.net
```

## Upstream management

CoreUpdate supports synchronizing certain data with other "upstream" CoreUpdate instances.

By default hosted instances of CoreUpdate periodically synchronize with the public instance of CoreUpdate over the internet. This automatically updates your instance's CoreOS application packages and channel versions.

Since on-premises instances of CoreUpdate cannot access the internet [synchronization must be done manually](https://github.com/coreos/updateservicectl/blob/master/Documentation/sync-packages.md). If you decide to enable internet access for your on-premises instance, you can manage upstreams using these commands.

### List upstreams

```
updateservicectl upstream list
```

### Create upstream

```
updateservicectl upstream create \
	--label="Public CoreOS" \
	--url="https://public.update.core-os.net"
```

### Delete upstream

```
updateservicectl upstream delete \
	--id=2
```

### Sync upstream

Synchronizes data of all upstreams and blocks until complete.

```
updateservicectl upstream sync
```
