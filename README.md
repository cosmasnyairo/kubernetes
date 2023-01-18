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
- [Observability](#observability)
- [Jobs and Cronjobs](#jobs-and-cronjobs)

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
kubectl get pods --no-headers | wc -l
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

- [ ] [Pod Design Definition file ](definition-files/labels-selectors-annotations.yaml)

- Pod labels - used to group objects i.e pods, services, replicasets

```console
kubectl get pods --selector label=value
```

```console
kubectl get pods --selector label=value,label2=value2
```

- Selectors match labels described i.e match labels on the pod or service to match labels of a pod

- Annotation records details for informatory purposes e.g  build information, tool used.

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
kubectl get deploy -o wide
```

```console
kubectl delete deployment <deployment -name>
```

```console
kubectl create deploy redis-deploy --image=redis --replicas=2 -n dev-ns
```

- Deployment strategies: 
  - Recreate - Remove all applications running on older verision and bring up applications running on newer verision
  - Rolling update (default strategy) - Remove a single application and bring up a new one one by one until the newer version is running on all applications
  - A new replica set is created under the hood when we do deployment upgrades
  - We use record flag to save commands used to create/update deployments
  - We use the to revision flag to rollback to a specific revision 

```console
kubectl set image deploy/deploymentname <container-name>=<image>
```

```console
kubectl set image deploy/deploymentname <container-name>=<image> --record
```

```console
kubectl rollout restart deploy/deploymentname
```

```console
kubectl rollout status deploy/deploymentname
```

```console
kubectl rollout history deploy/deploymentname
```

```console
kubectl rollout undo deploy/deploymentname
```

```console
kubectl rollout undo deploy/deploymentname --to-revision=1
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

---

- [ ] [Service Account Definition file ](definition-files/serviceaccount.yaml)


```console
kubectl create serviceaccount test-sa
```

```console
kubectl get serviceaccount
```

```console
kubectl describe serviceaccount test-sa
```

```console
kubectl create token SERVICEACCOUNTNAME
```

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

---

- [ ] [Node Affinity Definition file ](definition-files/nodeaffinity-pod.yaml)

Node affinity types:

- requiredDuringSchedulingIgnoredDuringExecution
- PreferredDuringSchedulingIgnoredDuringExecution
- requiredDuringSchedulingrequiredDuringExecution

|  | During Scheduling    | During Execution    |
| :---:   | :---: | :---: |
|  1 | Required   | Ignored   |
|  2 | Preferred   | Ignored   |
|  3 | Required   | Required   |

---

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

## Observability

---

Readiness Probe:
- Perform test to check if the container is up before marking the container as ready.
- For readiness, we can do http calls, tcp calls or run a command that when succesfull, we mark the container as ready

Liveness Probe:
- Periodically test if application within container is healthy.
- For liveness, we can do http calls, tcp calls or run a command that when they fail, we mark the container as unhealthy and it's restarted

- [ ] [Readiness & Liveness Probe Definition file ](definition-files/readiness-probe.yaml)

Logging:

Show logs 

```console
kubectl logs podname 
```

Show live logs 

```console
kubectl logs -f podname 
```

For multi container we specify container name 

```console
kubectl logs -f podname container-name
```


Metric Server: 
- We can have 1 metric server per cluster
- Receives metrics from nodes and pods and stores them in memory ( we can't see historical data with metric server)
- To install on cluster,we clone the metric server repo and run kubectl create -f repourl

```console
kubectl top node
```

```console
kubectl top pod
```

---

## Jobs and Cronjobs

Job - Tasks that can be run and exit after they've finalized
- [ ] [Job Definition file ](definition-files/job.yaml)

---

```console
kubectl get jobs
```

Cronjob - To run jobs periodically
- [ ] [Cronjob Definition file ](definition-files/cronjob.yaml)

```console
kubectl get cronjob
```

---