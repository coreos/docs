# Chihaya Setup

The <a href="https://github.com/chihaya/chihaya">Chihaya</a> project is an open source BitTorrent tracker that supports JWT-based authorization. It is the preferred tracker for making use of the secure [BitTorrent-based distribution](bittorrent.md) feature in Quay Enterprise.

## Initial Setup

### Basic configuration

Copy the following file as `config.json`, replacing `{QE LOCATION}` and `{TRACKER LOCATION}` with
the reachable endpoint for the Quay Enterprise instance and the tracker itself, respectively.

```
{
  "createOnAnnounce": true,
  "purgeInactiveTorrents": true,
  "announce": "15m",
  "minAnnounce": "15m",
  "reapInterval": "60s",
  "reapRatio": 1.25,
  "defaultNumWant": 50,
  "torrentMapShards": 16,
  "allowIPSpoofing": true,
  "dualStackedPeers": true,
  "realIPHeader": "X-Forwarded-For",
  "respectAF": false,
  "clientWhitelistEnabled": false,
  "clientWhitelist": ["OP1011"],
  "apiListenAddr": "0.0.0.0:6880",
  "apiRequestTimeout": "4s",
  "apiReadTimeout": "4s",
  "apiWriteTimeout": "4s",
  "apiListenLimit": 0,
  "udpListenAddr": "0.0.0.0:6881",
  "httpListenAddr": "0.0.0.0:6881",
  "httpRequestTimeout": "4s",
  "httpReadTimeout": "4s",
  "httpWriteTimeout": "4s",
  "httpListenLimit": 0,
  "driver": "noop",
  "statsBufferSize": 0,
  "includeMemStats": true,
  "verboseMemStats": false,
  "memStatsInterval": "5s",
  "jwkSetURI": "https://{QE LOCATION}/keys/services/quay/keys",
  "jwkUpdateInterval": "60s",
  "jwtAudience": "http://{TRACKER LOCATION}/announce",
  "jwkTTL": "5m"
}
```


## Running

Run the following commands to start Chihaya under a Docker container with the specified configuration mounted, making sure to point the `config.json` to the file created above.

```sh
$ docker pull quay.io/jzelinskie/chihaya:v1.0.1
$ docker run -p 6880-6882:6880-6882 -v $PWD/config.json:/config.json:ro quay.io/jzelinskie/chihaya:v1.0.1 -v=5
```

## Security

It is recommended to place the tracker behind an SSL-terminating proxy or load balancer of some kind, especially if publicly facing. If setup this way, make sure to update the `jwtAudience` value in the configuration to have `https` as its prefix, and to refer to the load balancer.

## High Availability

High Availability of the tracker can be handled by running 2 or more instances of the tracker, with one setup as primary and another as secondary, configured with automatic failover. A simple HTTP check can be used to ensure the health of each instance.

