# Kubernetes

A list of Kubernetes templates and commands i use

## Table of Contents
- [Notes](#notes)

## Notes
- etcd - key store for information about the cluster i.e nodes, pods, roles, secrets
- kube-api sever - management component in kubernetes. Only component to interact with the etcd data store
- kube-controller-manager - manages contollers in kubernetes and brings the system to the desired state
- kube-scheduler - decides which pod goes to which node
- kubelet - registers nodes,  creates pods on a nodes, monitors the pods and nodes
- kube-proxy - 

```
If we install the cluster using kubeadmin, we can view :
  - Exec into the etcd pod and run the `etcdctl` command
  - Exec into the kube-apiserver pod and access the `/etc/kubernetes/manifests/kube-apiserver.yaml` file
  - Exec into the kube-controller manager pod and access the `/etc/kubernetes/manifests/kube-controller-manager.yaml` file
  - Exec into the kube-scheduler pod and access the `/etc/kubernetes/manifests/kube-scheduler.yaml` file
  - Kubeadmin doesn't deploy the kubelet, we have to do it manually
```

```
If we install the clustrer without using kubeadmin, we can view:
  - explore the etcd service
  - the apiserver service located at `/etc/systemd/system/kube-apiserver.service` or `ps -aux | grep kube-apiserver` on the master node.
  - the kubecontroller manager service located at `/etc/systemd/system/kube-controller-manager.service` or `ps -aux | grep kube-controller-manager` on the master node.
  - explore the kube-scheduler service or `ps -aux | grep kube-scheduler`
  - explore the kubelet service or `ps -aux | grep kubelet`
```