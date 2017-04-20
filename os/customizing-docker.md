# Customizing docker

The Docker systemd unit can be customized by overriding the unit that ships with the default Container Linux settings. Common use-cases for doing this are covered below.

## Enable the remote API on a new socket

Create a file called `/etc/systemd/system/docker-tcp.socket` to make Docker available on a TCP socket on port 2375.

```ini
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=2375
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
```

Then enable this new socket:

```sh
systemctl enable docker-tcp.socket
systemctl stop docker
systemctl start docker-tcp.socket
systemctl start docker
```

Test that it's working:

```sh
docker -H tcp://127.0.0.1:2375 ps
```

### Container Linux Config

To enable the remote API on every Container Linux machine in a cluster, use a [Container Linux Config][cl-configs]. We need to provide the new socket file and Docker's socket activation support will automatically start using the socket:

```container-linux-config
systemd:
  units:
    - name: docker-tcp.socket
      enable: true
      contents: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
```

To keep access to the port local, replace the `ListenStream` configuration above with:

```yaml
        [Socket]
        ListenStream=127.0.0.1:2375
```

## Enable the remote API with TLS authentication

Docker TLS configuration consists of three parts: keys creation, configuring new [systemd socket][systemd-socket] unit and systemd [drop-in][drop-in] configuration.

### TLS keys creation

Please follow the [instruction][self-signed-certs] to know how to create self-signed certificates and private keys. Then copy with following files into `/etc/docker` Container Linux's directory and fix their permissions:

```sh
scp ~/cfssl/{server.pem,server-key.pem,ca.pem} coreos.example.com:
ssh core@coreos.example.com
sudo mv {server.pem,server-key.pem,ca.pem} /etc/docker/
sudo chown root:root /etc/docker/{server-key.pem,server.pem,ca.pem}
sudo chmod 0600 /etc/docker/server-key.pem
```

On your local host copy certificates into `~/.docker`:

```sh
mkdir ~/.docker
chmod 700 ~/.docker
cd ~/.docker
cp -p ~/cfssl/ca.pem ca.pem
cp -p ~/cfssl/client.pem cert.pem
cp -p ~/cfssl/client-key.pem key.pem
```

### Enable the secure remote API on a new socket

Create a file called `/etc/systemd/system/docker-tls-tcp.socket` to make Docker available on a secured TCP socket on port 2376.

```ini
[Unit]
Description=Docker Secured Socket for the API

[Socket]
ListenStream=2376
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
```

Then enable this new socket:

```sh
systemctl enable docker-tls-tcp.socket
systemctl stop docker
systemctl start docker-tls-tcp.socket
```

### Drop-in configuration

Create `/etc/systemd/system/docker.service.d/10-tls-verify.conf` [drop-in][drop-in] for systemd Docker service:

```ini
[Service]
Environment="DOCKER_OPTS=--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/server.pem --tlskey=/etc/docker/server-key.pem"
```

Reload systemd config files and restart docker service:

```sh
sudo systemctl daemon-reload
sudo systemctl restart docker.service
```

Now you can access your Docker's API through TLS secured connection:

```sh
docker --tlsverify -H tcp://server:2376 images
# or
docker --tlsverify -H tcp://server.example.com:2376 images
```

If you've experienceed problems connection to remote Docker API using TLS connection, you can debug it with `curl`:

```sh
curl -v --cacert ~/.docker/ca.pem --cert ~/.docker/cert.pem --key ~/.docker/key.pem https://server:2376
```

Or on your Container Linux host:

```sh
journalctl -f -u docker.service
```

In addition you can export environment variables and use docker client without additional options:

```sh
export DOCKER_HOST=tcp://server.example.com:2376 DOCKER_TLS_VERIFY=1
docker images
```

### Container Linux Config

A Container Linux Config for Docker TLS authentication will look like:

```container-linux-config
storage:
  files:
    - path: /etc/docker/ca.pem
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN CERTIFICATE-----
          MIIFNDCCAx6gAwIBAgIBATALBgkqhkiG9w0BAQswLTEMMAoGA1UEBhMDVVNBMRAw
          DgYDVQQKEwdldGNkLWNhMQswCQYDVQQLEwJDQTAeFw0xNTA5MDIxMDExMDhaFw0y
          NTA5MDIxMDExMThaMC0xDDAKBgNVBAYTA1VTQTEQMA4GA1UEChMHZXRjZC1jYTEL
          ... ... ...
    - path: /etc/docker/server.pem
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN CERTIFICATE-----
          MIIFajCCA1SgAwIBAgIBBTALBgkqhkiG9w0BAQswLTEMMAoGA1UEBhMDVVNBMRAw
          DgYDVQQKEwdldGNkLWNhMQswCQYDVQQLEwJDQTAeFw0xNTA5MDIxMDM3MDFaFw0y
          NTA5MDIxMDM3MDNaMEQxDDAKBgNVBAYTA1VTQTEQMA4GA1UEChMHZXRjZC1jYTEQ
          ... ... ...
    - path: /etc/docker/server-key.pem
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN RSA PRIVATE KEY-----
          MIIJKAIBAAKCAgEA23Q4yELhNEywScrHl6+MUtbonCu59LIjpxDMAGxAHvWhWpEY
          P5vfas8KgxxNyR+U8VpIjEXvwnhwCx/CSCJc3/VtU9v011Ir0WtTrNDocb90fIr3
          YeRWq744UJpBeDHPV9opf8xFE7F74zWeTVMwtiMPKcQDzZ7XoNyJMxg1wmiMbdCj
          ... ... ...
systemd:
  units:
    - name: docker-tls-tcp.socket
      enable: true
      contents: |
        [Unit]
        Description=Docker Secured Socket for the API

        [Socket]
        ListenStream=2376
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
docker:
  flags:
    - --tlsverify
    - --tlscacert=/etc/docker/ca.pem
    - --tlscert=/etc/docker/server.pem
    - --tlskey=/etc/docker/server-key.pem
```

## Use attached storage for Docker images

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantageous to use attached storage to expand your capacity for container images. Check out the guide to [mounting storage to your Container Linux machine][mounting-storage] for an example of how to bind mount storage into `/var/lib/docker`.

## Enabling the Docker debug flag

Set the `--debug` (`-D`) flag in the `DOCKER_OPTS` environment variable by using a drop-in file. For example, the following could be written to `/etc/systemd/system/docker.service.d/10-debug.conf`:

```ini
[Service]
Environment=DOCKER_OPTS=--debug
```

Now tell systemd about the new configuration and restart Docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

To test our debugging stream, run a Docker command and then read the systemd journal, which should contain the output:

```sh
docker ps
journalctl -u docker
```

### Container Linux Config

If you need to modify a flag across many machines, you can add the flag with a Container Linux Config:

```container-linux-config
docker:
  flags:
    - --debug
```

## Use an HTTP proxy

If you're operating in a locked down networking environment, you can specify an HTTP proxy for Docker to use via an environment variable. First, create a directory for drop-in configuration for Docker:

```sh
mkdir /etc/systemd/system/docker.service.d
```

Now, create a file called `/etc/systemd/system/docker.service.d/http-proxy.conf` that adds the environment variable:

```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
```

To apply the change, reload the unit and restart Docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

Proxy environment variables can also be set [system-wide][systemd-env-vars].

### Container Linux Config

The easiest way to use this proxy on all of your machines is via a Container Linux Config:

```container-linux-config
systemd:
  units:
    - name: docker.service
      enable: true
      dropins:
        - name: 20-http-proxy.conf
          contents: |
            [Service]
            Environment="HTTP_PROXY=http://proxy.example.com:8080"
```

## Increase ulimits

If you need to increase certain ulimits that are too low for your application by default, like memlock, you will need to modify the Docker service to increase the limit. First, create a directory for drop-in configuration for Docker:

```sh
mkdir /etc/systemd/system/docker.service.d
```

Now, create a file called `/etc/systemd/system/docker.service.d/increase-ulimit.conf` that adds increased limit:

```ini
[Service]
LimitMEMLOCK=infinity
```

To apply the change, reload the unit and restart Docker:

```sh
systemctl daemon-reload
systemctl restart docker
```

### Container Linux Config

The easiest way to use these new ulimits on all of your machines is via a Container Linux Config:

```container-linux-configs
systemd:
  units:
    - name: docker.service
      enable: true
      dropins:
        - name: 30-increase-ulimit.conf
          contents: |
            [Service]
            LimitMEMLOCK=infinity
```


## Using a dockercfg file for authentication

A json file `.dockercfg` can be created in your home directory that holds authentication information for a public or private Docker registry.

[docker-socket-systemd]: https://github.com/docker/docker/pull/17211
[drop-in]: using-systemd-drop-in-units.md
[mounting-storage]: mounting-storage.md
[self-signed-certs]: generate-self-signed-certificates.md
[systemd-socket]: https://www.freedesktop.org/software/systemd/man/systemd.socket.html
[systemd-env-vars]: https://coreos.com/os/docs/latest/using-environment-variables-in-systemd-units.html#system-wide-environment-variables
[cl-configs]: provisioning.md
