# Quay Enterprise Installation on Tectonic

This guide walks through the deployment of [Quay Enterprise][quay-enterprise-tour] onto a Tectonic cluster.
After completing the steps in this guide, a deployer will have a functioning instance of Quay Enterprise orchestrated as a Kubernetes service on a Tectonic cluster, and will be able to access the Quay Enterprise Setup tool with a browser to complete configuration of image repositories, builders, and users.

[quay-enterprise-tour]: https://quay.io/tour/enterprise

## Prerequisites

A PostgreSQL database must be available for Quay Enterprise metadata storage.
We currently recommend running this database server outside of the cluster.

## Download Kubernetes Configuration Files

Visit your [Tectonic Account][tectonic-account] and download the pre-formatted pull secret, under "Account Assets". There are several formats of the secret, be sure to download the "dockercfg" format resulting in a `config.json` file. This pull secret is used to download the Quay Enterprise containers.

This will be used later in the guide.

[tectonic-account]: https://account.tectonic.com

Next, download each of the following files to your workstation, placing them alongside your pull secret:

- [quay-enterprise-namespace.yml](files/quay-enterprise-namespace.yml)
- [quay-enterprise-config-secret.yml](files/quay-enterprise-config-secret.yml)
- [quay-enterprise-redis.yml](files/quay-enterprise-redis.yml)
- [quay-enterprise-app-rc.yml](files/quay-enterprise-app-rc.yml)
- [quay-enterprise-service-nodeport.yml](files/quay-enterprise-service-nodeport.yml)
- [quay-enterprise-service-loadbalancer.yml](files/quay-enterprise-service-loadbalancer.yml)

## Role Based Access Control

Quay Enterprise has native Kubernetes integrations. These integrations require Service Account to have access to Kubernetes API. When Kubernetes RBAC is enabled (Tectonic  v1.4 and later), Role Based Access Control policy manifests also have to be deployed.

Kubernetes API has minor changes between versions 1.4 and 1.5, Download appropiate versions of Role Based Access Control (RBAC) Policies.

### Tectonic v1.5.x RBAC Policies

- [quay-servicetoken-role.yaml](files/quay-servicetoken-role.yaml)
- [quay-servicetoken-role-binding.yaml](files/quay-servicetoken-role-binding.yaml)

### Tectonic v1.4.x RBAC Policies

- [quay-servicetoken-role.yaml](files/quay-servicetoken-role.yaml)
- [quay-servicetoken-role-binding-k8s1-4.yaml](files/quay-servicetoken-role-binding-k8s1-4.yaml)

## Deploy to Kubernetes

All Kubernetes objects will be deployed under the "quay-enterprise" namespace.
The first step is to create this namespace:

```sh
kubectl create -f quay-enterprise-namespace.yml
```

Next, add your pull secret to Kubernetes (make sure you specify the correct path to `config.json`):

```sh
kubectl create secret generic coreos-pull-secret --from-file=".dockerconfigjson=config.json" --type='kubernetes.io/dockerconfigjson' --namespace=quay-enterprise
```

### Tectonic v1.5.x : Deploy RBAC Policies

```sh
kubectl create -f quay-servicetoken-role.yaml
kubectl create -f quay-servicetoken-role-binding.yaml
```

### Tectonic v1.4.x : Deploy RBAC Policies

```sh
kubectl create -f quay-servicetoken-role.yaml
kubectl create -f quay-servicetoken-role-binding-k8s1-4.yaml
```

### Deploy Quay Enterprise objects

Finally, the remaining Kubernetes objects can be deployed onto Kubernetes:

```sh
kubectl create -f quay-enterprise-config-secret.yml -f quay-enterprise-redis.yml -f quay-enterprise-app-rc.yml
```

## Expose via Kubernetes Service

In order to access Quay Enterprise, a user must route to it through a Kubernetes Service.
It is up to the deployer to decide which Service type is appropriate for their use case: a [LoadBalancer](http://kubernetes.io/docs/user-guide/services/#type-loadbalancer) or a [NodePort](http://kubernetes.io/docs/user-guide/services/#type-nodeport).

A LoadBalancer is recommended if the Kubernetes cluster is integrated with a cloud provider, otherwise a NodePort will suffice.
Along with this guide are examples of this service.

### LoadBalancer

Using the sample provided, a LoadBalancer Kubernetes Service can be created like so:

```sh
kubectl create -f quay-enterprise-service-loadbalancer.yml
```

kubectl can be used to find the externally-accessible URL of the quay-enterprise service:

```sh
kubectl describe services quay-enterprise --namespace=quay-enterprise
```

### NodePort

Using the sample provided, a NodePort Kubernetes Service can be created like so:

```sh
kubectl create -f quay-enterprise-service-nodeport.yml
```

By default, the quay-enterprise service will be available on port 30080 on every node in the Kubernetes cluster.
If this port conflicts with an existing Kubernetes Service, simply modify the sample configuration file and change the value of NodePort.

## Continue with Quay Enterprise Setup

All that remains is to configure Quay Enterprise itself.
After successfully creating the quay-enterprise Kubernetes Service, navigate to `http://{quay-enterprise}/setup` in a web browser to load the Quay Enterprise setup tool, replacing `{quay-enterprise}` with a value that routes to your Service.

Once at the Quay Enterprise setup UI, follow the setup instructions to finalize your installation.
