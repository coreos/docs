# Controlling Backwards Compatibility with Docker Registry v1 and v2 Protocols

Since Quay Enterprise v1.14.0, Docker Registry v2 is supported, along with Docker Registry v1. Quay Enterprise is fully backward and forward compatible with both protocols. Thus, you can push and pull your images securely with any version of Docker Engine (≥0.10).

However, if for some reason, you still want to use Registry v1 for all or some of your Docker clients, it is possible to configure Quay Enterprise to prevent specific Docker versions (or ranges).

It is also possible to configure Quay Enterprise to prevent specific versions (or a range) from using v2.

## Configuration

In order to configure Quay Enterprise to 'blacklist' some versions from using v2, you have to find and edit the configuration file (`config.yaml`), which was mounted into the container or added as a Kubernetes secret. Modify it to contain:

    BLACKLIST_V2_SPEC = "<RULES>"
  
Note that `<RULES>` has to be replaced by actual rules, see examples below.

## Rule examples

- `BLACKLIST_V2_SPEC = "<1.6.0"`
  - This is the default rule. It means that every version earlier than 1.6.0 are prevented from using v2.

-  `BLACKLIST_V2_SPEC = "<=1.7.0,=1.7.2"`
  - Versions equals or earlier than 1.7.0 and 1.7.2 can't use v2.

-  `BLACKLIST_V2_SPEC = "!=1.9.1"`
  - No version except 1.9.1 can use v2.

