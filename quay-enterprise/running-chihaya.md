# Chihaya Setup

The <a href="https://github.com/chihaya/chihaya">Chihaya</a> project is an open source BitTorrent tracker that supports JWT-based authorization. It is the preferred tracker for making use of the secure [BitTorrent-based distribution](bittorrent.md) feature in Quay Enterprise.

## Initial Setup

### Basic configuration

Copy the following file as `chihaya.yaml`, replacing `{QE LOCATION}` and `{TRACKER LOCATION}` with
the reachable endpoint for the Quay Enterprise instance and the tracker itself, respectively.

```
chihaya:
  announce_interval: 15m
  prometheus_addr: 0.0.0.0:6880

  http:
    addr: 0.0.0.0:6881
    allow_ip_spoofing: true
    real_ip_header: X-Forwarded-For
    read_timeout: 5s
    write_timeout: 5s
    request_timeout: 5s

  storage:
    gc_interval: 14m
    peer_lifetime: 15m
    shards: 16
    max_numwant: 50

  prehooks:
  - name: jwt
    config:
      issuer: '{QE LOCATION}'
      audience: '{TRACKER LOCATION}/announce'
      jwk_set_url: '{QE LOCATION}/keys/services/quay/keys'
      jwk_set_update_interval: 5m
```


## Running

Run the following commands to start Chihaya under a Docker container with the specified configuration mounted, making sure to point the `chihaya.yaml` to the file created above.

```sh
$ docker pull quay.io/jzelinskie/chihaya:v2.0.0-rc.1
$ docker run -p 6880-6882:6880-6882 -v $PWD/chihaya.yaml:/etc/chihaya.yaml:ro quay.io/jzelinskie/chihaya:v2.0.0-rc.1
```

## Security

It is recommended to place the tracker behind an SSL-terminating proxy or load balancer of some kind, especially if publicly facing. If setup this way, make sure to update the `jwtAudience` value in the configuration to have `https` as its prefix, and to refer to the load balancer.

## High Availability

High Availability of the tracker can be handled by running 2 or more instances of the tracker, with one setup as primary and another as secondary, configured with automatic failover. A simple HTTP check can be used to ensure the health of each instance.

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/quay-enterprise/running-chihaya.md?pixel)]() <!-- END ANALYTICS -->