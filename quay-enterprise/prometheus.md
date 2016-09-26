# Prometheus metrics under Quay Enterprise

Quay Enterprise exports a [Prometheus](prometheus.io)-compatible endpoint on each instance to allow for easy monitoring and alerting.

[prometheus.io]: https://prometheus.io/

## Exposing the prometheus endpoint

The Prometheus-compatible endpoint on the Quay Enterprise instance can be found at port `9092`. Simply add `-p 9092:9092` to the `docker run` command (or expose the port via the `Pod` configuration in Kubernetes).

## Setting up Prometheus to consume metrics

Prometheus needs a way to access all Quay Enterprise instances running in a cluster." In the typical setup, this is done by listing all the Quay Enterprise instances in a single named DNS entry, which is then given to Prometheus.

### DNS configuration under Kubernetes

A simple [Kubernetes service](k8s service) can be configured to provide the DNS entry for Prometheus. Details on running Prometheus under Kubernetes can be found at [Prometheus and Kubernetes](k8s + prometheus) and [Monitoring Kubernetes with Prometheus](monitoring k8s + prometheus).

[k8s service]: http://kubernetes.io/docs/user-guide/services/
[k8s + prometheus]: https://coreos.com/blog/prometheus-and-kubernetes-up-and-running.html
[monitoring k8s + prometheus]: https://coreos.com/blog/monitoring-kubernetes-with-prometheus.html

### DNS configuration for a manual cluster

[SkyDNS](skydns) is a simple solution for managing this DNS record when not using Kubernetes. SkyDNS can run atop an [etcd](etcd) cluster. Entries for each Quay Enterprise instance in the cluster can be added and removed in the etcd store. SkyDNS will regularly read them from there and update the list of Quay instances in the DNS record accordingly.

[skydns]: https://github.com/skynetservices/skydns
[etcd]: https://github.com/coreos/etcd
