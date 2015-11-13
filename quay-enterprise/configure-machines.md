# Configure Machines for Quay Enterprise

Quay Enterprise allows you to create teams and user accounts that match your existing business unit organization. A special type of user, a robot account, is designed to be used programatically by deployment systems and other pieces of software. Robot accounts are commonly configured with read-only access to an organizations repositories.

This guide we will assume you have the DNS record `registry.example.com` configured to point to your Enterprise Registry.

## Credentials

Each CoreOS machine needs to be configured with the username and password for a robot account in order to deploy your containers. Docker looks for configured credentials in a `.dockercfg` file located within the user's home directory. You can download this file directly from the Quay Enterprise interface. Let's assume you've created a robot account called `myapp+deployment`.

Writing the `.dockercfg` can be specified in [cloud-config](https://coreos.com/os/docs/latest/cloud-config.html) with the write_files parameter, or created manually on each machine.

### Kubernetes Pull Secret

If you are using Quay Enterprise in conjunction with a Kubernetes or Tectonic cluster, it's easiest to use the built in secret distribution method. This method allows for you to use different sets of robot accounts on a per-app basis, and also allows for them to be updated or rotated at any time across all machines in the cluster.

An "Image Pull Secret" is a special secret that Kubernetes will use when pulling down the containers in a pod. It is a base64-encoded Docker config file. Here's an example:

```sh
$ cat ~/.dockercfg | base64
eyAiaHR0cHM6Ly9pbmRleC5kb2NrZXIuaW8vdjEvIjogeyAiYXV0aCI6ICJabUZyWlhCaGMzTjNiM0prTVRJSyIsICJlbWFpbCI6ICJqZG9lQGV4YW1wbGUuY29tIiB9IH0K
```

```
apiVersion: v1
kind: Secret
metadata:
  name: FoobarQuayCreds
data:
  .dockercfg: eyAiaHR0cHM6Ly9pbmRleC5kb2NrZXIuaW8vdjEvIjogeyAiYXV0aCI6ICJabUZyWlhCaGMzTjNiM0prTVRJSyIsICJlbWFpbCI6ICJqZG9lQGV4YW1wbGUuY29tIiB9IH0K
type: kubernetes.io/dockercfg
```

To use this secret, first submit it into the cluster:

```sh
$ kubectl create -f /tmp/foobarquaycreds.yaml
secrets/FoobarQuayCreds
```

And then reference it in a Pod or Replication Controller:

```
apiVersion: v1
kind: Pod
metadata:
  name: Foobar
spec:
  containers:
    - name: foo
      image: quay.io/coreos/etcd:v2.2.1
  imagePullSecrets:
    - name: FoobarQuayCreds
```

### Cloud-Config

A snippet to configure the credentials via write_files looks like:

```yaml
#cloud-config

write_files:
  - path: /root/.dockercfg
    permissions: 0644
    content: |
      {
       "https://registry.example.com/v1/": {
        "auth": "cm9ic3p1bXNrajYzUFFXSU9HSkhMUEdNMEISt0ZXN0OkdOWEVHWDRaSFhNUVVSMkI1WE9MM1k1S1R1VET0I1RUZWSVg3TFRJV1I3TFhPMUI=",
        "email": ""
       }
      }
```

Each machine booted with this cloud-config should automatically be authenticated with Quay Enterprise.


### Manual Login

To temporarily login to a Quay Enterprise account on a machine, run `docker login`:

```sh
$ docker login registry.example.com
Login against server at https://registry.example.com/v1/
Username: myapp+deployment
Password: GNXEGX4Y5J63PQWIOGJHLPGM0B5GUDOBZHXMQUR2B5XOL35EFVIX7LTIWR7LXO1B
Email: myemail@example.com
```

## Test Push or Pull

Now that your machine is authenticated, try pulling one of your repositories. If you haven't pushed a repository into your Enterprise Registry, you will need to tag it with the full name:

```sh
$ docker tag bf60637a656c registry.domain.com/myapp
$ docker push registry.domain.com/myapp
```

If you already have images in your registry, test out a pull:

```sh
docker pull registry.domain.com/myapp
```

## Pulling via systemd

Assuming a .dockercfg is present in /root, the following is an example systemd unit file that pulls a docker image:

```
[Unit]
Description=Hello World

[Service]
WorkingDirectory=/root
ExecStartPre=-/usr/bin/docker kill hello-world
ExecStartPre=-/usr/bin/docker rm -f hello-world
ExecStartPre=/usr/bin/docker pull quay.io/example/hello-world:latest
ExecStart=/usr/bin/docker run --rm --name hello-world quay.io/example/hello-world:latest
ExecStop=-/usr/bin/docker stop hello-world
```

If the working directory is not set, docker will not be able to discover the .dockercfg file and will not have the credentials to pull private images.
