---
layout: docs
title: Customizing the etcd Unit
category: distributed_configuration
sub_category: configuration
fork_url: https://github.com/coreos/docs/blob/master/distributed-configuration/customize-etcd-unit/index.md
weight: 5
---

# Customizing the etcd Unit

The etcd systemd unit can be customized by overriding the unit that ships with the default CoreOS settings. Common use-cases for doing this are covered below.

## Use Client Certificates

etcd supports client certificates as a way to provide secure communication between clients &#8596; leader and internal traffic between etcd peers in the cluster. Configuring certificates for both scenarios is done through environment variables. We can use a systemd drop-in unit to augment the unit that ships with CoreOS.

This site has a [good reference for how to generate self-signed key pairs](http://www.g-loaded.eu/2005/11/10/be-your-own-ca/) or you could use [etcd-ca](https://github.com/coreos/etcd-ca) to generate certs and keys. 

We need to create our drop-in unit in `/etc/systemd/system/etcd.service.d/`. If you run `systemctl status etcd2` you can see that CoreOS is already generating a few drop-in units for etcd as part of the OEM and cloudinit processes. To ensure that our drop-in runs after these, we name it `30-certificates.conf` and place them in `/etc/systemd/system/etcd2.service.d/`.

#### 30-certificates.conf

```ini
[Service]
# Client Env Vars
Environment=ETCD_CA_FILE=/path/to/CA.pem
Environment=ETCD_CERT_FILE=/path/to/server.crt
Environment=ETCD_KEY_FILE=/path/to/server.key
# Peer Env Vars
Environment=ETCD_PEER_CA_FILE=/path/to/CA.pem
Environment=ETCD_PEER_CERT_FILE=/path/to/peers.crt
Environment=ETCD_PEER_KEY_FILE=/path/to/peers.key
```

You'll have to put these files on disk somewhere. To do this on each of your machines, the easiest way is with cloud-config.

### Cloud-Config

Cloud-config has a parameter that will place the contents of a file on disk. We're going to use this to add our drop-in unit as well as the certificate files.

```yaml
#cloud-config

write_files:
  - path: /etc/systemd/system/etcd2.service.d/30-certificates.conf
    permissions: 0644
    content: |
      [Service]
      # Client Env Vars
      Environment=ETCD_CA_FILE=/path/to/CA.pem
      Environment=ETCD_CERT_FILE=/path/to/server.crt
      Environment=ETCD_KEY_FILE=/path/to/server.key
      # Peer Env Vars
      Environment=ETCD_PEER_CA_FILE=/path/to/CA.pem
      Environment=ETCD_PEER_CERT_FILE=/path/to/peers.crt
      Environment=ETCD_PEER_KEY_FILE=/path/to/peers.key
  - path: /path/to/CA.pem
    permissions: 0644
    content: |
      -----BEGIN CERTIFICATE-----
      MIIFNDCCAx6gAwIBAgIBATALBgkqhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
      ...snip...
      EtHaxYQRy72yZrte6Ypw57xPRB8sw1DIYjr821Lw05DrLuBYcbyclg==
      -----END CERTIFICATE-----
  - path: /path/to/server.crt
    permissions: 0644
    content: |
      -----BEGIN CERTIFICATE-----
      MIIFWTCCA0OgAwIBAgIBAjALBgkqhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
      DgYDVQQKEwdldGNkLWNhMQswCQYDVQQLEwJDQTAeFw0xNDA1MjEyMTQ0MjhaFw0y
      ...snip...
      rdmtCVLOyo2wz/UTzvo7UpuxRrnizBHpytE4u0KgifGp1OOKY+1Lx8XSH7jJIaZB
      a3m12FMs3AsSt7mzyZk+bH2WjZLrlUXyrvprI40=
      -----END CERTIFICATE-----
  - path: /path/to/server.key
    permissions: 0644
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      Proc-Type: 4,ENCRYPTED
      DEK-Info: DES-EDE3-CBC,069abc493cd8bda6

      TBX9mCqvzNMWZN6YQKR2cFxYISFreNk5Q938s5YClnCWz3B6KfwCZtjMlbdqAakj
      ...snip...
      mgVh2LBerGMbsdsTQ268sDvHKTdD9MDAunZlQIgO2zotARY02MLV/Q5erASYdCxk
      -----END RSA PRIVATE KEY-----
  - path: /path/to/peers.crt
    permissions: 0644
    content: |
      -----BEGIN CERTIFICATE-----
      VQQLEwJDQTAeFw0xNDA1MjEyMTQ0MjhaFw0yMIIFWTCCA0OgAwIBAgIBAjALBgkq
      DgYDVQQKEwdldGNkLWNhMQswCQYDhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
      ...snip...
      BHpytE4u0KgifGp1OOKY+1Lx8XSH7jJIaZBrdmtCVLOyo2wz/UTzvo7UpuxRrniz
      St7mza3m12FMs3AsyZk+bH2WjZLrlUXyrvprI90=
      -----END CERTIFICATE-----
  - path: /path/to/peers.key
    permissions: 0644
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      Proc-Type: 4,ENCRYPTED
      DEK-Info: DES-EDE3-CBC,069abc493cd8bda6

      SFreNk5Q938s5YTBX9mCqvzNMWZN6YQKR2cFxYIClnCWz3B6KfwCZtjMlbdqAakj
      ...snip...
      DvHKTdD9MDAunZlQIgO2zotmgVh2LBerGMbsdsTQ268sARY02MLV/Q5erASYdCxk
      -----END RSA PRIVATE KEY-----
```
