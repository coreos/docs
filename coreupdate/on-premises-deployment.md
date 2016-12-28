# On-premises deployment

An on-premises deployment of CoreUpdate is a self-administered instance that can be run behind a firewall.

## Accessing the CoreUpdate container

After signing up you will receive a `.dockercfg` file containing your credentials to the `quay.io/coreos/coreupdate` repository. Save this file to your Container Linux machine in `/home/core/.dockercfg` and `/root/.dockercfg`. You should now be able to execute `docker pull quay.io/coreos/coreupdate` to download the container.

## Database server

CoreUpdate requires an instance of a Postgres database server. You can use an existing instance if you have one, or use [the official Postgres docker image](https://registry.hub.docker.com/_/postgres/).

Postgres can be run on Container Linux with a systemd unit file similar to this one:

```ini
[Service]
User=core
ExecStartPre=-/usr/bin/docker kill postgres
ExecStartPre=-/usr/bin/docker rm postgres
ExecStart=/usr/bin/docker run --rm --name postgres \
    -v /opt/coreupdate/postgres/data:/var/lib/postgresql/data \
    --net="host" \
    postgres:9.4
ExecStop=/usr/bin/docker kill postgres

[Install]
WantedBy=multi-user.target
```

It is recommended to mount a volume from your host machine for data storage. The above example uses `/opt/coreupdate/postgres/data`.

Start the Postgres service by running:

```bash
sudo cp postgres.service /etc/systemd/system
sudo systemctl start postgres.service
```

View the logs and verify it is running:

```bash
sudo journalctl -u postgres.service -f
```

CoreUpdate needs a database and user for the connection, so you may need to initialize these on the Postgres server. You can do this manually, or execute similar commands using another instance of the Postgres container:

```bash
docker run --net="host" postgres:9.4 psql -h localhost -U postgres --command "CREATE USER coreos WITH SUPERUSER;"
docker run --net="host" postgres:9.4 psql -h localhost -U postgres --command "CREATE DATABASE coreupdate OWNER coreos;"
```

The username, password, and database name can be anything you choose as long as they match the `DB_URL` field in the config file.

## Web service

Once your database server is configured and running properly you can configure the web service.

### Configuration file

All CoreUpdate configuration options can be stored in a `.yaml` file. You will need to save this somewhere on your host machine such as `/etc/coreupdate/config.yaml`.

Below is a configuration file template. Customize the values as needed:

```yaml
# Published base URL of the web service.
# Required if using DNS, Load Balancer, or http->https redirections.
BASE_URL: http://localhost:8000

# (required) Unique secret session string.
# You can generate a UUID from the command line using the `uuidgen` command
SESSION_SECRET: "a-long-unique-string"

# Set this to 'false' if using Google authentication.
DISABLE_AUTH: true

# Enables Google OAuth, otherwise set DISABLE_AUTH to 'true'
# Configure at https://console.developers.google.com
#GOOGLE_OAUTH_CLIENT_ID:
#GOOGLE_OAUTH_CLIENT_SECRET:
# The redirect URL follows this format, substituting the BASE_URL: http://localhost:8000/admin/v1/oauth/login
#GOOGLE_OAUTH_REDIRECT_URL:

# Address and port to listen on.
LISTEN_ADDRESS: ":8000"

# Postgres database settings.
# Format: postgres://username:password@host:port/database-name
DB_URL: "postgres://coreos:coreos@localhost:5432/coreupdate?sslmode=disable"
DBTIMEOUT: 0
DBMAXIDLE: 0
DBMAXACTIVE: 100

# (Optional) sets a path to enable CoreUpdate's static package serving feature.
# Comment out to disable.
#STATIC_PACKAGES_DIR: /packages

# (Optional) enables uploading of package payloads to the server.
#ENABLE_PACKAGE_UPLOADS: true

# (Optional) Enable if syncing with upstream CoreUpdate instances.
# Zero value is disabled.
# This should be disabled if you plan to synchronize packages manually.
UPSTREAM_SYNC_INTERVAL: 0

# (Optional) enables TLS
#TLS_CERT_FILE:
#TLS_KEY_FILE:
```

#### Package payload hosting

By default the CoreUpdate database only stores meta-data about application packages. This enables you to host the package payloads using the file storage technology of your choice.

If you prefer you can store and serve package payloads from the same machine the CoreUpdate web service is running on. To do so ensure the following settings exist in your configuration file:

```bash
STATIC_PACKAGES_DIR: /packages
ENABLE-PACKAGE-UPLOADS: true
```

And add the volume flag to the `coreupdate@.service` file below:

```
-v /opt/packages:/packages
```

### Initializing the application

The CoreUpdate web service can be run with a systemd unit file such as:

```
[Unit]
Description=Core Update

[Service]
User=core
ExecStartPre=-/usr/bin/docker kill coreupdate-%i
ExecStartPre=-/usr/bin/docker rm coreupdate-%i
ExecStart=/usr/bin/docker run --rm --name coreupdate-%i \
    # mount the location of the config file
    -v /etc/coreupdate:/etc/coreupdate \
    # (optional) mount the location of the package payload directory
    #-v /opt/packages:/packages \
    --net="host" \
    # container to run
    # working directory to locate dashboard
    -w /opt/coreupdate \
    quay.io/coreos/coreupdate:latest \
    # binary inside the container to execute
    /opt/coreupdate/bin/coreupdate \
    # path to configuration file
    --yaml=/etc/coreupdate/config.yaml
ExecStop=/usr/bin/docker kill coreupdate-%i

[Install]
WantedBy=multi-user.target

[X-Fleet]
X-Conflicts=coreupdate@*
```

Start the service by running:

```bash
sudo cp coreupdate@.service /etc/systemd/system
sudo systemctl start coreupdate@.service
```

View the logs and verify it is running:

```bash
sudo journalctl -u coreupdate@.service -f
```

#### Create admin users

Now that the server is running the first user must be initialization. Do this using the `updateservicectl` tool.

This will generate an `admin` user and an api `key`, make note of the key for subsequent use of `updateservicectl`.

```bash
updateservicectl --server=http://localhost:8000 database init
```

Create the first control panel user:

```bash
updateservicectl --server=http://localhost:8000 --user=admin --key=<previously-generated-key> admin-user create google.apps.email@example.com
```

#### Create the "Container Linux" application

To sync the "Container Linux" application it must exist and have the same application id as the public CoreUpdate instance. NOTE: the application id must match exactly what is listed here:

```bash
updateservicectl --server=http://localhost:8000 --user=admin --key=<previously-generated-key> app create --label="Container Linux" --app-id=e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

You can now point your browser to `http://localhost:8000` to view the control panel.

### Air-gapped package management

On-Premises CoreUpdate instances can be managed in a completely air-gapped environment. Internet access is not required. Below are the steps you can take to update your packages in such an environment.

First you will need to decide if you want your CoreUpdate to host and serve the package files itself, or serve the files from a different fileserver.

#### Option 1: serving package files from CoreUpdate

CoreUpdate has the ability to serve package files without using a separate file server. Enable this functionality [via the config file](https://github.com/coreos/docs/blob/master/coreupdate/on-premises-deployment.md#configuration-file).

The two updateservicectl commands you would need are:

```
updateservicectl package download
```

This runs against the upstream instance (usually https://public.update.core-os.net). It downloads the actual binary packages to the computer from which you run the command.

```
updateservicectl package upload bulk
```

This runs against the downstream instance (your CoreUpdate server). It uploads the metadata and binary files to your CoreUpdate service.

#### Option 2: serving package files from a separate fileserver

```
updateservicectl package download
```

This runs against the upstream instance (usually https://public.update.core-os.net). It downloads all the actual binary to the computer from which you run the command. Once complete you should copy these files to the fileserver you intend to serve the packages from.

```
updateservicectl package create bulk
```

This runs against the downstream instance (your CoreUpdate server). It takes a directory of package binaries, extracts all the necessary metadata, and saves that information to your CoreUpdate service. Since the actual package binaries are served from another location you must provide a base path of that location (see `updateservicectl package create bulk --help` for more info).
