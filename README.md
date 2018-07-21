Do-It-Yourself Kubernetes in the Hetzner Cloud
==============================================

Example configuration for my talk at the [Munich Kubernetes Meetup](https://www.meetup.com/de-DE/Munchen-Kubernetes-Meetup/events/252431664/).

**This repository is not maintained.** It contains the snapshot used for the meetup demo on 25 July 2018, but it will not be updated for future Kubernetes versions.

References
----------

* Generating an Ansible inventory file with Terraform: [https://rsmitty.github.io/Terraform-Ansible-Kubernetes/](https://rsmitty.github.io/Terraform-Ansible-Kubernetes/)
* Setting up tinc vpn with Ansible: [https://github.com/thisismitch/ansible-tinc/](https://github.com/thisismitch/ansible-tinc/)
* Installing `docker`, `kubelet`, `kubeadm`, `kubectl`: [https://kubernetes.io/docs/setup/independent/](https://kubernetes.io/docs/setup/independent/)
* Setting up Kubernetes with `kubeadm`: [https://www.youtube.com/watch?v=2Yyc2R8yDRo](https://www.youtube.com/watch?v=2Yyc2R8yDRo)
* Using a CIFS file share as persistent storage in Kubernetes: [https://labs.consol.de/kubernetes/2018/05/11/cifs-flexvolume-kubernetes.html](https://labs.consol.de/kubernetes/2018/05/11/cifs-flexvolume-kubernetes.html)
* Backup and restore of the Kubernetes master: [https://labs.consol.de/kubernetes/2018/05/25/kubeadm-backup.html](https://labs.consol.de/kubernetes/2018/05/25/kubeadm-backup.html)
* Prometheus monitoring with the Prometheus operator: [https://labs.consol.de/kubernetes/2018/06/08/prometheus-operator-kubeadm-ansible.html](https://labs.consol.de/kubernetes/2018/06/08/prometheus-operator-kubeadm-ansible.html)

What You Need
-------------

1. Hetzner API token from [Hetzner Cloud Console](https://console.hetzner.cloud/) -> Access -> Tokens.
2. SSH key uploaded to [Hetzner Cloud Console](https://console.hetzner.cloud/) -> Access -> SSH Keys.
3. SSH key available locally (run `ssh-add <key>`), so that you can log into Hetzner machines without password.
4. [Hetzner Storage Box](https://www.hetzner.com/storage-box) (CIFS hard disk share)

How to Run
----------

1. Install [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/).
2. Run `terraform init`. This should create a directory structure in `./.terraform/` and download the [provider.hcloud](https://github.com/terraform-providers/terraform-provider-hcloud) and the [provider.null](https://github.com/terraform-providers/terraform-provider-null).
3. Create a file `./terraform.tfvars` with your Hetzner API token and the name of the SSH key as follows:

```properties
hcloud_token="..."
ssh_key_name="..."
```

4. Run `terraform apply`, confirm with `yes`. This should start the servers, and generate an Ansible inventory config file `./inventory`.
5. Replace the `share`, `username`, and `password` in [roles/kubeadm-master/vars/main.yml](roles/kubeadm-master/vars/main.yml) with the credentials for your [Hetzner Storage Box](https://www.hetzner.com/storage-box) (CIFS share). The password is encrypted using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/playbooks_vault.html). To encrypt your own password, perform the following steps:
   1. Create a file `~/.vault_pass.txt` with your password (the password may be followed by a `\n`).
   2. `export ANSIBLE_VAULT_PASSWORD_FILE="~/.vault_pass.txt"`
   3. Run `ansible-vault encrypt_string <hetzner-cifs-password>` and replace the `password` configuration in `roles/kubeadm-master/vars/main.yml` with the output of that command.
6. `export ANSIBLE_HOST_KEY_CHECKING=False` to disable strict host key checking for Ansible (don't check `~/.ssh/known_hosts`).
7. Run `ansible-playbook -i ./inventory ./kubernetes.yml`.

After Successful Run
--------------------

Learn the load balancer's public IP address from the file `./inventory` and add an entry in your local `/etc/hosts` file as follows (replace `159.69.45.50` with the load balancer's IP address):

```
159.69.45.50    kuard.example.com grafana.example.com prometheus.example.com alertmanager.example.com www.example.com
```

Import the client certificate `./client-certificate/self-signed-client-certificate.pfx` into your Web browser.

View the following URLs:

* [https://grafana.example.com](https://grafana.example.com)
* [https://prometheus.example.com](https://prometheus.example.com)
* [https://alertmanager.example.com](https://alertmanager.example.com)
