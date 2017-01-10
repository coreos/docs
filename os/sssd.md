# Configuring SSSD on CoreOS Container Linux

Container Linux ships with the System Security Services Daemon, allowing integration between Container Linux and enterprise authentication services.

## Configuring SSSD

Edit /etc/sssd/sssd.conf. This configuration file is fully documented [here](https://jhrozek.fedorapeople.org/sssd/1.13.1/man/sssd.conf.5.html). For example, to configure SSSD to use an IPA server called ipa.example.com, sssd.conf should read:

```
config_file_version = 2
services = nss, pam
domains = LDAP
[nss]
[pam]
[domain/LDAP]
id_provider = ldap
auth_provider = ldap
ldap_schema = ipa
ldap_uri = ldap://ipa.example.com
```

## Start SSSD

```sh
sudo systemctl start sssd
```

## Make SSSD available on future reboots

```sh
sudo systemctl enable sssd
```

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/sssd.md?pixel)]() <!-- END ANALYTICS -->