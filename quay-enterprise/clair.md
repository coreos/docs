# Clair Setup

<img src="img/Clair_horizontal_color.png" class="img-center" alt="Clair Security Scanner"/>

The <a href="https://github.com/coreos/clair">Clair</a> project is an open source engine that powers [Quay Security Scanner](security-scanning.md) to detect vulnerabilities in all images within Quay Enterprise, and notify developers as those issues are discovered.

## Initial Setup

### Postgres Database

In order to run Clair, a Postgres database is required. For production deployments, we recommend a PostgreSQL database running on machines other than those running Quay Enterprise, and ideally with automatic replication and failover.

#### Postgres database for testing

For testing purposes, a single PostgreSQL instance can be started locally:

```
docker run --name postgres -p 5432:5432 -d postgres
sleep 5
docker run --rm --link postgres:postgres postgres sh -c 'echo "create database clairtest" | psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'
```

The configuration string for this test database is `postgresql://postgres@{DOCKER HOST GOES HERE}:5432/clairtest?sslmode=disable`.

### Download the Clair image

Pull the security-enabled Clair image:

```
docker pull quay.io/coreos/clair-jwt:v1.2.4
```

### Make a configuration directory for Clair

```
mkdir clair-config
cd clair-config
```

## Configure Clair

Clair can run either as a single instance or in high-availability mode. It is recommended to run more than a single instance of Clair, ideally in an auto-scaling group with automatic healing.

Create a `config.yaml` file in the config directory with the following contents, replacing appearances of { VARIABLE } with the appropriate value.

### Clair configuration: High availability

```yaml
clair:
  database:
    # A PostgreSQL Connection string pointing to the Clair Postgres database.
    # Documentation on the format can be found at: http://www.postgresql.org/docs/9.4/static/libpq-connect.html
    source: { POSTGRES_CONNECTION_STRING }
    cachesize: 16384
  api:
    # The port at which Clair will report its health status. For example, if Clair is running at
    # https://clair.mycompany.com, the health will be reported at
    # http://clair.mycompany.com:6061/health.
    healthport: 6061

    port: 6062
    timeout: 900s

    # paginationkey can be any random set of characters. *Must be the same across all Clair instances*.
    paginationkey: "XxoPtCUzrUv4JV5dS+yQ+MdW7yLEJnRMwigVY/bpgtQ="

  updater:
    # interval defines how often Clair will check for updates from its upstream vulnerability databases.
    interval: 6h
    notifier:
      attempts: 3
      renotifyinterval: 1h
      http:
        # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
        # For example: https://myregistry.mycompany.com
        endpoint: { QUAY_ENDPOINT }/secscan/notify
        proxy: http://localhost:6063

jwtproxy:
  signer_proxy:
    enabled: true
    listen_addr: :6063
    ca_key_file: /certificates/mitm.key # Generated internally, do not change.
    ca_crt_file: /certificates/mitm.crt # Generated internally, do not change.
    signer:
      issuer: security_scanner
      expiration_time: 5m
      max_skew: 1m
      nonce_length: 32
      private_key:
        type: preshared
        options:
          # The ID of the service key generated for Clair. The ID is returned when setting up
          # the key in [Quay Enterprise Setup](security-scanning.md)
          key_id: { CLAIR_SERVICE_KEY_ID }
          private_key_path: /config/security_scanner.pem

  verifier_proxies:
  - enabled: true
    # The port at which Clair will listen.
    listen_addr: :6060

    # If Clair is to be served via TLS, uncomment these lines. See the "Running Clair under TLS"
    # section below for more information.
    # key_file: /config/clair.key
    # crt_file: /config/clair.crt

    verifier:
      # CLAIR_ENDPOINT is the endpoint at which this Clair will be accessible. Note that the port
      # specified here must match the listen_addr port a few lines above this.
      # Example: https://myclair.mycompany.com:6060
      audience: { CLAIR_ENDPOINT }

      upstream: http://localhost:6062
      key_server:
        type: keyregistry
        options:
          # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
          # Example: https://myregistry.mycompany.com
          registry: { QUAY_ENDPOINT }/keys/
```


### Clair configuration: Single instance

```yaml
clair:
  database:
    # A PostgreSQL Connection string pointing to the Clair Postgres database.
    # Documentation on the format can be found at: http://www.postgresql.org/docs/9.4/static/libpq-connect.html
    source: { POSTGRES_CONNECTION_STRING }
    cachesize: 16384
  api:
    # The port at which Clair will report its health status. For example, if Clair is running at
    # https://clair.mycompany.com, the health will be reported at
    # http://clair.mycompany.com:6061/health.
    healthport: 6061

    port: 6062
    timeout: 900s

    # paginationkey can be any random set of characters. *Must be the same across all Clair instances*.
    paginationkey: "XxoPtCUzrUv4JV5dS+yQ+MdW7yLEJnRMwigVY/bpgtQ="

  updater:
    # interval defines how often Clair will check for updates from its upstream vulnerability databases.
    interval: 6h
    notifier:
      attempts: 3
      renotifyinterval: 1h
      http:
        # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
        # For example: https://myregistry.mycompany.com
        endpoint: { QUAY_ENDPOINT }/secscan/notify
        proxy: http://localhost:6063

jwtproxy:
  signer_proxy:
    enabled: true
    listen_addr: :6063
    ca_key_file: /certificates/mitm.key # Generated internally, do not change.
    ca_crt_file: /certificates/mitm.crt # Generated internally, do not change.
    signer:
      issuer: security_scanner
      expiration_time: 5m
      max_skew: 1m
      nonce_length: 32
      private_key:
        type: autogenerated
        options:
          rotate_every: 12h
          key_folder: /config/
          key_server:
            type: keyregistry
            options:
              # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
              # For example: https://myregistry.mycompany.com
              registry: { QUAY_ENDPOINT }/keys/


  verifier_proxies:
  - enabled: true
    # The port at which Clair will listen.
    listen_addr: :6060

    # If Clair is to be served via TLS, uncomment these lines. See the "Running Clair under TLS"
    # section below for more information.
    # key_file: /config/clair.key
    # crt_file: /config/clair.crt

    verifier:
      # CLAIR_ENDPOINT is the endpoint at which this Clair will be accessible. Note that the port
      # specified here must match the listen_addr port a few lines above this.
      # Example: https://myclair.mycompany.com:6060
      audience: { CLAIR_ENDPOINT }

      upstream: http://localhost:6062
      key_server:
        type: keyregistry
        options:
          # QUAY_ENDPOINT defines the endpoint at which Quay Enterprise is running.
          # Example: https://myregistry.mycompany.com
          registry: { QUAY_ENDPOINT }/keys/
```


### Configuring Clair for TLS

To configure Clair to run under TLS, a few additional steps are required:

1. Generate a TLS certificate and key pair for the DNS name at which Clair will be accessed
2. Place these files as `clair.crt` and `clair.key` in your Clair configuration directory
3. Uncomment the `key_file` and `crt_file` lines under `verifier_proxies` in your Clair `config.yaml`


## Run Clair

Execute the following command to run Clair:

```
docker run --restart=always -p 6060:6060 -p 6061:6061 -v /path/to/clair/config/directory:/config quay.io/coreos/clair-jwt:v1.2.4
```

Output similar to the following will be seen on success:

```
2016-05-04 20:01:05,658 CRIT Supervisor running as root (no user in config file)
2016-05-04 20:01:05,662 INFO supervisord started with pid 1
2016-05-04 20:01:06,664 INFO spawned: 'jwtproxy' with pid 8
2016-05-04 20:01:06,666 INFO spawned: 'clair' with pid 9
2016-05-04 20:01:06,669 INFO spawned: 'generate_mitm_ca' with pid 10
time="2016-05-04T20:01:06Z" level=info msg="No claims verifiers specified, upstream should be configured to verify authorization"
time="2016-05-04T20:01:06Z" level=info msg="Starting reverse proxy (Listening on ':6060')"
2016-05-04 20:01:06.715037 I | pgsql: running database migrations
time="2016-05-04T20:01:06Z" level=error msg="Failed to create forward proxy: open /certificates/mitm.crt: no such file or directory"
goose: no migrations to run. current version: 20151222113213
2016-05-04 20:01:06.730291 I | pgsql: database migration ran successfully
2016-05-04 20:01:06.730657 I | notifier: notifier service is disabled
2016-05-04 20:01:06.731110 I | api: starting main API on port 6062.
2016-05-04 20:01:06.736558 I | api: starting health API on port 6061.
2016-05-04 20:01:06.736649 I | updater: updater service is disabled.
2016-05-04 20:01:06,740 INFO exited: jwtproxy (exit status 0; not expected)
2016-05-04 20:01:08,004 INFO spawned: 'jwtproxy' with pid 1278
2016-05-04 20:01:08,004 INFO success: clair entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2016-05-04 20:01:08,004 INFO success: generate_mitm_ca entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
time="2016-05-04T20:01:08Z" level=info msg="No claims verifiers specified, upstream should be configured to verify authorization"
time="2016-05-04T20:01:08Z" level=info msg="Starting reverse proxy (Listening on ':6060')"
time="2016-05-04T20:01:08Z" level=info msg="Starting forward proxy (Listening on ':6063')"
2016-05-04 20:01:08,541 INFO exited: generate_mitm_ca (exit status 0; expected)
2016-05-04 20:01:09,543 INFO success: jwtproxy entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
```

To verify Clair is running, execute the following command:

```
curl -X GET -I http://path/to/clair/here:6061/health
```

If a `200 OK` code is returned, Clair is running:

```
HTTP/1.1 200 OK
Server: clair
Date: Wed, 04 May 2016 20:02:16 GMT
Content-Length: 0
Content-Type: text/plain; charset=utf-8
```

## Continue with Quay Setup

Once Clair setup is complete, continue with [Quay Security Scanner Setup](security-scanning.md).
