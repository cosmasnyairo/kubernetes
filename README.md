# Kubernetes 

A list of Kubernetes templates and commands

## Table of Contents

- [Notes](#notes)
- [Pod](#pod)
- [Replication Controller and replicaset](#replication-controller-and-replicaset)
- [Deployments](#deployments)
- [Namespaces](#namespaces)
- [Services](#services)
- [Config Map](#config-map)
- [Secrets](#secrets)
- [Service Account](#service-account)

## Notes

---

Cluster is a collection of nodes

Master node has:

- api sever (frontend for kube)
- etcd (key store for data used to manage cluster)
- scheduler (assigns containers to nodes)
- controller (bring up containers when they go down)

Worked node has:

- kubelet (agent in each node in cluster that ensures containers running on nodes as expected)
- runtime (software to run containers in the background i.e docker)

Multi container pods can communicate to each other through localhost

Resources in a namespace can refer to each other by their names

```
pods have a 1 to 1 relationship with containers
entrypoint in docker -> command in kubernetes
cmd in docker -> args in kubernetes
kube system - resources for internal purposes for kubernetes
kube public - resources to be made available to all users
```

---

## Pod


---

Single instance of an application (smallest object we can create in k8)

We scale pods up or down

[Pod Definition file](templates/deployment.yml)

```console
kubectl get pods -o wide
```

```console
kubectl get pods -A
```

```console
kubectl label pod/<pod-name> <label>=<value>
```

```console
kubectl get pods,svc
```

```console
kubectl run <pod-name> --image=<image-name>  -n <namespace> --dry-run=client -o yaml > test.yaml
```

```console
kubectl set image pod <pod-name> <container-name>=<image>
```

```console
kubectl get pod <pod-name> -o yaml > pod-definition.yaml
```

```console
kubectl apply -f test.yaml
```

```console
kubeclt edit pod <pod-name>
```

```console
kubectl explain pods --recursive | less
```

```console
kubectl explain pods --recursive | grep envFrom -A<number-of-lines>
```

---

## Replication Controller and Replicaset

---

```
Replication controller is in v1 while replicaset in apps/v1

Replica set uses selector to determine pods to watch and manage even existing pods

```
[Replicaset Definition file ](templates/replicaset.yaml)
[Replicationcontroller Definition file](templates/replicationcontroller.yaml)

```console
kubectl create -f definition.yml
```

```console
kubectl get replicationcontroller
```

```console
kubectl get rs
```

```console
kubectl delete replicaset <replicaset-name>
```

```console
kubectl edit replicaset <replicaset-name>
```

```console
kubectl set image rs <replica-set> <container-name>=<image>

```

```console
kubectl describe replicaset <replicaset-name>
```

```console
kubectl apply -f definition.yml
```

```console
kubectl replace -f definition.yml
```

```console
kubectl scale -replicas=10 -f definition.yml
```

```console
kubectl scale --replicas=0 replicaset/<replicaset-name>
```

---

## Deployments

---

[Deployment Definition file ](templates/deployment.yml)

```console
kubectl create deployment nginx --image=nginx
```

```console
kubectl scale deploy/webapp --replicas=3
```

```console
kubectl get deploy
```

```console
kubectl delete deployment <deployment -name>
```

```console
kubectl create deploy redis-deploy --image=redis --replicas=2 -n dev-ns
```

---

## Namespaces

---

[Namespace Definition file ](templates/namespace.yml)
[Resource Quota Definition file](templates/resourcequota.yml)
```console
kubectl create ns <namespace-name>
```

```console
kubectl config set-context $(kubectl config current-context) -n <namespace-name>
```

---

## Services

---

To connect to another service in a different namespace: we use the following syntax:

```
<service-name>.<namespace>.<svc>.<domain>
test-service.test-ns.svc.cluster.local

```

```console
kubectl expose pod <pod-name> --type=<type> --port=<port> --name=<service-name>
```

```console
kubectl create service <type> <service-name> --tcp=<port>
```

---

## Config Map

---

- Imperative

  ```console

  kubectl create configmap \
      app-config --from-literal=APP_COLOR=RED \
                 --from-literal=APP_TYPE=AAB \
                 --from-literal=APP_ENV=PROD \
  ```

  ```console
  kubectl create configmap \
      app-config --from-file=app_config.properties
  ```

- Declarative:

  ```console
  kubectl create -f test-config-map.yml
  ```

  ```console
  kubectl get configmaps
  kubectl get cm
  kubectl describe configmap
  ```

---

## Secrets

---

- Imperative

  ```console
  kubectl create secret generic \
      app-secret --from-literal=DB_HOST=mysql \
                 --from-literal=DB_PORT=1000
                 --from-literal=DB_NAME=test \
  ```

  ```console
  kubectl create secret generic \
      app-secret --from-file=test.env
  ```

- Declarative

  ```console
  kubectl create -f test-secret.yml
  ```

  ```console
  kubectl get secrets
  ```

  ```console
  kubectl get secret <secret-name> -o yaml
  ```

  ```console
  kubectl describe secrets
  ```

---

## Service Account

---

```console
kubectl create serviceaccount test-sa
```

```console
kubectl get serviceaccount
```

```console
kubectl describe serviceaccount test-sa
```

---
