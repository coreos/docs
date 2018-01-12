# Quay Enterprise Application Tokens #

Since Quay Enterprise version 2.7.0, a new way of authenticating to Quay from Docker CLI (and other apps) was added, in the form of application tokens. These tokens don't expire by default, but this expiration can be set inside the Quay superadmin control panel. 
To enable expiration of application tokens, the following option must be selected in the Quay Enterprise suerpadmin control panel:

![Quay Enterprise superadmin control panel](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/set-token-expiration-time.png "Quay Enteprrise admin control panel")

Note that the number of days **needs** to be specified, if the text field is blank, the tokens will never expire.

## Icons explained ##

In a typical situation, a repo owner might have multiple tokens created for multiple applciations, and every token has its own expiry time, as we can see here:

![Application Tokens](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/app-token-list.png "Application tokens")

Every token is marked with a triangle that shows the current state of the token:

* red triangle (not shown): marks the expired token
* yellow triangle: tokens that will expire in 30 days time.
* green triangle: token that has more than 30 days left till expiration.

Note that currently a repo owner **can't** choose the token expiration time. This can be set only by the Quay admin.

## Using tokens ##

Tokens are used much the same way as encrypted passwords or robot account credentials. Upon clicking on any of the tokens, you should see the following:

![Token Information](https://github.com/ibazulic/docs/blob/master/quay-enterprise/img/app-token-details.png "Token Information")

The difference between encrypted passwords and robot accounts and tokens is that a token always has a username `$app` no matter how you use the token. 
