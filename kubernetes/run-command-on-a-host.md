# Running a command on a Kubernetes host

In a perfect world you would never need to manually run a command on one of your orchestration hosts. In the *real* world you will probably need to do this at least once. Most orchestration systems are not designed for this operation, but they rarely block you from doing it.

## Running commands on a fleet host

Running commands on a fleet host is as simple as `fleetctl ssh <machine id>`.

```
CoreOS alpha (1248.1.0)
core@core-01 ~ $ fleetctl list-machines
MACHINE     IP      METADATA
351cdb78... 172.17.8.101    -
3b836135... 172.17.8.103    -
8c554606... 172.17.8.102    -
core@core-01 ~ $ fleetctl ssh 8c554606
Last login: Thu Dec 15 00:13:50 UTC 2016 from 11.22.33.44 on pts/0
CoreOS alpha (1248.1.0)
core@core-02 ~ $ 
```

Just like that!

## Running commands on a Kubernetes host

Unfortunately there is not one easy, convenient, or sure-fire way to run commands on a Kubernetes host. Some providers (e.g., aws, gcloud, etc) make it easier than others, but [for now there is no `kubectl ssh` command][kube-ssh]. For this reason we will have to go through the most popular providers on a case-by-case basis.

**To run a command in a Kubernetes pod, use `kubectl exec <pod name> <command>` or `kubectl exec -it <pod name> sh` to enter a shell in the pod**.

### Kubernetes on AWS

This section assumes you used [`kube-aws`][gh-kube-aws] to setup your cluster. Most of of the information found here can be found in the AWS EC2 web interface.

The simplest way to run commands on a Kubernetes node is to use `ssh`. You'll need the following information to login to a node:

* The SSH key you setup with EC2 (`user-name.pem`)
* The public-ip of the node you want to login to (`public.facing.node.ip`)

The public IP or public DNS address of a node can be found using just the `aws` CLI tool:

```
$ aws ec2 describe-instances --filters Name=key-name,Values=user-name Name=tag:Name,Values=elijah-docs-testing-kube-aws-controller
{
  "Reservations": [
   ...
      "Instances": [
          ...
          "PublicDnsName": "ec2-111-222-121-212.us-west-2.compute.amazonaws.com", 
          ...
          "PublicIpAddress": "111.222.121.212", 
          ...
          "Tags": [
            ...
            {
              "Value": "my-k8s-cluster-kube-aws-controller", 
              "Key": "Name"
            }, 
            ...
```

Alternatively the `kubectl describe nodes` command can be used to find the ip addresses of a node:

```
$ kubectl get nodes
NAME                                       STATUS                     AGE
ip-10-0-0-168.us-west-2.compute.internal   Ready                      3h
ip-10-0-0-50.us-west-2.compute.internal    Ready,SchedulingDisabled   3h
$ kubect describe node ip-10-0-0-50.us-west-2.compute.internal
[...]
Addresses:      10.0.0.50,10.0.0.50,111.222.121.212
[...]
```

Using your choice of terminal, shell, or other SSH client, run commands on the node like so:

```
$ ssh -i /path/to/user-name.pem core@111.222.121.212 -- 'docker ps'
CONTAINER ID        IMAGE                                                        COMMAND                  CREATED             STATUS              PORTS               NAMES
9dd322b0845a        gcr.io/google_containers/exechealthz-amd64:1.1               "/exechealthz '-cmd=n"   34 minutes ago      Up 34 minutes                           k8s_healthz.bbab67dc_kube-dns-v17.1-vhgjo_kube-system_6753182e-c3bb-11e6-afb3-0a878799edb7_1e3a012a
[...]
```

You can also use the `PublicDnsName` (instead of the `PublicIpAddress`) and login to the node to get a shell on the node.

```
$ ssh -i /path/to/user-name.pem core@ec2-111-222-121-212.us-west-2.compute.amazonaws.com
Last login: Fri Dec 16 18:33:46 UTC 2016 from 11.22.33.44 on pts/0
CoreOS stable (1185.5.0)
Update Strategy: No Reboots
core@ip-10-0-0-168 ~ $ echo $HOSTNAME
ip-10-0-0-168.us-west-2.compute.internal
```

### Kubernetes on Google Cloud

```
TODO: Outline this example
  General outline:
    Using the gcloud cli: `gcloud ssh node-name` has been told to work.
```

### Kubernetes on bare metal

Loging into a bare metal Kubernetes node is very similar to how we log into an AWS node. We start by finding the Ip address of the node, then the key, and using `ssh` to run commands on the node.

The Node IP address can be found using `kubectl describe node <node name>` or `kubectl describe nodes` for all nodes. The IP address is located under the `Addresses` field.

```
$ kubectl get nodes
NAME                STATUS                     AGE
controller-node     Ready,SchedulingDisabled   4h
worker-node-1       Ready                      4h
worker-node-2       Ready                      4h
$ kubectl describe node controller-node
[...]
Addresses:       10.0.0.18
[...]
$ ssh -i /path/to/k8s/credentials/admin-key core@10.0.0.18
Last login: Thu Dec 15 00:14:08 UTC 2016 from 11.22.33.44 on pts/0
CoreOS alpha (1262.0.0)
core@controller-node ~ $ echo $HOSTNAME
controller-node
```

### Minikube

Minikube provides a simple way to do this with the `minikube ssh` command.

```
$ minikube ssh
[...]
Boot2Docker version 1.11.1, build master : 901340f - Fri Jul  1 22:52:19 UTC 2016
Docker version 1.11.1, build 5604cbe
docker@minikube:~$ docker ps
CONTAINER ID        IMAGE                                                        COMMAND                  CREATED             STATUS              PORTS               NAMES
21145aebcba1        gcr.io/google_containers/kubedns-amd64:1.8                   "/kube-dns --domain=c"   29 minutes ago      Up 29 minutes                           k8s_kubedns.4f05776_kube-dns-v20-1ursk_kube-system_e9996080-c329-11e6-bbb2-0e3eb4884b15_5ae8b5d4
[...]
```

[gh-kube-aws]: https://github.com/coreos/kube-aws
[kube-ssh]: https://github.com/kubernetes/kubernetes/issues/3920#issuecomment-211721711
