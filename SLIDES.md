---
title: DIY Kubernetes
author: Fabian Stäber
...

# Talk Outline

* Terraform and Ansible
* Tinc VPN
* kubeadm
* Load balancing
* Monitoring
* Backup and restore

https://github.com/fstab/diy-kubernetes

<!--

List of URLs shown throughout the talk (open in advance):

* https://github.com/fstab/diy-kubernetes
* https://hetzner.cloud
* https://docs.hetzner.cloud/
* https://github.com/terraform-providers/
* https://kubernetes.io/docs/setup/independent/
* https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade-1-9/
* TGI Kubernetes 006
* https://github.com/kubernetes/ingress-nginx/blob/master/rootfs/etc/nginx/template/nginx.tmpl
* https://kuard.example.com
* https://prometheus.example.com
* https://grafana.example.com

-->

# Terraform

<!--
This setup does have the load balancer as a single point of failure,
but it is possible to set up two load balancers.
To save money, you can run the load balancers and kube nodes on the same
physical machine, so you end up with three machines needed.
-->

```
                                  ________
                                 |        |
                                 | kube   |
                                 | master |
                                 |________|
          __________              ________
         |          |            |        |
-------> | load     | ==========>| kube   |
eth0     | balancer | vpn0 ||    | node   |
         |__________|      ||    |________|
                           ||     ________
                           ||    |        |
                           ||    | kube   |
                             ===>| node   |
                                 |________|

eth0 -> vpn0 -> flannel.1 -> docker0
```

<!--

Hetzner
=======

* Show UI on https://hetzner.cloud
* Show doc on https://docs.hetzner.cloud/

-> Could automate with bash and curl, but Terraform is idempotent

Terraform
=========

* terraform init -> .terraform/plugins/
* https://github.com/terraform-providers/

Ansible
=======

-> Could automate with bash and curl, but Ansible is idempotent

* Show kubernetes.yml
* Show inventory
* Run cd roles && ansible-galaxy init <name>

Firewall
========

* "iptables -P INPUT DROP" is complex, because there are so many virtual network devices in the final setup where you need exceptions.

-> Better to use policy ACCEPT and explicitly drop on eth0.

Tinc VPN
========

* Show files in tinc-host-configs
* Show ifconfig
* Show ping test in ansible task

Docker
======

Straightforward, except you need to choose a supported version and configure the cgroup driver:
https://kubernetes.io/docs/tasks/tools/install-kubeadm/#installing-docker

It is virutally impossible to install Docker 17.03, on Ubuntu 18.04, but I never had problems with Docker 17.12.

Kubernetes
==========

What you need on the each node and the master:

* kubelet (systemd service)
* cni plugins (directory with executables used for setting up pod-to-pod networking)
* kubeadm (tool for configuring everything, not needed at runtime)

Heads up:

* Start kubelet with -node-ip <vpn ip> so that it's not on eth0
* Kubernetes docu has packages (https://kubernetes.io/docs/tasks/tools/install-kubeadm/#installing-docker),
  but quote from https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade-1-9/
  "Even though kubeadm ships in the Kubernetes repositories, it’s important to install kubeadm manually."

-> Now we have kubelet running on each node and the master, but it continuously fails in a back-off loop, because it cannot communicate with the master yet.

Configuring the master, Configuring the nodes
=============================================

* kubeadm init (does all the magic, generate certificates, token, etc.).
  -> Use -apiserver-advertise-address for vpn0
  -> Watch TGI Kubernetes 006: kubeadm (highly recommended).
* kubeadm join
  -> Show how the `kubeadm_join_command` goes from master to nodes

Load Balancer / Example Deployment
==================================

* apply example yaml with kubectl (kuard deployment)
* Run kubectl get nodes / pods / deployments ...
* Show load balancer nginx config sites-enabled/...
* Show /etc/hosts on macbook
* Show http://kuard.example.com

Kubernetes Native / Ingress
===========================

* Explain Custom Resource Definitions (CRDs)
* Explain how Kubernetes Native Applications use CRDs (examples: Nginx ingress, Prometheus Operator)
* Show https://github.com/kubernetes/ingress-nginx/blob/master/rootfs/etc/nginx/template/nginx.tmpl
  -> Nginx ingress good for http, but maybe not best for other protocols.

Prometheus
==========

* prometheus operator as example of kubernetes native application
* Explain `example.jsonnet`.
* show https://prometheus.example.com/targets
* show https://grafana.example.com

Backup/Restore
==============

* node: no problem
* master:
  -> Show CIFS plugin /usr/libexec/...
  -> Show backup-cron-job.yml

* Proof: run `terraform destroy -target hcloud_server.master`
* Show kuard deployment still available through node port
* Restore.

Summary
=======

* hosted Kubernetes
* diy Kubernetes
* kubespray, kops, ...

-->
