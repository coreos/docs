# BitTorrent-based distribution

Quay Enterprise supports BitTorrent-based distribution of its images to clients via the [quayctl](https://github.com/coreos/quayctl) tool. BitTorrent-based distribution allows for machines to share image data amongst themselves, resulting in faster downloads and shorter production launch times.

## Visit the management panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Quay Enterprise Management Panel"/>

## Enable BitTorrent distribution

<img src="img/enable-bittorrent.png" class="img-center" alt="Enable BitTorrent distribution"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled **BitTorrent-based download**.
- Check the "Enable BitTorrent downloads" box

## Enter an announce URL

In the "Announce URL" field, enter the HTTP endpoint of a JWT-capable BitTorrent tracker's announce URL such as [Chihaya](running-chihaya.md). This will typically be a URL ending in `/announce`.

## Save configuration

- Click "Save Configuration Changes"
- Restart the container (you will be prompted)
