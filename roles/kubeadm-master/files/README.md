The `kubeadm` documentation suggests to run the following to install flannel:

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
```

The original `kube-flannel.yml` configuration makes flannel bind to the default network interface, which is `eth0` in our case. We added the parameter `-iface vpn0` to the `flanneld` command.
