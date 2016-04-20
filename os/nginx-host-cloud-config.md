# Hosting cloud-config using nginx

The nginx HTTP server can be used to serve `could-config` files to booting CoreOS machines. With the addition of the [http_sub_module][http_sub_module], nginx can perform appropriate substitution of the `cloud-config` `$private_ipv4` and `$public_ipv4` variables used to simplify network configuration. The `http_sub_module` is enabled in the official nginx binaries, and in most Linux distributions' nginx packages.

## Example

The example nginx configuration below will perform replacement of the `$public_ipv4` and `$private_ipv4` variables for each client connection from a CoreOS machine booting through the cloud-init process.

```
location ~ ^/user_data {
  root /path/to/cloud/config/files;
  sub_filter $public_ipv4 '$remote_addr';
  sub_filter $private_ipv4 '$http_x_forwarded_for';
# sub_filter $private_ipv4 '$http_x_real_ip';
  sub_filter_once off;
  sub_filter_types '*';
}
```

This example configuration is valid for all `/user_data*` URIs (e.g., `/user_data_host1`, `/user_data_host2`). With a remote nginx accessed via a transparent proxy, `$private_ipv4` substitution will work only if the proxy adds appropriate `HTTP_X_FORWARDED_FOR` or `HTTP_X_REAL_IP` HTTP header to requests.

[nginx]: http://nginx.org/en/
[http_sub_module]: http://nginx.org/en/docs/http/ngx_http_sub_module.html
