# Adding TLS Certificates to the Quay Enterprise Container

To add custom TLS certificates to Quay Enterprise, create a new directory named `extra_ca_certs/` beneath the Quay Enterprise config directory. Copy any required site-specific TLS certificates to this new directory.

## Example

### View certificate to be added to the container:

```
$ cat storage.crt
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
[...]
-----END CERTIFICATE-----
```

### Create certs directory and copy certificate there:

```
$ mkdir -p quay/config/extra_ca_certs

$ cp storage.crt quay/config/extra_ca_certs/

$ tree quay/config/
├── config.yaml
├── extra_ca_certs
│   ├── storage.crt
```

### Restart QE container and check cert with docker-exec:

Obtain the quay container's `CONTAINER ID` with `docker ps`:

```
$ docker ps
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS
5a3e82c4a75f        quay.io/coreos/quay:v2.2.0           "/sbin/my_init"          24 hours ago        Up 18 hours         0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 8443/tcp   grave_keller
```

Restart the container with that ID:

```
$ docker restart 5a3e82c4a75f
```

Examine the certificate copied into the container namespace:

```
$ docker exec -it 5a3e82c4a75f cat /etc/ssl/certs/storage.pem
-----BEGIN CERTIFICATE-----
MIIDTTCCAjWgAwIBAgIJAMVr9ngjJhzbMA0GCSqGSIb3DQEBCwUAMD0xCzAJBgNV
```
