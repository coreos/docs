## Hosting Cloud-Config Using Nginx

One of the ways to host your `cloud-config` files is to use [nginx][nginx]. You can also use [http_sub_module][http_sub_module] which will allow you to use `$private_ipv4` and `$public_ipv4` substitution variables referenced in other documents. By default this module is enabled in official nginx packages and in most Linux distributions.

Here is an example nginx configuration which will substitute `$public_ipv4` and `$private_ipv4` (depends on your nginx server location and NAT configuration) variables:

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

This example configuration is valid for all `/user_data*` URIs (i.e. `/user_data_host1`, `/user_data_host2`, etc.). `$private_ipv4` substitution will work only if your local hosts use a transparent http proxy which adds `HTTP_X_FORWARDED_FOR` or `HTTP_X_REAL_IP` HTTP request headers and your nginx server is hosted remotely.

[nginx]: http://nginx.org/en/
[http_sub_module]: http://nginx.org/en/docs/http/ngx_http_sub_module.html
