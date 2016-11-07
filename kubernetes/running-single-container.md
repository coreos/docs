# Running a single container

[comment]: # (TODO: Environment Setup Guide / Reference?)

Let's say you just want to start one *one* container with Kubernetes. How would you do that?

## Start a deployment

First you need to define a deployment. This can be done a few ways, the fastest is with `kubectl run $DEPLOYMENT_NAME --image=$IMAGE --port=$PORT --replicas=$NUM_REPLICAS`. For example:

```
$ kubectl run webserver --image=nginx --port=80 --replicas=1
deployment "webserver" created
$ kubect get deployments
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
webserver   1         1         1            1           33s
$ kubect get pods
webserver-3274421635-a4al1   1/1       Running   0          35m
```

## Start a service

This is a great start, but we can't access our container yet. To do that we need to define a Kubernetes service, which we will do with `kubernetes expose deployment $DEPLOYMENT_NAME --type=$EXPOSE_TYPE`.

```
$ kubectl expose deployment webserver --type=NodePort
$ kubectl get services
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   10.0.0.1     <none>        443/TCP   5h
webserver    10.0.0.209   <pending>     80/TCP    22s
```

## Testing the service 

Now that we have created our application's service, we should verify that it is accessible to the outside world.

### Minikube

Minikube does not supply a URL in the output of `kubectl get services`, instead you have to use `minikube service $SERVICE_NAME --url` to get a given service's URI. One can test a web application service with the following `curl` command:

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

## Scale the service

Let's say you spoke too soon when you said you 'Only need one container'. We can scale a given deployment with `kubectl scale $DEPLOYMENT_NAME --replcias=$NUM`

```
$ kubectl scale deployments webserver --replicas=5
$ kubectl get deployments webserver
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

Replicas can be increased or decreased based on you see fit and pods will be created and deleted accordingly.

## Delete the service

```
$ kubectl delete service,deployment nginx
```

## File based management

Manually spinning up and tearing down containers is fun, but keeping your infrastructure in files is much easier to automate and maintain.  Kubernetes can accept json or yaml files as input for creating, updating, and destroying pretty much everything.

You can save a json or yaml file describing a running application with the following command:

```
$ kubectl get deployments,services webserver -o yaml > webserver.yml
```

Feel free to read through `webserver.yml`, but for our purposes it's not necessary.

To destroy the deployments and services in this file pass the `-f` flag to `kubectl delete`.

```
$ kubectl delete -f webserver.yml 
deployment "webserver" deleted
service "webserver" deleted
$ kubectl get all
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   10.0.0.1     <none>        443/TCP   5h
```

To spin up the app again, pass the `-f` flag to `kubectl create`.

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
