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
- [Security Context](#security-context)
- [Service Account](#service-account)
- [Resource Limits](#resource-limits)
- [Taints and Tolerations](#taints-and-tolerations)
- [Node Selectors](#node-selectors)
- [Node Affinity](#node-affinity)
- [Multicontainer Pods](#multicontainer-pods)


## Notes

---


- [ ] [Definition file](definition-files/definition.yaml)
 
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

- [ ] [Pod Definition file](definition-files/deployment.yaml)

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
kubectl exec -it podname -- commandtorun
```

```console
kubectl replace --force -f app.yaml 
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
- [ ] [Replicaset Definition file ](definition-files/replicaset.yaml)
- [ ] [Replicationcontroller Definition file](definition-files/replicationcontroller.yaml)

```console
kubectl create -f definition.yaml
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
kubectl apply -f definition.yaml
```

```console
kubectl replace -f definition.yaml
```

```console
kubectl scale -replicas=10 -f definition.yaml
```

```console
kubectl scale --replicas=0 replicaset/<replicaset-name>
```

---

## Deployments

---

- [ ] [Deployment Definition file ](definition-files/deployment.yaml)

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

- [ ] [Namespace Definition file ](definition-files/namespace.yaml)
- [ ] [Resource Quota Definition file](definition-files/resourcequota.yaml)
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

- [ ] [ConfigMap Definition file ](definition-files/configmap.yaml)
- [ ] [Pod with configMap Definition file](definition-files/configmap-pod.yaml)

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
  kubectl create -f test-config-map.yaml
  ```

  ```console
  kubectl get configmaps
  kubectl get cm
  kubectl describe configmap
  ```

---

## Secrets

---

- [ ] [Secret Definition file ](definition-files/secret.yaml)
- [ ] [Pod with Secret Definition file](definition-files/secret-pod.yaml)

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
  kubectl create -f test-secret.yaml
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

## Security Context

---

- [ ] [Security Context Definition file ](definition-files/securitycontext.yaml)

We can add security context on the pod level or the container level. If both are specified, the container level takes precedence.

Cabapilites are supported only on the container level

---

## Service Account

## Taints and Tolerations

---

- [ ] [Taints and Tolerations Definition file ](definition-files/taint%26toleration-pod.yaml)


<!-- To add the taint -->
```console
kubectl taint nodes NODENAME app=red:taint-effect 
```

<!-- To remove the taint -->
```console
kubectl taint nodes NODENAME app=red:taint-effect-
```

taint-effects include: `NoSchedule|NoExecute|PreferNoSchedule`

---

## Node Selectors

---

- [ ] [Node Selectors Definition file ](definition-files/nodeselector-pod.yaml)

```console
kubectl label nodes NODENAME type=test
```

We cannot apply advanced filters e.g not , or

---

## Node Affinity

## Multicontainer Pods

---

- [ ] [Multicontainer Pods Definition file ](definition-files/multicontainer.yaml)

- Sidecar containers -> help the main container e.g to logging agent to send logs to log server
- Adapter containers -> process data for the main container e.g converts logs to readable format before sending to logging server
- Ambassador containers -> proxy requests from the main container e.g send requests to db on main container's behalf

- [ ] [Init Containers Definition file ](definition-files/initcontainer.yaml)

- Init containers -> Process inside init container must finish before other containers start. 
- If the init container fails, the pod is restarted until the init container succeeds

---
