# Quay Enterprise OIDC Auth with Tectonic Identity 

This document explains how to configure Quay Enterprise to use Tectonic Identity as an OIDC provider for authorization and authentication.

## Export certificate information for TLS verification of Tectonic Identity 

```
kubectl -n tectonic-system get secret tectonic-ca-cert-secret -o json | jq -r '.data[]' | base64 -d >> tectonic-ca-ingress.crt
kubectl -n tectonic-system get secret tectonic-ingress-tls-secret -o json | jq -r '.data["tls.crt"]' | base64 -d >> tectonic-ca-ingress.crt
```

## Upload certificate to Quay Enterprise

Upload the `tectonic-ca-ingress.crt` certificate to to Quay Enterprise through the superuser panel, or follow [Adding TLS Certificates to the Quay Enterprise Container][add-certs] to upload manually.

## Configure Tectonic Identity

Edit the Tectonic Identity ConfigMap: 

```
kubectl -n tectonic-system edit cm tectonic-identity
```

Add a client definition under the `staticClients` section for Quay Enterprise: 

```
  - id: quay-enterprise
    name: Quay Enterprise
    secret: rEpLaCeThIs
    redirectURIs:
      - 'https://reg.example.com/oauth2/tectonicidentity/callback'
      - 'https://reg.example.com/oauth2/tectonicidentity/callback/attach'
      - 'https://reg.example.com/oauth2/tectonicidentity/callback/cli'
```

__secret:__ a user generated string that will later be passed to Quay Enterprise. Use `date | md5sum` or `openssl rand -base64 15` to generate a random string. 

__redirectURIs:__ callback URLs that must be passed to the Tectonic Identity ConfigMap. Replace reg.example.com with the Server Hostname of the registry. These values can be copied from the superuser panel if the OIDC provider is added to Quay Enterprise before this ConfigMap change is saved. 

Save the changes to the Tectonic Identity ConfigMap and issue a `kubectl patch` to update the deployment: 

```
kubectl --namespace tectonic-system patch deployment tectonic-identity \
    --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"date\":\"`date +'%s'`\"}}}}}"
```

## OIDC Provider for Tectonic Identity

Navigate to the superuser panel, then to External Authorization, click "Add OIDC Provider" and type `tectonicidentity` in the prompt.

__OIDC Server:__ FQDN of the Tectonic cluster with `/identity/` appended. Most easily found in the tectonic-identity configmap as the `issuer` parameter. Be certain to include the forward slash at the end of the domain name. Example: `https://tectonic.example.com/identity/`

__Client ID:__ `quay-enterprise`

__Client Secret:__ string passed as `secret` to tectonic-identity configmap.

__Service Name:__ will be displayed on the login page. Suggested value: `Tectonic Identity`

## Configure Access Settings

__Enable Open User Creation__ must be checked to allow for new users to be created. 

__Enable Invite-only User Creation__ used to restrict access based on email invitations to organization teams. This requires an SMTP server.

__Allow external application tokens__  if checked, users will be able to generate external application tokens for use with the docker and rkt CLIs. Consider the means of internal authentication before selecting this option. 

## Configure Internal Authentication

__Local Database__ can be used if traditional username/password authentication with the docker CLI is desired. This will require that OIDC users create a password from Account Settings after initial sign up.

__External Application Token__ requires enabling `Allow external application tokens` in Access Settings. This option will disable username/password in favor of a token generated from Account Settings. This option provides a single sign on experience, and minimizes password complication. If enabled, set an expiration date for the token.

## Save Configuration 

Click "Save Configuration Changes", then "Save Configuration", and finally "Restart Now" or restart the Quay Enterprise container with a `docker restart` or `kubectl delete pod <quay-enterprise-pod-name>`.

[add-certs]: insert-custom-cert.md


