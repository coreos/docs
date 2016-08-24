# Direct OAuth approval

Note: Documentation on the API endpoints themselves can be found on the [public API documentation for Quay](http://docs.quay.io/api/).

Quay Enterprise offers programmatic access via an [OAuth 2](http://oauth.net/2/) compatible API. Generation of an OAuth access token must normally be done via either an OAuth web approval flow, or via the Generate Token tab in the Application settings with Quay's UI. Occasionally, however, a tool or external application might want to directly generate an access token on behalf of a user.

## Enabling direct OAuth approval

Direct approval and generation of OAuth access tokens must be explicitly whitelisted by OAuth application client ID in the config. This is done as an additional security measure. The client ID for an OAuth application can be found under its information tab in the Quay UI.

To enable direct OAuth approval for a specific application, add its client ID to the `DIRECT_OAUTH_CLIENTID_WHITELIST` property in `config.yaml`:

```yaml
DIRECT_OAUTH_CLIENTID_WHITELIST: ['some-client-id']
```

## Using direct OAuth approval

To perform direct granting and approval of an OAuth token on behalf a user, an application or tool should issue an HTTP `POST` to the `/oauth/authorizeapp` endpoint, with the normal OAuth 2 approval flow parameters (client_id, redirect_uri, scope) as **form encoded values**.

In addition, the user's credentials must be specified via a Basic Auth header. If the credentials validate, then Quay will redirect to the `redirect_uri` with the generated and approved token for that user.

Example (username is `username` and password is `passwordhere`):

```
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmRoZXJl

POST https://myregistry/oauth/authorizeapp

client_id=some_client_id&redirect_uri=https://my/internal/application/token_created&scope=repo:push,org:admin
```

Response:
```
302 Found

Location: https://my/internal/application/token_created#access_token=some_access_token_here&token_type=Bearer&expires_in=315576000
```

