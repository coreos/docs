[k8s]: http://kubernetes.io/
[k8s-coreos-guide]: https://github.com/GoogleCloudPlatform/kubernetes/blob/v1.0.0/docs/getting-started-guides/coreos/coreos_multinode_cluster.md
[k8s-user-guide]: https://github.com/GoogleCloudPlatform/kubernetes/blob/v1.0.0/docs/user-guide.md

# Getting Started with CoreOS and Kubernetes

[Kubernetes][k8s] is a distributed container platform originally developed by Google. CoreOS has developed a number of technologies that are complimentary or required by Kubernetes, including etcd, flannel, and fleet. 

## Differences between fleet and Kubernetes

Fleet is a low level distributed init system. Fleet is useful for "booting" a distributed system, such as Kubernetes. Fleet is great for tools that are building products that are platforms themselves. Kubernetes is intended a complete distributed platform that includes service discovery, overlay networking, and robust APIs.

Fleet should be used if you are building your own platform that orchestrates containers or the host system.

Kubernetes is recommended for most operations teams that are looking to deploy containers against a distributed platform. 

## Deploy Kubernetes on CoreOS

Please refer to the [CoreOS Multinode Cluster][k8s-coreos-guide] guide for the latest instructions for running Kubernetes on CoreOS. 

## Getting started with Kubernetes

Refer to the [Kubernetes User Guide][k8s-user-guide] for detailed instructions on how to use Kubernetes.
