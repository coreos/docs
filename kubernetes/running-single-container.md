# Running a single container

**Note**: *This guide assumes that you have a working Kubernetes cluster avaliable to play with. If you don't yet have one avaliable try [installing MiniKube][minikube-install].*

Let's say you just want to start *one* container with Kubernetes. How would you do that?

## Define a deployment

First you need to define a **deployment**. A deployment has three main jobs:

* **Run** a desired number of containers, called **pods**.
* **Monitor** container healthy and restarts as necessary.
* Execute **rolling upgrades** when an image is updated.

This can be done a few ways, the fastest is with `kubectl run $DEPLOYMENT_NAME --image=$IMAGE --port=$PORT --replicas=$NUM_REPLICAS`. For example:

```
$ kubectl run \
    webserver \
    --image=nginx \
    --port=80 \
    --replicas=1
deployment "webserver" created
$ kubectl get deployments
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
webserver   1         1         1            1           33s
```

As you can see our deployment started a single copy of the container.  To view your running pods run `kubectl get pods`

```
$ kubectl get pods
webserver-3274421635-a4al1   1/1       Running   0          35m
```

## Define a service

This is a great start, but we can't access our container yet. To do that we need to define a **Kubernetes service**. Services are used to group a set of replicated pods into one interface, like exposing one load balanced front-end for many identical pods.

We can define a service with with `kubernetes expose deployment $DEPLOYMENT_NAME --type=$EXPOSE_TYPE`.

```
$ kubectl expose \
    deployment webserver \
    --type=NodePort
$ kubectl get services
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   10.0.0.1     <none>        443/TCP   5h
webserver    10.0.0.209   <pending>     80/TCP    22s
```

## Testing the service 

Now that we have created our application's service, we should verify that it is accessible to the outside world.

### Minikube

Minikube does not supply a URL in the output of `kubectl get services`, instead you have to use the `minikube service $SERVICE_NAME --url` command to get a given service's URI. A web service can be tested with the following `curl` command:

```
$ curl $(minikube service webserver --url)
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
[...]
```

[comment]: # (### AWS)

[comment]: # (### Tectonic)

[comment]: # (### GCE)


## Scale a service

Let's say you spoke too soon when you said you 'only need one container'. We can scale a given deployment with `kubectl scale $DEPLOYMENT_NAME --replcias=$NUM`

```
$ kubectl scale \
    deployments webserver \
    --replicas=5
$ kubectl get deployment webserver
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
webserver   5         5         5            5           18m
$ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
webserver-3274421635-7zupw   1/1       Running   0          53s
webserver-3274421635-a19vl   1/1       Running   0          53s
webserver-3274421635-a4al1   1/1       Running   0          18m
webserver-3274421635-isrmc   1/1       Running   0          53s
webserver-3274421635-wwnum   1/1       Running   0          53s
```

Replicas can be increased or decreased based what on you see fit; pods will be created and deleted accordingly.

## Update an image

For one reason or another you may choose to update a deployment's container. This can be done with `kubectl set image deployment $DEPLOYMENT_NAME $DEPLOYMENT_NAME=$IMAGE:$TAG`.

```
$ kubectl set image \
    deployment webserver \
    webserver=nginx:alpine
```

Watching the output of `kubectl get deployment webserver` will show old containers being destroyed and new containers being created. If the new container fails to run, Kubernetes will ensure that some percentage of the old containers are still running to prevent the service from going down entirely.

## Delete a service and deployment

To delete a deployment or service use `kubectl delete $SELECTORS $RESOURCE`.

```
$ kubectl delete service,deployment webserver
$ kubect get deployments,services webserver
[deployments.extensions "webserver" not found, services "webserver" not found]
```

As you can see the `webserver` service has been delete from the cluster.

## File based management

Manually spinning up and tearing down containers is fun, but keeping your infrastructure in files is much easier to automate and maintain.  Kubernetes can accept json or yaml files as input for creating, updating, and destroying pretty much everything.

Save a json or yaml file describing a running application with the following command:

```
$ kubectl get deployments,services webserver -o yaml > webserver.yml
```

Feel free to read through `webserver.yml`, but for our purposes it's not necessary.

Once the resource file is created, it can be passed to kubernetes sub-commands with the `-f` flag. Resources can be spun up with the `kubectl create -f $FILE` command.

```
$ kubectl create -f webserver.yml 
deployment "webserver" created
service "webserver" created
$ kubectl get all
NAME             CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   10.0.0.1     <none>        443/TCP   5h
svc/webserver    10.0.0.209   <nodes>       80/TCP    3s
NAME                            READY     STATUS              RESTARTS   AGE
po/webserver-3274421635-e7ldj   1/1       Running             0          3s
po/webserver-3274421635-kykpc   0/1       ContainerCreating   0          3s
```

Resources can then be destroyed using `kubectl delete -f $FILE`.

```
$ kubectl delete -f webserver.yml 
deployment "webserver" deleted
service "webserver" deleted
$ kubectl get all
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   10.0.0.1     <none>        443/TCP   5h
```

[minikube-install]: https://github.com/kubernetes/minikube/releases
