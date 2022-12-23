# Kubernetes Commands I Use

A list of Kubernetes commands i use

## Table of Contents
- [Notes](#notes)
- [Pod](#pod)
- [Replication Controller and replicaset](#replication-controller-and-replicaset)
- [Services](#Services)
- [Config Map](#config-map)
- [Secrets](#secrets)
- [Service Account](#service-account)

## Notes

----
Cluster is a collection of nodes

Master node has:
- api sever  (frontend for kube)
- etcd (key store for data used to manage cluster)
- scheduler  (assigns containers to nodes)
- controller (bring up containers when they go down)

Worked node has:
-  kubelet (agent in each node in cluster that ensures containers running on nodes as expected)
-  runtime (software to run containers in the background i.e docker)

```
pods have a 1 to 1 relationship with containers
entrypoint in docker -> command in kubernetes
cmd in docker -> args in kubernetes
```

----

## Pod

----

``` console
kubectl get pods -o wide
```

``` console
kubectl get pods,svc
```

``` console
kubectl run pod <pod-name> --image <image-name> --dry-run=client -o yaml > test.yaml
```

``` console
kubectl get pod <pod-name> -o yaml > pod-definition.yaml
```

``` console
kubectl apply -f test.yaml
```

``` console
kubeclt edit pod <pod-name>
```

``` console
kubectl explain pods --recursive | less
```

``` console
kubectl explain pods --recursive | grep envFrom -A<number-of-lines>
```

----

## Replication Controller and Replicaset

----

```console
kubectl create -f definition.yml
```

```console
kubectl get replicationcontroller
```

```console

kubectl get replicaset
```

```console

kubectl delete replicaset <replicaset-name>
```

```console
kubectl edit replicaset <replicaset-name>
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

----

## Deployments

----

```console
kubectl create deployment nginx --image=nginx 
```

```console
kubectl scale deploy/webapp --replicas=3
```

```console
kubectl get deployment 
```

```console
kubectl delete deployment <deployment -name>
```

```console
kubectl create deploy redis-deploy --image=redis --replicas=2 -n dev-ns
```
----

## Services

----

```console
kubectl expose pod redis --port=6379 --name redis-service - create service
```

----

## Config Map

----

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

----

## Secrets

----

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

----

## Service Account

----

```console
kubectl create serviceaccount test-sa 
```

```console
kubectl get serviceaccount
```

```console
kubectl describe serviceaccount test-sa 
```

----
