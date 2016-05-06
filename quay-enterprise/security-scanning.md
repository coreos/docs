# Quay Security Scanner

Quay Enterprise supports scanning container images for known vulnerabilities with a scanning engine such as [Clair](clair.md). This document explains how to configure Clair with Quay Enterprise.

## Visit the management panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Quay Enterprise Management Panel"/>

## Enable Security Scanning

<img src="img/enable-security-scanning.png" class="img-center" alt="Enable Security Scanning"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled **Security Scanner**.
- Check the "Enable Security Scanning" box


## Enter a security scanner

In the "Security Scanner Endpoint" field, enter the HTTP endpoint of a Quay Enterprise-compatible security scanner such as [Clair](clair.md).

<img src="img/security-scanner-endpoint.png" class="img-center" alt="Security Scanner Endpoint"/>

## Generate an auth key

To connect Quay Enterprise securely to the scanner, click "Create Key >" to create an authentication key between Quay and the Security Scanner.

### Authentication for high-availability scanners

If the security scanning engine is running on multiple instances in a high-availability setup, select "Generate shared key":

<img src="img/security-scanner-generate-shared.png" class="img-center" alt="Security Scanner Generate Shared Key"/>

Enter an optional expiration date, and click "Generate Key":

<img src="img/security-scanner-generate-shared-dialog.png" class="img-center" alt="Security Scanner Generate Shared Key"/>

**Save the key ID and download the preshared private key into the configuration directory for the security scanning engine.**

<img src="img/security-scanner-shared-key.png" class="img-center" alt="Security Scanner Shared Key"/>

### Authentication for single-instance scanners

If the security scanning engine is being run on a single instance, select "Have the service provide a key":

<img src="img/security-scanner-service-provide-key.png" class="img-center" alt="Security Scanner Service Provide Key"/>

Once the following dialog is visible, run the security scanning engine:

<img src="img/security-scanner-service-awaiting-key.png" class="img-center" alt="Security Scanner Service Awaiting Key"/>

When the security scanning engine connects, the key will be automatically approved.

## Save configuration

- Click "Save Configuration Changes"
- Restart the container (you will be prompted)
