# Generating signing keys for ACI conversion

This document explains how to add a pair of signing keys to your Quay Enterprise installation allowing Quay to sign container images after converting them to ACI format.

## Download the generation script and config

Download the files [aci-signing-key-batch](aci-signing-key-batch) and [generate-signing-keys.sh](generate-signing-keys.sh) next to your configuration directory.

Make `generate-signing-keys.sh` executable:

```sh
chmod +x generate-signing-keys.sh
```

## Edit the configuration

Edit the [aci-signing-key-batch](aci-signing-key-batch) configuration, replacing the email address, name, and comment with values appropriate for your site.

## Run the generation script

Run the generate script, giving the name of an output directory as the argument:

```sh
./generate-signing-keys.sh outputdir
```

The script will create a pair of files beneath the given directory named `signing-private.gpg` and `signing-public.gpg`.

```
Generating initial keys
gpg: Generating a default key
gpg: done
Generating public signing key
Determining private key
Exporting private signing key
Private key name: CBFB447F
Cleaning up
Emitted outputdir/signing-private.gpg and outputdir/signing-public.gpg
```

Take note of the private key's name (example from above: `CBFB447F`)

## Enter config in superuser panel

Visit the Quay superuser panel. Upload the pair of key files, and enter the generated private key name. Save the configuration and restart Quay Enterprise to enable signing of converted ACIs.
