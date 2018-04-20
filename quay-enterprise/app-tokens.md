# Quay Enterprise Application Tokens #

Since Quay Enterprise version 2.7.0, a new way of authenticating to Quay from Docker CLI (and other apps) was added, in the form of application tokens. These tokens don't expire by default, but this expiration can be set inside the Quay super user control panel. 
To enable expiration of application tokens, the following option must be selected:

![Quay Enterprise Super User control panel](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/set-token-expiration-time.png "Quay Enterprise admin control panel")

Note that the number of days **needs** to be specified, if the text field is blank, the tokens will never expire.

## Icons explained ##

In most cases, a namespace owner will have multiple tokens for multiple applications. Each token can have its own expiration time.

![Application Tokens](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/app-token-list.png "Application tokens")

Every token is marked with a triangle that shows the current state of the token:

* red triangle (not shown): marks the expired token
* yellow triangle: tokens that will expire in 30 days time.
* green triangle: token that has more than 30 days left till expiration.

Note: Only Quay admins can set token expiry times. Namespace owners cannot choose the time.

## Using tokens ##

Tokens are used much the same way as encrypted passwords or robot account credentials. Upon clicking on any of the tokens, you should see the following:

![Token Information](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/app-token-details.png "Token Information")

The difference between encrypted passwords and robot accounts and tokens is that a token always has a username `$app` no matter how you use the token. 
