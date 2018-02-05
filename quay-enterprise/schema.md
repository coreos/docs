 # Schema for Quay Enterprise #

 _Note: all fields are optional unless otherwise marked_

* **authentication_type** [string] required: The authentication engine to use for credential authentication.
  * **enum**: Database, LDAP, JWT, Keystone, OIDC.
  * **Example**: `Database`
* **buildlogs_redis** [object] required: Connection information for Redis for build logs caching.
  * **host** [string] required: The hostname at which Redis is accessible.
    * **Example**: `my.redis.cluster`
  * **password** [string]: The password to connect to the Redis instance.
      * **Example**: `mypassword`
  * **port** [number]: The port at which Redis is accessible.
      * **Example**: `1234`
* **db_uri** [string] required: The URI at which to access the database, including any credentials.
  * **Reference**: [https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495](https://www.postgresql.org/docs/9.3/static/libpq-connect.html#AEN39495)
  * **Example**: `mysql+pymysql://username:password@dns.of.database/quay`
* **default_tag_expiration** [string] required: The default, configurable tag expiration time for time machine. Defaults to `2w`.
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
* **distributed_storage_config** [object] required: Configuration for storage engine(s) to use in Quay. Each key is a unique ID for a storage engine, with the value being a tuple of the type and configuration for that engine.
  * **Example**: `{"local_storage": ["LocalStorage", {"storage_path": "some/path/"}]}`
* **distributed_storage_preference** [array] required: The preferred storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) to use. A preferred engine means it is first checked for pullig and images are pushed to it.
  * **Min Items**: None
  * **Example**: `[u's3_us_east', u's3_us_west']`
    * **array item** [string]
* **preferred_url_scheme** [string] required:  The URL scheme to use when hitting Quay. If Quay is behind SSL *at all*, this *must* be `https`.
  * **enum**: `http, https`
  * **Example**: `https`
* **server_hostname** [string] required: The URL at which Quay is accessible, without the scheme.
  * **Example**: `quay.io`
* **tag_expiration_options** [array] required: The options that users can select for expiration of tags in their namespace(if enabled).
  * **Min Items**: None
  * **array item** [string]
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
* **user_events_redis** [object] required: Connection information for Redis for user event handling.
  * **host** [string] required: The hostname at which Redis is accessible
    * **Example**: `my.redis.cluster`
  * **password** [string]: The password to connect to the Redis instance.
    * **Example**: `mypassword`
  * **port** [number]: The port at which Redis is accessible.
    * **Example**: `1234`
* **action_log_archive_location** [string]: If action log archiving is enabled, the storage engine in which to place the archived data.
  * **Example**: `s3_us_east`
* **action_log_archive_path' [string]: If action log archiving is enabled, the path in storage in which to place the archived data.
  * **Example**: `archives/actionlogs`
* **app_specific_token_expiration** [string, `null`]: The expiration for external app tokens. Defaults to None.
  * **Pattern**: `^[0-9]+(w|m|d|h|s)$`
* **allow_pulls_without_strict_logging** [boolean]: If true, pulls in which the pull audit log entry cannot be written will still succeed. Useful if the database can fallback into a read-only state and it is desired for pulls to continue during that time. Defaults to False.
  * **Example**: `True`
* **avatar_kind** [string]: The types of avatars to display, either generated inline (local) or Gravatar (gravatar)
  * **enum**: local, gravatar
* **bitbucket_trigger_config** ['object', 'null']: Configuration for using BitBucket for build triggers.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/bitbucket-build.html](https://coreos.com/quay-enterprise/docs/latest/bitbucket-build.html)
  * **consumer_key** [string] required: The registered consumer key(client ID) for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **consumer_secret** [string] required: The registered consumer secret(client secret) for this Quay instance
    * **Example**: e4a58ddd3d7408b7aec109e85564a0d153d3e846
* **bittorrent_announce_url** [string]: The URL of the announce endpoint on the bittorrent tracker.
  * **Pattern**: ``^http(s)?://(.)+$``
  * **Example**: `https://localhost:6881/announce`
* **bittorrent_piece_size** [number]: The bittorent piece size to use. If not specified, defaults to 512 * 1024.
  * **Example**: `524288`
* **browser_api_calls_xhr_only** [boolean]:  If enabled, only API calls marked as being made by an XHR will be allowed from browsers. Defaults to True.
  * **Example: False
* **contact_info** [array]: If specified, contact information to display on the contact page. If only a single piece of contact information is specified, the contact footer will link directly.
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
* **blacklist_v2_spec** [string]: The Docker CLI versions to which Quay will respond that V2 is *unsupported*. Defaults to `<1.6.0`.
  * **Reference**: [http://pythonhosted.org/semantic_version/reference.html#semantic_version.Spec](http://pythonhosted.org/semantic_version/reference.html#semantic_version.Spec)
  * **Example**: `<1.8.0`
* **db_connection_args** [object]: If specified, connection arguments for the database such as timeouts and SSL.
  * **threadlocals** [boolean] required: Whether to use thread-local connections. Should *ALWAYS* be `true`
  * **autorollback** [boolean] required: Whether to use auto-rollback connections. Should *ALWAYS* be `true`
  * **ssl** [object]: SSL connection configuration
    * **ca** [string] required: Absolute container path to the CA certificate to use for SSL connections.
+     * **Example**: `conf/stack/ssl-ca-cert.pem`
* **default_namespace_maximum_build_count** [number, `null`]: If not None, the default maximum number of builds that can be queued in a namespace.
  * **Example: `20`
* **direct_oauth_clientid_whitelist** [array]: A list of client IDs of *Quay-managed* applications that are allowed to perform direct OAuth approval without user approval.
  * **Min Items**: None
  * **Unique Items**: True
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html](https://coreos.com/quay-enterprise/docs/latest/direct-oauth.html)
    * **array item** [string]
* **distributed_storage_default_locations** [array]: The list of storage engine(s) (by ID in DISTRIBUTED_STORAGE_CONFIG) whose images should be fully replicated, by default, to all other storage engines.
  * **Min Items**: None
  * **Example**: `s3_us_east, s3_us_west`
    * **array item** [string]
* **external_tls_termination** [boolean]: If TLS is supported, but terminated at a layer before Quay, must be true.
  * **Example**: `True`
* **enable_health_debug_secret** [string, `null`]: If specified, a secret that can be given to health endpoints to see full debug info when not authenticated as a superuser.
  * **Example**: `somesecrethere`
* **expired_app_specific_token_gc** [string, `null`]: Duration of time expired external app tokens will remain before being garbage collected. Defaults to 1d.
* **pattern**: `^[0-9]+(w|m|d|h|s)$`
* **feature_aci_conversion** [boolean]: Whether to enable conversion to ACIs. Defaults to False.
  * **Example**: `False`
* **feature_action_log_rotation** [boolean]: Whether or not to rotate old action logs to storage. Defaults to False.
  * **Example**: `False`
* **feature_advertise_v2** [boolean]: Whether the v2/ endpoint is visible. Defaults to True.
  * **Example**: `True`
* **feature_anonymous_access** [boolean]: Whether to allow anonymous users to browse and pull public repositories.Defaults to True.
  * **Example**: `True`
* **feature_app_registry** [boolean]: Whether to enable support for App repositories. Defaults to False.
  * **Example**: `False`
* **feature_app_specific_tokens** [boolean]:  +      'description': 'If enabled, users can create tokens for use by the Docker CLI. Defaults to True.
  * **Example**: False
* **feature_bitbucket_build** [boolean]: Whether to support Bitbucket build triggers. Defaults to False.
  * **Example**: `False`
* **feature_bittorrent** [boolean]: Whether to allow using Bittorrent-based pulls. Defaults to False.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/bittorrent.html](https://coreos.com/quay-enterprise/docs/latest/bittorrent.html)
  * **Example**: `False`
* **feature_build_support** [boolean]: Whether to support Dockerfile build. Defaults to True.
  * **Example**: `True`
* **feature_change_tag_expirartion** [boolean]: Whether users and organizations are allowed to change the tag expiration for tags in their namespace. Defaults to True.
  * **Example**: `False`
* **feature_direct_login** [boolean]: Whether users can directly login to the UI. Defaults to True.
  * **Example**: `True`
* **feature_github_build** [boolean]: Whether to support GitHub build triggers. Defaults to False.
  * **Example**: `False`
* **feature_github_login** [boolean]: Whether GitHub login is supported. Defaults to False.
  * **Example**: `False`
* **feature_gitlab_build**[boolean]: Whether to support GitLab build triggers. Defaults to False.
  * **Example**: `False`
* **feature_google_login** [boolean]: Whether Google login is supported. Defaults to False.
  * **Example**: `False`
* **feature_invite_only_user_creation** [boolean]: Whether users being created must be invited by another user. Defaults to False.
  * **Example**: `False`
* **feature_library_support** [boolean]: Whether to allow for "namespace-less" repositories when pulling and pushing from Docker. Defaults to True.
  * **Example**: `True`
* **feature_mailing** [boolean]: Whether emails are enabled. Defaults to True.
  * **Example**: `True`
* **feature_nonsuperuser_team_syncing_setup** [boolean]: If enabled, non-superusers can setup syncing on teams to backing LDAP or Keystone. Defaults To False.
  * **Example**: `True`
* **feature_partial_user_autocomplete** [boolean]: If set to true, autocompletion will apply to partial usernames. Defaults to True.
  * **Example**: `True`
* **feature_permanent_sessions** [boolean]: Whether sessions are permanent. Defaults to True.
  * **Example**: `True`
* **feature_proxy_storage** [boolean]: Whether to proxy all direct download URLs in storage via the registry nginx. Defaults to False.
  * **Example**: `False`
* **feature_public_catalog** [boolean]: If set to true, the `_catalog` endpoint returns public repositories. Otherwise, only private repositories can be returned. Defaults to False.
  * **Example**: `False`
* **feature_reader_build_logs** [boolean]: If set to true, build logs may be read by those with read access to the repo, rather than only write access or admin access. Defaults to False.
  * **Example**: False
* **feature_recaptcha** [boolean]: Whether Recaptcha is necessary for user login and recovery. Defaults to False.
  * **Example**: `False`
  * **Reference**: [https://www.google.com/recaptcha/intro/](https://www.google.com/recaptcha/intro/)
* **feature_require_encrypted_basic_auth** [boolean]: Whether non-encrypted passwords (as opposed to encrypted tokens) can be used for basic auth. Defaults to False.
  * **Example**: `False`
* **feature_require_team_invite** [boolean]: Whether to require invitations when adding a user to a team. Defaults to True.
  * **Example**: `True`
* **feature_security_notifications** [boolean]: If the security scanner is enabled, whether to turn of/off security notificaitons. Defaults to False.
  * **Example**: `False`
* **feature_security_scanner** [boolean]: Whether to turn of/off the security scanner. Defaults to False.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/security-scanning.html](https://coreos.com/quay-enterprise/docs/latest/security-scanning.html)
  * **Example**: `False`
* **feature_storage_replication** [boolean]: Whether to automatically replicate between storage engines. Defaults to False.
  * **Example**: `False`
* **feature_super_users** [boolean]: Whether super users are supported. Defaults to True.
  * **Example**: `True`
* **feature_team_syncing** [boolean]: Whether to allow for team membership to be synced from a backing group in the authentication engine (LDAP or Keystone).
  * **Example**: `True`
* **feature_user_creation** [boolean] :Whether users can be created (by non-super users). Defaults to True.
  * **Example**: `True`
* **feature_user_log_access** [boolean]: If set to true, users will have access to audit logs for their namespace. Defaults to False.
  * **Example**: `True`
* **feature_user_metadata** [boolean]: Whether to collect and support user metadata. Defaults to False.
  * **Example**: `False`
* **feature_user_rename** [boolean]: If set to true, users can rename their own namespace. Defaults to False.
  * **Example**: `True`
* **github_login_config** [object, 'null']: Configuration for using GitHub (Enterprise) as an external login provider.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-auth.html](https://coreos.com/quay-enterprise/docs/latest/github-auth.html)
  * **allowed_organiztions** [array]: The names of the GitHub (Enterprise) organizations whitelisted to work with the ORG_RESTRICT option.
    * **Min Items**: None
    * **Unique Items**: True
      * **array item** [string]
  * **api_endpoint** [string]: The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
    * **Example**: `https://api.github.com/`
  * **client_id** [string] required: The registered client ID for this Quay instance; cannot be shared with GITHUB_TRIGGER_CONFIG.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `0e8dbe15c4c7630b6780`
  * **client_secret** [string] required: The registered client secret for this Quay instance.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
  * **github_endpoint** [string] required: The endpoint of the GitHub (Enterprise) being hit.
    * **Example**: `https://github.com/`
  * **org_restrict** [boolean]: If true, only users within the organization whitelist can login using this provider.
    * **Example**: `True`
* **github_trigger_config** [object, `null`]: Configuration for using GitHub (Enterprise) for build triggers.
  * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-build.html](https://coreos.com/quay-enterprise/docs/latest/github-build.html)
  * **api_endpoint** [string]: The endpoint of the GitHub (Enterprise) API to use. Must be overridden for github.com.
    * **Example**: `https://api.github.com/`
  * **client_id** [string] required: The registered client ID for this Quay instance; cannot be shared with GITHUB_LOGIN_CONFIG.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `0e8dbe15c4c7630b6780`
  * **client_secret** [string] required: The registered client secret for this Quay instance.
    * **Reference**: [https://coreos.com/quay-enterprise/docs/latest/github-app.html](https://coreos.com/quay-enterprise/docs/latest/github-app.html)
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
  * **github_endpoint** [string] required: The endpoint of the GitHub (Enterprise) being hit.
    * **Example**: `https://github.com/`
* **gitlab_trigger_config** [object]: Configuration for using Gitlab (Enterprise) for external authentication.
  * **client_id** [string] required: The registered client ID for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **client_secret** [string] required: The registered client secret for this Quay instance.
    * **Example**: `e4a58ddd3d7408b7aec109e85564a0d153d3e846`
    * **gitlab_endpoint** [string] required: The endpoint at which Gitlab(Enterprise) is running.
      * **Example**: `https://gitlab.com`
* **google_login_config** [object, `null`]: Configuration for using Google for external authentication
  * **client_id** [string] required: The registered client ID for this Quay instance.
    * **Example**: `0e8dbe15c4c7630b6780`
  * **client_secret** [string] required: The registered client secret for this Quay instance.
    * **Example**: e4a58ddd3d7408b7aec109e85564a0d153d3e846
* **health_checker** [string]: The configured health check.
  * **Example**: `('RDSAwareHealthCheck', {'access_key': 'foo', 'secret_key': 'bar'})`
* **log_archive_location** [string]:If builds are enabled, the storage engine in which to place the archived build logs.
  * **Example**: `s3_us_east`
* **log_archive_path** [string]: If builds are enabled, the path in storage in which to place the archived build logs.
  * **Example**: `archives/buildlogs`
* * **mail_default_sender** [string, `null`]: If specified, the e-mail address used as the `from` when Quay sends e-mails. If none, defaults to `support@quay.io`.
  * **Example**: `support@myco.com`
* **mail_password** [string, `null`]: The SMTP password to use when sending e-mails.
  * **Example**: `mypassword`
* **mail_port** [number]: The SMTP port to use. If not specified, defaults to 587.
  * **Example**: `588`
* **mail_server** [string]: The SMTP server to use for sending e-mails. Only required if FEATURE_MAILING is set to true.
  * **Example**: `smtp.somedomain.com`
* **mail_username** [string, 'null']: The SMTP username to use when sending e-mails.
  * **Example**: `myuser`
* **mail_use_tls** [boolean]: If specified, whether to use TLS for sending e-mails.
  * **Example**: `True`
* **maximum_layer_size** [string]: Maximum allowed size of an image layer. Defaults to 20G.
  * **Pattern**: ``^[0-9]+(G|M)$``
  * **Example**: `100G`
* **public_namespaces** [array]: If a namespace is defined in the public namespace list, then it will appear on *all* user's repository list pages, regardless of whether that user is a member of the namespace. Typically, this is used by an enterprise customer in configuring a set of "well-known" namespaces.
  * **Min Items**: None
  * **Unique Items**: True
    * **array item** [string]
* **prometheus_namespace** [string]: The prefix applied to all exposed Prometheus metrics. Defaults to `quay`.
  * **Example**: `myregistry`
* **recaptcha_site_key** [string]: If recaptcha is enabled, the site key for the Recaptcha service.
* **recaptcha_secret_key** [string]: 'If recaptcha is enabled, the secret key for the Recaptcha service.
* **registry_title** [string]: If specified, the long-form title for the registry. Defaults to `Quay Enterprise`.
  * **Example**: `Corp Container Service`
* **registry_title_short** [string]: If specified, the short-form title for the registry. Defaults to `Quay Enterprise`.
  * **Example**: `CCS`
* **security_scanner_endpoint** [string]: The endpoint for the security scanner.
  * **Pattern**: ``^http(s)?://(.)+$``
  * **Example**: `http://192.168.99.101:6060`
* **security_scanner_indexing_interval** [number]: The number of seconds between indexing intervals in the security scanner. Defaults to 30.
  * **Example**: `30`
* **session_cookie_secure** [boolean]: Whether the `secure` property should be set on session cookies. Defaults to False. Recommended to be True for all installations using SSL.
  * **Example**: True
  * **Reference**: [https://en.wikipedia.org/wiki/Secure_cookies](https://en.wikipedia.org/wiki/Secure_cookies)
* **super_users** [array]: Quay usernames of those users to be granted superuser privileges.
  * **Min Items**: None
  * **Unique Items**: True
    * **array item** [string]
* **team_resync_stale_time** [string]: If team syncing is enabled for a team, how often to check its membership and resync if necessary(Default: 30m).
  * **Pattern**: ``^[0-9]+(w|m|d|h|s)$``
  * **Example**: `2h`
* **userfiles_location** [string]: ID of the storage engine in which to place user-uploaded files.
  * **Example**: `s3_us_east`
* **userfiles_path** [string]: Path under storage in which to place user-uploaded files.
  * **Example**: `userfiles`
* **user_recovery_token_lifetime** [string]: The length of time a token for recovering a user accounts is valid. Defaults to 30m.
  * **Example**: `10m`
  * **Pattern**: `^[0-9]+(w|m|d|h|s)$`
* **v2_pagination_size** [number]: The number of results returned per page in V2 registry APIs.
  * **Example**: `100`
