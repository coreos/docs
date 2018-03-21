 # Schema for Quay Enterprise #

 _Note: all fields are optional unless otherwise marked_

* **AUTHENTICATION_TYPE** [string] required: The authentication engine to use for credential authentication.
  * **enum**: Database, LDAP, JWT, Keystone, OIDC.
  * **Example**: `Database`
* **BUILDLOGS_REDIS** [object] required: Connection information for Redis for build logs caching.
  * **HOST** [string] required: The hostname at which Redis is accessible.
    * **Example**: `my.redis.cluster`
  * **PASSWORD** [string]: The password to connect to the Redis instance.
      * **Example**: `mypassword`
  * **PORT** [number]: The port at which Redis is accessible.
      * **Example**: `1234`
* **DB_URI** [string] required: The URI at which to access the database, including any credentials.
  * **Reference**: [https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495](https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495)
  * **Example**: `mysql+pymysql://username:password@dns.of.database/quay`
* **DEFAULT_TAG_EXPIRATION** [string] required: The default, configurable tag expiration time for time machine. Defaults to `2w`.
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
* **DISTRIBUTED_STORAGE_CONFIG** [object] required: Configuration for storage engine(s) to use in Quay. Each key is a unique ID for a storage engine, with the value being a tuple of the type and configuration for that engine.
  * **Example**: `{"local_storage": ["LocalStorage", {"storage_path": "some/path/"}]}`
* **DISTRIBUTED_STORAGE_PREFERENCE** [array] required: The preferred storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) to use. A preferred engine means it is first checked for pullig and images are pushed to it.  * **Min Items**: None * **Example**: `[u's3_us_east', u's3_us_west']` * **array item** [string] * **preferred_url_scheme** [string] required:  The URL scheme to use when hitting Quay. If Quay is behind SSL *at all*, this *must* be `https`.  * **enum**: `http, https` * **Example**: `https`
* **SERVER_HOSTNAME** [string] required: The URL at which Quay is accessible, without the scheme.
  * **Example**: `quay.io`
* **TAG_EXPIRATION_OPTIONS** [array] required: The options that users can select for expiration of tags in their namespace(if enabled).
  * **Min Items**: None
  * **array item** [string]
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
* **USER_EVENTS_REDIS** [object] required: Connection information for Redis for user event handling.
  * **HOST** [string] required: The hostname at which Redis is accessible
    * **Example**: `my.redis.cluster`
  * **PASSWORD** [string]: The password to connect to the Redis instance.
    * **Example**: `mypassword`
  * **PORT** [number]: The port at which Redis is accessible.
    * **Example**: `1234`
* **ACTION_LOG_ARCHIVE_LOCATION** [string]: If action log archiving is enabled, the storage engine in which to place the archived data.
  * **Example**: `s3_us_east`
* **ACTION_LOG_ARCHIVE_PATH' [string]: If action log archiving is enabled, the path in storage in which to place the archived data.
  * **Example**: `archives/actionlogs`
* **APP_SPECIFIC_TOKEN_EXPIRATION** [string, `null`]: The expiration for external app tokens. Defaults to None.
  * **Pattern**: `^[0-9]+(w|m|d|h|s)$`
* **ALLOW_PULLS_WITHOUT_STRICT_LOGGING** [boolean]: If true, pulls in which the pull audit log entry cannot be written will still succeed. Useful if the database can fallback into a read-only state and it is desired for pulls to continue during that time. Defaults to False.
  * **Example**: `True`
* **AVATAR_KIND** [string]: The types of avatars to display, either generated inline (local) or Gravatar (gravatar)
  * **enum**: local, gravatar
* **BITBUCKET_TRIGGER_CONFIG** ['object', 'null']: Configuration for using BitBucket for build triggers.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/bitbucket-build.html](https://coreos.com/quay-enterprise/docs/latest/bitbucket-build.html)
  * **consumer_key** [string] required: The registered consumer key(client ID) for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **CONSUMER_SECRET** [string] required: The registered consumer secret(client secret) for this Quay instance
    * **Example**: e4a58ddd3d7408b7aec109e85564a0d153d3e846
* **BITTORRENT_ANNOUNCE_URL** [string]: The URL of the announce endpoint on the bittorrent tracker.
  * **Pattern**: ``^http(s)?://(.)+$``
  * **Example**: `https://localhost:6881/announce`
* **BITTORRENT_PIECE_SIZE** [number]: The bittorent piece size to use. If not specified, defaults to 512 * 1024.
  * **Example**: `524288`
* **BROWSER_API_CALLS_XHR_ONLY** [boolean]:  If enabled, only API calls marked as being made by an XHR will be allowed from browsers. Defaults to True.
  * **Example: False
* **CONTACT_INFO** [array]: If specified, contact information to display on the contact page. If only a single piece of contact information is specified, the contact footer will link directly.
  * **Min Items**: 1
  * **Unique Items**: True
    * **array item 0** [string]: Adds a link to send an e-mail
      * **Pattern**: ``^mailto:(.)+$``
      * **Example**: `mailto:support@quay.io`
    * **array item 1** [string]: Adds a link to visit an IRC chat room
      * **Pattern**: ``^irc://(.)+$``
      * **Example**: `irc://chat.freenode.net:6665/quay`
    * **array item 2** [string]: Adds a link to call a phone number
      * **Pattern**: ``^tel:(.)+$``
      * **Example**: `tel:+1-888-930-3475`
    * **array item 3** [string]: Adds a link to a defined URL
      * **Pattern**: ``^http(s)?://(.)+$``
      * **Example**: `https://twitter.com/quayio`
* **BLACKLIST_V2_SPEC** [string]: The Docker CLI versions to which Quay will respond that V2 is *unsupported*. Defaults to `<1.6.0`.
  * **Reference**: [http://pythonhosted.org/semantic_version/reference.html#semantic_version.Spec](http://pythonhosted.org/semantic_version/reference.html#semantic_version.Spec)
  * **Example**: `<1.8.0`
* **DB_CONNECTION_ARGS** [object]: If specified, connection arguments for the database such as timeouts and SSL.
  * **threadlocals** [boolean] required: Whether to use thread-local connections. Should *ALWAYS* be `true`
  * **autorollback** [boolean] required: Whether to use auto-rollback connections. Should *ALWAYS* be `true`
  * **ssl** [object]: SSL connection configuration
    * **ca** [string] required: Absolute container path to the CA certificate to use for SSL connections.
+     * **Example**: `conf/stack/ssl-ca-cert.pem`
* **DEFAULT_NAMESPACE_MAXIMUM_BUILD_COUNT** [number, `null`]: If not None, the default maximum number of builds that can be queued in a namespace.
  * **Example: `20`
* **DIRECT_OAUTH_CLIENTID_WHITELIST** [array]: A list of client IDs of *Quay-managed* applications that are allowed to perform direct OAuth approval without user approval.
  * **Min Items**: None
  * **Unique Items**: True
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html](https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html)
    * **array item** [string]
* **DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS** [array]: The list of storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) whose images should be fully replicated, by default, to all other storage engines.
  * **Min Items**: None
  * **Example**: `s3_us_east, s3_us_west`
    * **array item** [string]
* **EXTERNAL_TLS_TERMINATION** [boolean]: If TLS is supported, but terminated at a layer before Quay, must be true.
  * **Example**: `True`
* **ENABLE_HEALTH_DEBUG_SECRET** [string, `null`]: If specified, a secret that can be given to health endpoints to see full debug info when not authenticated as a superuser.
  * **Example**: `somesecrethere`
* **EXPIRED_APP_SPECIFIC_TOKEN_GC** [string, `null`]: Duration of time expired external app tokens will remain before being garbage collected. Defaults to 1d.
  * **pattern**: `^[0-9]+(w|m|d|h|s)$`
* **FEATURE_ACI_CONVERSION** [boolean]: Whether to enable conversion to ACIs. Defaults to False.
  * **Example**: `False`
* **FEATURE_ACTION_LOG_ROTATION** [boolean]: Whether or not to rotate old action logs to storage. Defaults to False.
  * **Example**: `False`
* **FEATURE_ADVERTISE_V2** [boolean]: Whether the v2/ endpoint is visible. Defaults to True.
  * **Example**: `True`
* **FEATURE_ANONYMOUS_ACCESS** [boolean]: Whether to allow anonymous users to browse and pull public repositories.Defaults to True.
  * **Example**: `True`
* **FEATURE_APP_REGISTRY** [boolean]: Whether to enable support for App repositories. Defaults to False.
  * **Example**: `False`
* **FEATURE_APP_SPECIFIC_TOKENS** [boolean]:  +      'description': 'If enabled, users can create tokens for use by the Docker CLI. Defaults to True.
  * **Example**: False
* **FEATURE_BITBUCKET_BUILD** [boolean]: Whether to support Bitbucket build triggers. Defaults to False.
  * **Example**: `False`
* **FEATURE_BITTORRENT** [boolean]: Whether to allow using Bittorrent-based pulls. Defaults to False.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/bittorrent.html](https://coreos.com/quay-enterprise/docs/latest/bittorrent.html)
  * **Example**: `False`
* **FEATURE_BUILD_SUPPORT** [boolean]: Whether to support Dockerfile build. Defaults to True.
  * **Example**: `True`
* **FEATURE_CHANGE_TAG_EXPIRARTION** [boolean]: Whether users and organizations are allowed to change the tag expiration for tags in their namespace. Defaults to True.
  * **Example**: `False`
* **FEATURE_DIRECT_LOGIN** [boolean]: Whether users can directly login to the UI. Defaults to True.
  * **Example**: `True`
* **FEATURE_GITHUB_BUILD** [boolean]: Whether to support GitHub build triggers. Defaults to False.
  * **Example**: `False`
* **FEATURE_GITHUB_LOGIN** [boolean]: Whether GitHub login is supported. Defaults to False.
  * **Example**: `False`
* **FEATURE_GITLAB_BUILD**[boolean]: Whether to support GitLab build triggers. Defaults to False.
  * **Example**: `False`
* **FEATURE_GOOGLE_LOGIN** [boolean]: Whether Google login is supported. Defaults to False.
  * **Example**: `False`
* **FEATURE_INVITE_ONLY_USER_CREATION** [boolean]: Whether users being created must be invited by another user. Defaults to False.
  * **Example**: `False`
* **FEATURE_LIBRARY_SUPPORT** [boolean]: Whether to allow for "namespace-less" repositories when pulling and pushing from Docker. Defaults to True.
  * **Example**: `True`
* **FEATURE_MAILING** [boolean]: Whether emails are enabled. Defaults to True.
  * **Example**: `True`
* **FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP** [boolean]: If enabled, non-superusers can setup syncing on teams to backing LDAP or Keystone. Defaults To False.
  * **Example**: `True`
* **FEATURE_PARTIAL_USER_AUTOCOMPLETE** [boolean]: If set to true, autocompletion will apply to partial usernames. Defaults to True.
  * **Example**: `True`
* **FEATURE_PERMANENT_SESSIONS** [boolean]: Whether sessions are permanent. Defaults to True.
  * **Example**: `True`
* **FEATURE_PROXY_STORAGE** [boolean]: Whether to proxy all direct download URLs in storage via the registry nginx. Defaults to False.
  * **Example**: `False`
* **FEATURE_PUBLIC_CATALOG** [boolean]: If set to true, the `_catalog` endpoint returns public repositories. Otherwise, only private repositories can be returned. Defaults to False.
  * **Example**: `False`
* **FEATURE_READER_BUILD_LOGS** [boolean]: If set to true, build logs may be read by those with read access to the repo, rather than only write access or admin access. Defaults to False.
  * **Example**: False
* **FEATURE_RECAPTCHA** [boolean]: Whether Recaptcha is necessary for user login and recovery. Defaults to False.
  * **Example**: `False`
  * **Reference**: [https://www.google.com/recaptcha/intro/](https://www.google.com/recaptcha/intro/)
* **FEATURE_REQUIRE_ENCRYPTED_BASIC_AUTH** [boolean]: Whether non-encrypted passwords (as opposed to encrypted tokens) can be used for basic auth. Defaults to False.
  * **Example**: `False`
* **FEATURE_REQUIRE_TEAM_INVITE** [boolean]: Whether to require invitations when adding a user to a team. Defaults to True.
  * **Example**: `True`
* **FEATURE_SECURITY_NOTIFICATIONS** [boolean]: If the security scanner is enabled, whether to turn of/off security notificaitons. Defaults to False.
  * **Example**: `False`
* **FEATURE_SECURITY_SCANNER** [boolean]: Whether to turn of/off the security scanner. Defaults to False.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/security-scanning.html](https://coreos.com/quay-enterprise/docs/latest/security-scanning.html)
  * **Example**: `False`
* **FEATURE_STORAGE_REPLICATION** [boolean]: Whether to automatically replicate between storage engines. Defaults to False.
  * **Example**: `False`
* **FEATURE_SUPER_USERS** [boolean]: Whether super users are supported. Defaults to True.
  * **Example**: `True`
* **FEATURE_TEAM_SYNCING** [boolean]: Whether to allow for team membership to be synced from a backing group in the authentication engine (LDAP or Keystone).
  * **Example**: `True`
* **FEATURE_USER_CREATION** [boolean] :Whether users can be created (by non-super users). Defaults to True.
  * **Example**: `True`
* **FEATURE_USER_LOG_ACCESS** [boolean]: If set to true, users will have access to audit logs for their namespace. Defaults to False.
  * **Example**: `True`
* **FEATURE_USER_METADATA** [boolean]: Whether to collect and support user metadata. Defaults to False.
  * **Example**: `False`
* **FEATURE_USER_RENAME** [boolean]: If set to true, users can rename their own namespace. Defaults to False.
  * **Example**: `True`
* **GITHUB_LOGIN_CONFIG** [object, 'null']: Configuration for using GitHub (Enterprise) as an external login provider.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-auth.html](https://coreos.com/quay-enterprise/docs/latest/github-auth.html)
  * **allowed_organiztions** [array]: The names of the GitHub (Enterprise) organizations whitelisted to work with the ORG_RESTRICT option.
    * **Min Items**: None
    * **Unique Items**: True
      * **array item** [string]
  * **API_ENDPOINT** [string]: The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
    * **Example**: `https://api.github.com/`
  * **CLIENT_ID** [string] required: The registered client ID for this Quay instance; cannot be shared with GITHUB_TRIGGER_CONFIG.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `0e8dbe15c4c7630b6780`
  * **CLIENT_SECRET** [string] required: The registered client secret for this Quay instance.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
  * **GITHUB_ENDPOINT** [string] required: The endpoint of the GitHub (Enterprise) being hit.
    * **Example**: `https://github.com/`
  * **ORG_RESTRICT** [boolean]: If true, only users within the organization whitelist can login using this provider.
    * **Example**: `True`
* **GITHUB_TRIGGER_CONFIG** [object, `null`]: Configuration for using GitHub (Enterprise) for build triggers.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-build.html](https://coreos.com/quay-enterprise/docs/latest/github-build.html)
  * **API_ENDPOINT** [string]: The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
    * **Example**: `https://api.github.com/`
  * **CLIENT_ID** [string] required: The registered client ID for this Quay instance; cannot be shared with GITHUB_LOGIN_CONFIG.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `0e8dbe15c4c7630b6780`
  * **CLIENT_SECRET** [string] required: The registered client secret for this Quay instance.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
  * **GITHUB_ENDPOINT** [string] required: The endpoint of the GitHub (Enterprise) being hit.
    * **Example**: `https://github.com/`
* **GITLAB_TRIGGER_CONFIG** [object]: Configuration for using Gitlab (Enterprise) for external authentication.
  * **CLIENT_ID** [string] required: The registered client ID for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **CLIENT_SECRET** [string] required: The registered client secret for this Quay instance.
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
    * **gitlab_endpoint** [string] required: The endpoint at which Gitlab(Enterprise) is running.
      * **Example**: `https://gitlab.com`
* **GOOGLE_LOGIN_CONFIG** [object, `null`]: Configuration for using Google for external authentication
  * **CLIENT_ID** [string] required: The registered client ID for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **CLIENT_SECRET** [string] required: The registered client secret for this Quay instance.
    * **Example**: e4a58ddd3d7408b7aec109e85564a0d153d3e846
* **HEALTH_CHECKER** [string]: The configured health check.
  * **Example**: `('RDSAwareHealthCheck', {'access_key': 'foo', 'secret_key': 'bar'})`
* **LOG_ARCHIVE_LOCATION** [string]:If builds are enabled, the storage engine in which to place the archived build logs.
  * **Example**: `s3_us_east`
* **LOG_ARCHIVE_PATH** [string]: If builds are enabled, the path in storage in which to place the archived build logs.
  * **Example**: `archives/buildlogs`
* * **MAIL_DEFAULT_SENDER** [string, `null`]: If specified, the e-mail address used as the `from` when Quay sends e-mails. If none, defaults to `support@quay.io`.
  * **Example**: `support@myco.com`
* **MAIL_PASSWORD** [string, `null`]: The SMTP password to use when sending e-mails.
  * **Example**: `mypassword`
* **MAIL_PORT** [number]: The SMTP port to use. If not specified, defaults to 587.
  * **Example**: `588`
* **MAIL_SERVER** [string]: The SMTP server to use for sending e-mails. Only required if FEATURE_MAILING is set to true.
  * **Example**: `smtp.somedomain.com`
* **MAIL_USERNAME** [string, 'null']: The SMTP username to use when sending e-mails.
  * **Example**: `myuser`
* **MAIL_USE_TLS** [boolean]: If specified, whether to use TLS for sending e-mails.
  * **Example**: `True`
* **MAXIMUM_LAYER_SIZE** [string]: Maximum allowed size of an image layer. Defaults to 20G.
  * **Pattern**: ``^[0-9]+(G|M)$``
  * **Example**: `100G`
* **PUBLIC_NAMESPACES** [array]: If a namespace is defined in the public namespace list, then it will appear on *all* user's repository list pages, regardless of whether that user is a member of the namespace. Typically, this is used by an enterprise customer in configuring a set of "well-known" namespaces.
  * **Min Items**: None
  * **Unique Items**: True
    * **array item** [string]
* **PROMETHEUS_NAMESPACE** [string]: The prefix applied to all exposed Prometheus metrics. Defaults to `quay`.
  * **Example**: `myregistry`
* **RECAPTCHA_SITE_KEY** [string]: If recaptcha is enabled, the site key for the Recaptcha service.
* **RECAPTCHA_SECRET_KEY** [string]: 'If recaptcha is enabled, the secret key for the Recaptcha service.
* **REGISTRY_TITLE** [string]: If specified, the long-form title for the registry. Defaults to `Quay Enterprise`.
  * **Example**: `Corp Container Service`
* **REGISTRY_TITLE_SHORT** [string]: If specified, the short-form title for the registry. Defaults to `Quay Enterprise`.
  * **Example**: `CCS`
* **SECURITY_SCANNER_ENDPOINT** [string]: The endpoint for the security scanner.
  * **Pattern**: ``^http(s)?://(.)+$``
  * **Example**: `http://192.168.99.101:6060`
* **SECURITY_SCANNER_INDEXING_INTERVAL** [number]: The number of seconds between indexing intervals in the security scanner. Defaults to 30.
  * **Example**: `30`
* **SESSION_COOKIE_SECURE** [boolean]: Whether the `secure` property should be set on session cookies. Defaults to False. Recommended to be True for all installations using SSL.
  * **Example**: True
  * **Reference**: [https://en.wikipedia.org/wiki/Secure_cookies](https://en.wikipedia.org/wiki/Secure_cookies)
* **SUPER_USERS** [array]: Quay usernames of those users to be granted superuser privileges.
  * **Min Items**: None
  * **Unique Items**: True
    * **array item** [string]
* **TEAM_RESYNC_STALE_TIME** [string]: If team syncing is enabled for a team, how often to check its membership and resync if necessary(Default: 30m).
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
  * **Example**: `2h`
* **USERFILES_LOCATION** [string]: ID of the storage engine in which to place user-uploaded files.
  * **Example**: `s3_us_east`
* **USERFILES_PATH** [string]: Path under storage in which to place user-uploaded files.
  * **Example**: `userfiles`
* **USER_RECOVERY_TOKEN_LIFETIME** [string]: The length of time a token for recovering a user accounts is valid. Defaults to 30m.
  * **Example**: `10m`
  * **Pattern**: `^[0-9]+(w|m|d|h|s)$`
* **V2_PAGINATION_SIZE** [number]: The number of results returned per page in V2 registry APIs.
  * **Example**: `100`
