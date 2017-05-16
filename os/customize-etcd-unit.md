# Customizing the etcd unit

The etcd systemd unit can be customized by overriding the unit that ships with the default Container Linux settings. Common use-cases for doing this are covered below.

## Use client certificates

etcd supports client certificates as a way to provide secure communication between clients &#8596; leader and internal traffic between etcd peers in the cluster. Configuring certificates for both scenarios is done through the etcd section in a Container Linux Config. Options provided here will augment the unit that ships with Container Linux.

Please follow the [instruction](generate-self-signed-certificates.md) to know how to create self-signed certificates and private keys.

```yaml container-linux-config
etcd:
  # More settings are needed here for a functioning etcd daemon
  ca_file:        /path/to/CA.pem
  cert_file:      /path/to/server.crt
  key_file:       /path/to/server.key
  peer_ca_file:   /path/to/CA.pem
  peer_cert_file: /path/to/peers.crt
  peer_key_file:  /path/to/peers.key
storage:
  files:
    - path: /path/to/CA.pem
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN CERTIFICATE-----
          MIIFNDCCAx6gAwIBAgIBATALBgkqhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
          ...snip...
          EtHaxYQRy72yZrte6Ypw57xPRB8sw1DIYjr821Lw05DrLuBYcbyclg==
          -----END CERTIFICATE-----
    - path: /path/to/server.crt
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN CERTIFICATE-----
          MIIFWTCCA0OgAwIBAgIBAjALBgkqhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
          DgYDVQQKEwdldGNkLWNhMQswCQYDVQQLEwJDQTAeFw0xNDA1MjEyMTQ0MjhaFw0y
          ...snip...
          rdmtCVLOyo2wz/UTzvo7UpuxRrnizBHpytE4u0KgifGp1OOKY+1Lx8XSH7jJIaZB
          a3m12FMs3AsSt7mzyZk+bH2WjZLrlUXyrvprI40=
          -----END CERTIFICATE-----
    - path: /path/to/server.key
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN RSA PRIVATE KEY-----
          Proc-Type: 4,ENCRYPTED
          DEK-Info: DES-EDE3-CBC,069abc493cd8bda6

          TBX9mCqvzNMWZN6YQKR2cFxYISFreNk5Q938s5YClnCWz3B6KfwCZtjMlbdqAakj
          ...snip...
          mgVh2LBerGMbsdsTQ268sDvHKTdD9MDAunZlQIgO2zotARY02MLV/Q5erASYdCxk
          -----END RSA PRIVATE KEY-----
    - path: /path/to/peers.crt
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN CERTIFICATE-----
          VQQLEwJDQTAeFw0xNDA1MjEyMTQ0MjhaFw0yMIIFWTCCA0OgAwIBAgIBAjALBgkq
          DgYDVQQKEwdldGNkLWNhMQswCQYDhkiG9w0BAQUwLTEMMAoGA1UEBhMDVVNBMRAw
          ...snip...
          BHpytE4u0KgifGp1OOKY+1Lx8XSH7jJIaZBrdmtCVLOyo2wz/UTzvo7UpuxRrniz
          St7mza3m12FMs3AsyZk+bH2WjZLrlUXyrvprI90=
          -----END CERTIFICATE-----
    - path: /path/to/peers.key
      filesystem: root
      mode: 0644
      contents:
        inline: |
          -----BEGIN RSA PRIVATE KEY-----
          Proc-Type: 4,ENCRYPTED
          DEK-Info: DES-EDE3-CBC,069abc493cd8bda6

          SFreNk5Q938s5YTBX9mCqvzNMWZN6YQKR2cFxYIClnCWz3B6KfwCZtjMlbdqAakj
          ...snip...
          DvHKTdD9MDAunZlQIgO2zotmgVh2LBerGMbsdsTQ268sARY02MLV/Q5erASYdCxk
          -----END RSA PRIVATE KEY-----
```
